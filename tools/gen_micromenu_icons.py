#!/usr/bin/env python3
"""Rebuilds Media/MicroMenu/<set>/*.blp at 128x128 (DXT5 + baked mip chain).

    python tools/gen_micromenu_icons.py [--size 128] [--preview out.png] [--write]

Sources: 素材\\RoyMicroMenu\\Media\\WebIconSets\\<set>\\source_svg\\*.themed.svg
(SVG -> PNG needs node + @resvg/resvg-js).  Hearthstone / MeetingStone / Volume
have no SVG and are reconstructed from the shipped 32px raster instead.

With --write, both QFXSystemBar and the RoyMicroMenu factory BLP catalogue are
updated. Without --write only the QA report is printed (nothing is written).
"""

import json
import os
import shutil
import struct
import subprocess
import sys
import tempfile

from PIL import Image

ADDON = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDIA = os.path.join(ADDON, "QFXSystemBar", "Media", "MicroMenu")
ROOT = os.path.dirname(ADDON)                      # ...\微型菜单插件
WORKSPACE = os.path.dirname(ROOT)                  # ...\我发布的插件
SVGROOT = os.path.join(WORKSPACE, "微型菜单素材", "RoyMicroMenu", "Media", "WebIconSets")
TOOLS = os.path.dirname(os.path.abspath(__file__))

SETS = (("GameIcons", "GameIcons_CC_BY_3_0"), ("Lucide", "Lucide_ISC"), ("Tabler", "Tabler_MIT"))
NAMES = ("Achievement", "Bags", "Character", "Collections", "EJ", "Guild", "Hearthstone",
         "Housing", "LFD", "MainMenu", "MeetingStone", "PlayerSpells", "Profession",
         "QuestLog", "Social", "Store", "Volume")
NO_SVG = ("Hearthstone", "MeetingStone", "Volume")

# ---------------------------------------------------------------- image utils


def alpha_bbox(img, thr=8):
    a = img.getchannel("A") if "A" in img.getbands() else img
    px = a.load()
    w, h = a.size
    x0, y0, x1, y1 = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if px[x, y] > thr:
                x0 = min(x0, x)
                y0 = min(y0, y)
                x1 = max(x1, x)
                y1 = max(y1, y)
    return (x0, y0, x1 + 1, y1 + 1) if x1 >= 0 else None


def flat_colour(img):
    px = img.convert("RGBA").load()
    w, h = img.size
    acc, n = [0, 0, 0], 0
    for y in range(h):
        for x in range(w):
            p = px[x, y]
            if p[3] > 200:
                acc[0] += p[0]
                acc[1] += p[1]
                acc[2] += p[2]
                n += 1
    if n == 0:
        return (255, 255, 255)
    return tuple(int(round(c / n)) for c in acc)


def trace_upscale(mask, size, factor=12):
    """Rebuilds a crisp larger alpha from a small raster: upscale the coverage
    with a smooth filter, cut it at 50% coverage, then supersample down."""
    big = mask.resize((size * 4, size * 4), Image.LANCZOS)
    big = big.point(lambda v: 255 if v >= 128 else 0)
    big = big.resize((size * 4 * factor // 4, size * 4 * factor // 4), Image.LANCZOS)
    return big.resize((size, size), Image.BOX)


def mips(img):
    out = [img]
    cur = img
    while cur.size != (1, 1):
        w, h = cur.size
        cur = cur.resize((max(1, w // 2), max(1, h // 2)), Image.BOX)
        out.append(cur)
    return out


# ------------------------------------------------------------------- dxt5 blp


def _alpha_levels(a0, a1):
    if a0 == a1:
        return [a0, a0] + [a0] * 6
    return [a0, a1] + [int(round(((8 - i) * a0 + (i - 1) * a1) / 7.0)) for i in range(2, 8)]


def dxt5(img, colour):
    """BC3/DXT5 for a flat-colour icon: colour block is a constant, the alpha
    block uses one (a0, a1) pair per 4x4 block."""
    w, h = img.size
    px = img.load()
    r, g, b = colour
    c565 = ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
    out = bytearray()
    for by in range(0, h, 4):
        for bx in range(0, w, 4):
            # the last partial block of a mip level is padded by clamping
            block = [px[min(bx + x, w - 1), min(by + y, h - 1)][3]
                     for y in range(4) for x in range(4)]
            a0, a1 = max(block), min(block)
            levels = _alpha_levels(a0, a1)
            bits = 0
            for i, a in enumerate(block):
                best = min(range(8), key=lambda k: abs(levels[k] - a))
                bits |= (best & 7) << (3 * i)
            out += bytes((a0, a1)) + bits.to_bytes(6, "little")
            out += struct.pack("<HH", c565, c565) + bytes(4)
    return bytes(out)


def dxt5_decode_alpha(data, size):
    """Self-check: returns the alpha plane a decoder would produce."""
    img = Image.new("L", (size, size))
    px = img.load()
    pos = 0
    for by in range(0, size, 4):
        for bx in range(0, size, 4):
            a0, a1 = data[pos], data[pos + 1]
            levels = _alpha_levels(a0, a1)
            bits = int.from_bytes(data[pos + 2:pos + 8], "little")
            for i in range(16):
                x, y = min(bx + i % 4, size - 1), min(by + i // 4, size - 1)
                px[x, y] = levels[(bits >> (3 * i)) & 7]
            pos += 16
    return img


def write_blp(path, img, colour):
    blob_levels = [dxt5(lv, colour) for lv in mips(img)]
    header_size = 148 + 1024
    offsets, lengths, at = [], [], header_size
    for blob in blob_levels:
        offsets.append(at)
        lengths.append(len(blob))
        at += len(blob)
    w, h = img.size
    head = struct.pack("<4sIBBBBII", b"BLP2", 1, 2, 8, 7, 1, w, h)
    head += struct.pack("<16I", *(offsets + [0] * (16 - len(offsets))))
    head += struct.pack("<16I", *(lengths + [0] * (16 - len(lengths))))
    head += b"\0" * 1024
    with open(path, "wb") as fh:
        fh.write(head)
        for blob in blob_levels:
            fh.write(blob)
    return os.path.getsize(path)


# ---------------------------------------------------------------------- build


def render_svgs(jobs):
    if not jobs:
        return
    tmp = os.path.join(tempfile.gettempdir(), "qfx_icon_jobs.json")
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(jobs, fh)
    env = dict(os.environ)
    env.setdefault("RESVG_PATH", os.path.join(tempfile.gettempdir(), "opencode",
                                              "node_modules", "@resvg", "resvg-js"))
    subprocess.run(["node", os.path.join(TOOLS, "rasterize_svg.js"), tmp],
                   check=True, env=env, cwd=TOOLS)


def build(size, write):
    total_old = total_new = 0
    for media_set, svg_set in SETS:
        src_dir = os.path.join(SVGROOT, svg_set, "source_svg")
        out_dir = os.path.join(MEDIA, media_set)
        png_dir = os.path.join(tempfile.gettempdir(), "qfx_icons_%s" % media_set)
        os.makedirs(png_dir, exist_ok=True)
        jobs = []
        for name in NAMES:
            svg = os.path.join(src_dir, name + ".themed.svg")
            if name not in NO_SVG and os.path.exists(svg):
                jobs.append({"svg": svg, "out": os.path.join(png_dir, name + ".png"), "size": size})
        render_svgs(jobs)

        print("== %s" % media_set)
        for name in NAMES:
            tga_path = os.path.join(out_dir, name + ".tga")
            ref = Image.open(tga_path).convert("RGBA")
            old_size = os.path.getsize(tga_path)
            colour = flat_colour(ref)

            png = os.path.join(png_dir, name + ".png")
            match = None
            alpha = None
            origin = "trace"
            if os.path.exists(png):
                fresh = Image.open(png).convert("RGBA")
                if fresh.size != (size, size):
                    print("   !! %-12s rendered %s, expected %dx%d"
                          % (name, fresh.size, size, size))
                    continue
                # is the SVG actually the same artwork as the shipped raster?
                ref32 = ref.getchannel("A")
                new32 = fresh.getchannel("A").resize(ref.size, Image.BOX)
                pa, pb = ref32.load(), new32.load()
                match = sum(abs(pa[x, y] - pb[x, y])
                            for y in range(ref.size[1]) for x in range(ref.size[0])) \
                    / (ref.size[0] * ref.size[1])
                if match <= 20:
                    alpha = fresh.getchannel("A")
                    origin = "svg"
            if alpha is None:
                alpha = trace_upscale(ref.getchannel("A"), size)

            img = Image.new("RGBA", (size, size), colour + (0,))
            img.putalpha(alpha)
            enc = dxt5(img, colour)
            dec = dxt5_decode_alpha(enc, size)
            src_px, dec_px = alpha.load(), dec.load()
            err = [abs(src_px[x, y] - dec_px[x, y]) for y in range(size) for x in range(size)]
            mean_err = sum(err) / len(err)
            max_err = max(err)

            b_new = alpha_bbox(img)
            b_old = alpha_bbox(ref)
            # compare in units of the old raster so the numbers line up with the .tga
            k = ref.size[0] / float(size)
            d = [round((b_new[i] * k - b_old[i]), 1) for i in range(4)]

            blp_path = os.path.join(out_dir, name + ".blp")
            written = 0
            if write:
                written = write_blp(blp_path, img, colour)
                factory_dir = os.path.join(SVGROOT, svg_set, "blp")
                os.makedirs(factory_dir, exist_ok=True)
                shutil.copy2(blp_path, os.path.join(factory_dir, name + ".blp"))
                total_new += written
            total_old += old_size
            print("   %-12s %-5s colour %-16s vs-old %-18s bbox drift %-20s alpha err mean %.1f max %2d  %6d -> %6d B"
                  % (name, origin, "%d,%d,%d" % colour,
                     ("%.1f/255" % match) if match is not None else "-",
                     d, mean_err, max_err, old_size, written or 0))

    print("total old tga %d B, new blp %d B" % (total_old, total_new))


def _decode_blp_alpha(data, size, level=0):
    """Decodes alpha level `level` of a BLP written by write_blp."""
    offsets = struct.unpack_from("<16I", data, 20)
    img = Image.new("L", (size, size))
    px = img.load()
    pos = offsets[level]
    for by in range(0, size, 4):
        for bx in range(0, size, 4):
            a0, a1 = data[pos], data[pos + 1]
            levels = _alpha_levels(a0, a1)
            bits = int.from_bytes(data[pos + 2:pos + 8], "little")
            for i in range(16):
                px[bx + i % 4, by + i // 4] = levels[(bits >> (3 * i)) & 7]
            pos += 16
    return img


def _gpu_sample(img, disp):
    """Approximates what the client shows: pick the smallest mip that covers the
    display size (trilinear with a baked chain) and bilinear the remainder."""
    size = img.size[0]
    lv = 0
    while size >> lv > disp and size >> (lv + 1) >= 1:
        lv += 1
    s = max(1, size >> lv)
    small = img.resize((s, s), Image.BOX)
    if s == disp:
        return small
    return small.resize((disp, disp), Image.BILINEAR)


def preview(out_path, tint=(0, 159, 255)):
    bg = (6, 19, 33, 255)
    disps = (20, 30, 50)
    rows = [(s, n) for s in ("GameIcons", "Lucide", "Tabler")
            for n in ("Character", "Bags", "Volume", "Hearthstone", "MeetingStone")]
    left, cell_w, cell_h = 190, 150, 74
    sheet = Image.new("RGBA", (left + cell_w * len(disps), cell_h * len(rows) + 26), bg)

    def tinted(img):
        px = img.load()
        for y in range(img.size[1]):
            for x in range(img.size[0]):
                px[x, y] = (tint[0], tint[1], tint[2], px[x, y][3])
        return img

    for r, (media_set, name) in enumerate(rows):
        y = r * cell_h + 22
        for c, disp in enumerate(disps):
            x = left + c * cell_w
            tga = Image.open(os.path.join(MEDIA, media_set, name + ".tga")).convert("RGBA")
            blp = os.path.join(MEDIA, media_set, name + ".blp")
            if os.path.exists(blp):
                data = open(blp, "rb").read()
                width, height = struct.unpack_from("<II", data, 12)
                if width != height:
                    raise ValueError("preview only supports square BLP icons: %s" % blp)
                big = Image.new("RGBA", (width, height))
                big.putalpha(_decode_blp_alpha(data, width, 0))
                new = _gpu_sample(tinted(big), disp)
                sheet.paste(new, (x + 74, y + 6), new)
            old = tinted(tga).resize((disp, disp), Image.BILINEAR)
            sheet.paste(old, (x + 14, y + 6), old)
    sheet.convert("RGB").save(out_path)
    return out_path


def arg(flag, default, cast=str):
    return cast(sys.argv[sys.argv.index(flag) + 1]) if flag in sys.argv else default


def main():
    size = arg("--size", 128, int)
    if size < 4 or size > 4096 or size & (size - 1):
        raise SystemExit("--size must be a power of two between 4 and 4096")
    write = "--write" in sys.argv
    print("sources:", SVGROOT)
    print("target :", MEDIA, "%dx%d" % (size, size), "(writing)" if write else "(dry run)")
    build(size, write)
    pv = arg("--preview", None)
    if pv:
        print("preview:", preview(pv))


if __name__ == "__main__":
    main()
