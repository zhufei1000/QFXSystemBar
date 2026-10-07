#!/usr/bin/env python3
"""Build the white MDT menu icon from its SVG (requires node + @resvg/resvg-js).

    python tools/gen_mdt_icon.py

Set RESVG_PATH to an existing @resvg/resvg-js installation when necessary.
The SVG and preview stay in tools; only the BLP is shipped in the addon.
"""
from pathlib import Path
import tempfile

from PIL import Image

from gen_micromenu_icons import alpha_bbox, dxt5, dxt5_decode_alpha, render_svgs, write_blp


def main():
    root = Path(__file__).resolve().parent.parent
    source = root / "tools/source_svg/MDT.white.svg"
    png = source.with_suffix(".png")
    output = root / "QFXSystemBar/Media/MicroMenu/MDT.blp"
    preview = source.with_name("MDT.white.preview.png")
    with tempfile.TemporaryDirectory(prefix="qfx_mdt_") as temp:
        preview_svg = Path(temp) / "preview.svg"
        svg = source.read_text(encoding="utf-8")
        preview_svg.write_text(svg.replace('fill="#fff">', 'fill="#fff"><rect width="128" height="128" fill="#172131"/>', 1), encoding="utf-8")
        render_svgs([
            {"svg": str(source), "out": str(png), "size": 128},
            {"svg": str(preview_svg), "out": str(preview), "size": 128},
        ])
    icon = Image.open(png).convert("RGBA")
    assert icon.size == (128, 128)
    pixels = icon.load()
    assert all(pixels[x, y][:3] == (255, 255, 255)
               for y in range(128) for x in range(128) if pixels[x, y][3])
    assert icon.getchannel("A").getextrema() == (0, 255)
    assert icon.getpixel((0, 0))[3] == 0
    size = write_blp(str(output), icon, (255, 255, 255))
    decoded = dxt5_decode_alpha(dxt5(icon, (255, 255, 255)), 128)
    assert alpha_bbox(decoded) == alpha_bbox(icon)
    output.with_suffix(".svg").write_bytes(source.read_bytes())
    print(f"MDT.blp: {size} bytes, 128x128, white RGB, transparent alpha, 8 mip levels")


if __name__ == "__main__":
    main()
