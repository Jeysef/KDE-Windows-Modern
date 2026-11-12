#!/usr/bin/env python3
"""Clean screenshots for the store listings, in dark and light.

Everything happens on a new, temporary virtual desktop with neutral windows
(KWrite with a sample note, Calculator, System Settings on its Colors page),
so nothing personal ends up in a public picture. For the light shots the
color scheme, Plasma style, window decoration and widget style switch to
the light variants; the previous values are restored at the end, as is the
virtual desktop.

Usage: scripts/store/capture.py <out-dir>
Writes desktop-<v>.png, quicksettings-<v>.png, clock-<v>.png,
titlebar-<v>.png for v in dark, light. Hands off the mouse while it runs.
"""
import pathlib
import re
import subprocess
import sys
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tests"))

from evdev import ecodes as e  # noqa: E402

from e2e import a11y  # noqa: E402
from e2e.session import kwin_call, kwin_reconfigure, screenshot  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402

VDM = ("org.kde.KWin", "/VirtualDesktopManager", "org.kde.KWin.VirtualDesktopManager")
VARIANTS = {
    "dark": {"scheme": "WindowsModernDark", "style": "kvantum-dark", "plasma": "Windows-modern-dark",
             "deco": "__aurorae__svg__windows-modern-dark-aurorae"},
    "light": {"scheme": "WindowsModernLight", "style": "kvantum", "plasma": "Windows-modern-light",
              "deco": "__aurorae__svg__windows-modern-light-aurorae"},
}
# Window class -> geometry (x, y, w, h) on the 1920x1032 work area.
LAYOUT = {"systemsettings": (110, 80, 1080, 720), "kwrite": (820, 300, 820, 560), "kcalc": (1530, 120, 300, 440)}
NOTE = """Windows Modern

A Windows 11 look and feel for KDE Plasma 6:
Start menu, taskbar, system tray with Quick Settings,
Snap Layouts, Windows shortcuts and Alt+Tab,
window decorations, icons and cursors.

Dark and light.
"""


def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout.strip()


def read(file, group, key):
    return run("kreadconfig6", "--file", file, "--group", group, "--key", key)


def write(file, group, key, value):
    run("kwriteconfig6", "--notify", "--file", file, "--group", group, "--key", key, value)


def current_settings():
    return {"scheme": read("kdeglobals", "General", "ColorScheme"),
            "style": read("kdeglobals", "KDE", "widgetStyle"),
            "plasma": read("plasmarc", "Theme", "name"),
            "deco": read("kwinrc", "org.kde.kdecoration2", "theme"),
            "library": read("kwinrc", "org.kde.kdecoration2", "library")}


def apply(s):
    run("plasma-apply-colorscheme", s["scheme"])
    run("plasma-apply-desktoptheme", s["plasma"])
    write("kdeglobals", "KDE", "widgetStyle", s["style"])
    if s.get("library"):
        write("kwinrc", "org.kde.kdecoration2", "library", s["library"])
    write("kwinrc", "org.kde.kdecoration2", "theme", s["deco"])
    kwin_reconfigure()
    time.sleep(3)


def desktops():
    out = run("busctl", "--user", "get-property", *VDM, "desktops")
    return re.findall(r'"([0-9a-f-]{36})" "([^"]*)"', out)


def kwin_script(source, name):
    js = pathlib.Path(tempfile.mkdtemp()) / f"{name}.js"
    js.write_text(source)
    sid = kwin_call("/Scripting", "org.kde.kwin.Scripting.loadScript", f"string:{js}", f"string:{name}").split()[-1]
    kwin_call(f"/Scripting/Script{sid}", "org.kde.kwin.Script.run")
    time.sleep(0.8)
    kwin_call("/Scripting", "org.kde.kwin.Scripting.unloadScript", f"string:{name}")


def place_windows():
    rules = ", ".join(f'"{c}": [{x}, {y}, {w}, {h}]' for c, (x, y, w, h) in LAYOUT.items())
    kwin_script(f"""const L = {{{rules}}};
for (const w of workspace.windowList()) {{
  const key = Object.keys(L).find(k => w.resourceClass === k || w.resourceClass.endsWith("." + k));
  const g = key && L[key];
  if (g && w.normalWindow) {{ w.setMaximize(false, false);
    w.frameGeometry = {{x: g[0], y: g[1], width: g[2], height: g[3]}}; workspace.activeWindow = w; }}
}}""", "wm-store-place")


def open_windows(tmp):
    note = tmp / "Windows Modern.txt"
    note.write_text(NOTE)
    procs = [subprocess.Popen(["systemsettings", "kcm_colors"]),
             subprocess.Popen(["kcalc"]),
             subprocess.Popen(["kwrite", str(note)])]
    time.sleep(6)
    place_windows()
    time.sleep(1)
    return procs


def filter_colors(vi):
    """Show only the Windows Modern schemes in System Settings' Colors page."""
    x, y, _, _ = LAYOUT["systemsettings"]
    vi.move_to(x + 600, y + 127)        # the page's search field
    time.sleep(0.3)
    vi.click()
    time.sleep(0.3)
    vi.type_text("windows modern")
    vi.move_to(960, 1000)
    time.sleep(1.5)
    place_windows()                     # bring KWrite and Calculator back on top


def flyout(vi, name, out):
    node = a11y.find("plasmashell", name, visible=False)
    vi.move_to(*node.centre)
    time.sleep(0.4)
    vi.click()
    time.sleep(1.5)
    vi.move_to(960, 300)   # no tooltip in the picture
    time.sleep(0.8)
    screenshot(out)
    vi.tap(e.KEY_ESC)
    time.sleep(0.8)


def main(out):
    out = pathlib.Path(out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    tmp = pathlib.Path(tempfile.mkdtemp())
    before = current_settings()
    start_desktop = run("busctl", "--user", "get-property", *VDM, "current").split('"')[1]
    known = {d for d, _ in desktops()}
    run("busctl", "--user", "call", *VDM, "createDesktop", "us", str(len(known)), "Store screenshots")
    new = next(d for d, _ in desktops() if d not in known)
    procs = []
    try:
        run("busctl", "--user", "set-property", *VDM, "current", "s", new)
        time.sleep(1.5)
        with a11y.enabled():
            vi = VirtualInput()
            try:
                vi.announce()
                for variant in ("dark", "light"):
                    for p in procs:
                        p.terminate()
                    apply(VARIANTS[variant])
                    procs = open_windows(tmp)
                    filter_colors(vi)
                    vi.move_to(960, 1000)
                    time.sleep(0.5)
                    screenshot(out / f"desktop-{variant}.png")
                    flyout(vi, "Show hidden icons", out / f"quicksettings-{variant}.png")
                    flyout(vi, "Clock", out / f"clock-{variant}.png")
            finally:
                vi.close()
    finally:
        for p in procs:
            p.terminate()
        apply(before)
        run("busctl", "--user", "set-property", *VDM, "current", "s", start_desktop)
        time.sleep(1)
        run("busctl", "--user", "call", *VDM, "removeDesktop", "s", new)
    print(f"screenshots in {out}")


if __name__ == "__main__":
    main(sys.argv[1])
