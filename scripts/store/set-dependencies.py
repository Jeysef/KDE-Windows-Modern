#!/usr/bin/env python3
"""Write the global themes' X-KPackage-Dependencies from products.json.

Installing a global theme from the KDE Store (Discover, Get New Global
Themes) then also installs these store items: its color scheme, Plasma
style, window decoration, icons, cursors, the Start menu, clock
and Show desktop widgets, and the Alt+Tab switcher. The C++ tray and
taskbar cannot ship through the store; ./install.sh adds them.

One failing dependency aborts the whole theme install, so every id must be
a published product whose zip installs cleanly (test with kpackagetool6 in
a throwaway HOME before releasing).
"""
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
STORE = "api.kde-look.org"
WIN10OS_CURSORS = 1383064  # yeyushengfan258's Win10OS-cursors (GPL-3.0)

products = json.loads((HERE / "products.json").read_text())


def dep(knsrc, name):
    pid = products[name]["id"]
    if not pid:
        raise SystemExit(f"{name} has no store id yet")
    return f"kns://{knsrc}/{STORE}/{pid}"


for variant in ("dark", "light"):
    deps = [dep("colorschemes.knsrc", "color-schemes"),
            dep("plasma-themes.knsrc", f"desktoptheme-{variant}"),
            dep("aurorae.knsrc", f"aurorae-{variant}"),
            dep("icons.knsrc", "icons"),
            f"kns://xcursor.knsrc/{STORE}/{WIN10OS_CURSORS}",
            dep("plasmoids.knsrc", "startmenu"),
            dep("plasmoids.knsrc", "digitalclock"),
            dep("plasmoids.knsrc", "showdesktop"),
            dep("kwinswitcher.knsrc", "windowswitcher")]
    path = ROOT / f"plasma/look-and-feel/org.kde.windowsmodern.{variant}/metadata.json"
    meta = json.loads(path.read_text())
    meta["X-KPackage-Dependencies"] = deps
    path.write_text(json.dumps(meta, indent=4, ensure_ascii=False) + "\n")
    print(f"{path.relative_to(ROOT)}: {len(deps)} dependencies")
