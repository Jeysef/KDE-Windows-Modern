#!/usr/bin/env python3
"""Render the real Plasma switch with each Windows Modern theme and check
that nothing but accent and background shows around the "on" pill.

Plasma draws the on-pill 1px right of the off-outline (SwitchIndicator.qml),
so a careless switch.svg lets the outline peek out as a white (dark theme)
or black (light theme) rim. Runs headless with an isolated theme copy, so
the live session is untouched.

Usage: tests/theme/check-switch.py [--out DIR]   (keeps the renders in DIR)
Exit 0 = clean, 1 = stray pixels, 77 = Plasma components unavailable.
"""
import argparse
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
THEMES = HERE.parents[1] / "plasma/desktoptheme"
QML = next((q for q in ("/usr/lib64/qt6/bin/qml", "/usr/lib/qt6/bin/qml", shutil.which("qml6") or "",
                        shutil.which("qml") or "") if q and os.access(q, os.X_OK)), None)
SWITCH_W, PITCH, X0 = 40, 52, 6   # Switches.qml layout


def render(theme, png, bg):
    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        shutil.copytree(THEMES / theme, tmp / "data/plasma/desktoptheme/WMTEST")
        (tmp / "config").mkdir()
        (tmp / "config/plasmarc").write_text("[Theme]\nname=WMTEST\n")
        env = dict(os.environ, XDG_DATA_HOME=str(tmp / "data"), XDG_CONFIG_HOME=str(tmp / "config"),
                   XDG_CACHE_HOME=str(tmp / "cache"), QT_QPA_PLATFORM="offscreen")
        subprocess.run([QML, str(HERE / "Switches.qml"), "--", str(png), bg], env=env,
                       capture_output=True, timeout=60, check=False)


def stray_pixels(png):
    from PIL import Image
    im = Image.open(png).convert("RGB")
    bg = im.getpixel((1, 1))
    bad = 0
    for i in (1, 3):                                    # the "on" switches
        left = X0 + i * PITCH
        accent = im.getpixel((left + 12, im.height // 2))
        knob = im.getpixel((left + 30, im.height // 2))
        for x in range(left - 2, left + SWITCH_W + 2):
            for y in range(im.height):
                p = im.getpixel((x, y))
                if min(_off_line(p, bg, accent), _off_line(p, accent, knob)) > 24:
                    bad += 1
    return bad


def _off_line(p, a, b):
    """How far p is from every blend of colours a and b (antialiasing)."""
    d = [j - i for i, j in zip(a, b)]
    v = [j - i for i, j in zip(a, p)]
    t = max(0.0, min(1.0, sum(i * j for i, j in zip(d, v)) / (sum(i * i for i in d) or 1)))
    return max(abs(p[k] - (a[k] + t * d[k])) for k in range(3))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out", type=pathlib.Path)
    args = ap.parse_args()
    if QML is None:
        print("qml (Qt 6) not found — skipped")
        return 77
    try:
        import PIL  # noqa: F401
    except ImportError:
        print("python3-pillow not installed — skipped")
        return 77
    out = args.out or pathlib.Path(tempfile.mkdtemp())
    out.mkdir(parents=True, exist_ok=True)
    failed = 0
    for theme, bg in (("Windows-modern-dark", "#2c2c2c"), ("Windows-modern-light", "#f3f3f3")):
        png = out / f"{theme}.png"
        render(theme, png, bg)
        if not png.exists():
            print(f"{theme}: render failed (Plasma components missing?) — skipped")
            return 77
        bad = stray_pixels(png)
        print(f"{'PASS' if bad == 0 else 'FAIL'}  {theme}: {bad} stray pixels around the on-pill")
        failed |= bad > 0
    if args.out is None:
        shutil.rmtree(out)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
