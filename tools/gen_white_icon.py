#!/usr/bin/env python3
"""Render white SVG icons to client-compatible 256px BLP2/DXT5 with vector mips.

Requires node + @resvg/resvg-js (RESVG_PATH can select its installation).
Each mip is rasterized from the SVG instead of chained bitmap downsampling.
Use the same DXT5 header as existing menu icons, with a new path to avoid cached
RAW3 metadata from 1.14.4. Only the BLP and editable SVG ship in the addon.
"""
from pathlib import Path
import struct
import tempfile

from PIL import Image
from gen_micromenu_icons import dxt5, render_svgs

MIP_SIZES = (256, 128, 64, 32, 16, 8, 4, 2, 1)


def write_dxt5_blp(path, levels):
    blobs = []
    for size, image in zip(MIP_SIZES, levels, strict=True):
        assert image.size == (size, size)
        blobs.append(dxt5(image, (255, 255, 255)))
    offsets, lengths, offset = [], [], 148 + 1024
    for blob in blobs:
        offsets.append(offset)
        lengths.append(len(blob))
        offset += len(blob)
    header = struct.pack("<4sIBBBBII", b"BLP2", 1, 2, 8, 7, 1, 256, 256)
    header += struct.pack("<16I", *(offsets + [0] * (16 - len(offsets))))
    header += struct.pack("<16I", *(lengths + [0] * (16 - len(lengths))))
    header += bytes(1024)
    path.write_bytes(header + b"".join(blobs))
    data = path.read_bytes()
    for offset, length, blob in zip(offsets, lengths, blobs, strict=True):
        assert data[offset:offset + length] == blob
    return len(data)


def build_white_icon(name):
    root = Path(__file__).resolve().parent.parent
    source = root / f"tools/source_svg/{name}.white.svg"
    png = source.with_suffix(".png")
    preview = source.with_name(f"{name}.white.preview.png")
    with tempfile.TemporaryDirectory(prefix="qfx_white_icon_") as temp:
        temp = Path(temp)
        preview_svg = temp / "preview.svg"
        svg = source.read_text(encoding="utf-8")
        preview_svg.write_text(svg.replace(">", '><rect width="100%" height="100%" fill="#172131"/>', 1), encoding="utf-8")
        paths = [temp / f"mip-{size}.png" for size in MIP_SIZES]
        jobs = [{"svg": str(source), "out": str(path), "size": size}
                for size, path in zip(MIP_SIZES, paths, strict=True)]
        jobs.append({"svg": str(preview_svg), "out": str(preview), "size": 256})
        render_svgs(jobs)
        levels = [Image.open(path).convert("RGBA") for path in paths]
        base = levels[0]
        assert base.getchannel("A").getextrema() == (0, 255)
        assert base.getpixel((0, 0))[3] == 0
        base.save(png)
        output = root / f"QFXSystemBar/Media/MicroMenu/{name}-256.blp"
        size = write_dxt5_blp(output, levels)
        (output.parent / f"{name}.svg").write_bytes(source.read_bytes())
    print(f"{output.name}: {size} bytes, 256x256, white DXT5, 9 vector mip levels")


if __name__ == "__main__":
    for name in ("MDT", "MRT", "GreatVault"):
        build_white_icon(name)
