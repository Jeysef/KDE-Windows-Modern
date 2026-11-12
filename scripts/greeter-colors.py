#!/usr/bin/env python3
"""Give the login screen's user the Windows Modern Dark colors.

Usage: greeter-colors.py <scheme.colors> <greeter kdeglobals>

The login screen runs as its own user ('plasmalogin') with Plasma's default
light colors, so the wallpaper showed its light picture while the desktop
is dark. The lock and login screens are always dark (PRODUCT.md), so this
copies the scheme's color groups ([Colors:*], [ColorEffects:*], [WM]) into
the greeter's kdeglobals, replacing any there, and names the scheme in
[General]. Other groups (icons, fonts) are kept. Run as the greeter user.
"""
import pathlib
import sys

IMPORT = ("[Colors:", "[ColorEffects:", "[WM]")


def sections(text):
    """[(header, lines)] in order; the header is '' for lines before any group."""
    out, header, lines = [], "", []
    for line in text.splitlines():
        if line.startswith("["):
            out.append((header, lines))
            header, lines = line.strip(), []
        else:
            lines.append(line)
    out.append((header, lines))
    return out


def main(scheme_path, kdeglobals_path):
    scheme = pathlib.Path(scheme_path)
    target = pathlib.Path(kdeglobals_path)
    imported = [(h, ls) for h, ls in sections(scheme.read_text()) if h.startswith(IMPORT)]
    kept = [(h, ls) for h, ls in sections(target.read_text() if target.exists() else "")
            if not h.startswith(IMPORT)]
    name = scheme.stem
    has_general = any(h == "[General]" for h, _ in kept)
    out = []
    for h, ls in kept:
        if h == "[General]":
            ls = [line for line in ls if not line.startswith(("ColorScheme=", "ColorSchemeHash="))]
            ls.insert(0, f"ColorScheme={name}")
        if h:
            out.append(h)
        out.extend(line for line in ls)
    if not has_general:
        out += ["[General]", f"ColorScheme={name}", ""]
    for h, ls in imported:
        out.append(h)
        out.extend(ls)
    target.write_text("\n".join(out).rstrip("\n") + "\n")
    print(f"{target}: {len(imported)} color groups from {scheme.name}")


if __name__ == "__main__":
    main(*sys.argv[1:3])
