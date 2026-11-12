"""Render a preview grid of the icon pack for the store listing.

Usage: uvx --with cairosvg --with pillow python scripts/store/render_icons.py <out.png> <logo.png>
"""
import io
import subprocess
import pathlib
import sys

import cairosvg
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parents[2] / "icons" / "windows-modern"
NAMES = ["places/user-home", "places/user-desktop", "places/folder-documents", "places/folder-download",
         "places/folder-music", "places/folder-pictures", "places/folder-videos", "places/folder",
         "devices/computer", "devices/drive-harddisk", "places/network-workgroup", "places/user-trash-full",
         "apps/system-file-manager", "apps/utilities-terminal", "apps/preferences-system", "apps/firefox",
         "apps/accessories-calculator", "apps/accessories-text-editor", "categories/applications-graphics",
         "apps/multimedia-video-player", "mimetypes/application-pdf", "mimetypes/image-x-generic",
         "mimetypes/audio-x-generic", "mimetypes/package-x-generic"]
SIZE, CELL, COLS = 96, 150, 8


def icon(name, size):
    png = cairosvg.svg2png(url=str(ROOT / f"{name}.svg"), output_width=size, output_height=size)
    return Image.open(io.BytesIO(png)).convert("RGBA")


def main(out, logo):
    rows = (len(NAMES) + COLS - 1) // COLS
    W, H = COLS * CELL + 60, rows * CELL + 130
    img = Image.new("RGBA", (W, H), (243, 243, 243, 255))
    d = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype(subprocess.run(["fc-match", "-f", "%{file}", "Segoe UI:semibold"], capture_output=True, text=True).stdout, 34)
    except OSError:
        font = ImageFont.load_default()
    d.text((30, 30), "Windows Modern icons", fill=(28, 28, 28), font=font)
    for i, n in enumerate(NAMES):
        x = 30 + (i % COLS) * CELL + (CELL - SIZE) // 2
        y = 100 + (i // COLS) * CELL + (CELL - SIZE) // 2
        im = icon(n, SIZE)
        img.alpha_composite(im, (x, y))
    img.convert("RGB").save(out)
    icon("places/folder", 256).save(logo)
    print(out, img.size)


if __name__ == "__main__":
    main(*sys.argv[1:3])
