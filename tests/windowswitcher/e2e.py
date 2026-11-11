#!/usr/bin/env python3
"""End-to-end test of the Alt+Tab switcher inside the running KWin.

KWin caches compiled QML for the whole session, keyed by file URL, so a
switcher that was already shown never picks up edits until you log out.
This tool sidesteps that: it installs the current repository version under
a one-off layout ID (new path, fresh compile), points KWin at it, presses
Alt+Tab through a virtual keyboard (uinput), takes a screenshot with
Spectacle while Alt is held, then checks KWin's log for QML errors. It
always restores your previous switcher setting and removes the copy.

Releasing Alt at the end switches to the selected window, exactly like a
real Alt+Tab.

Requirements: Plasma (Wayland or X11) session, python3-evdev, write access
to /dev/uinput (granted to the logged-in user on most distros; otherwise
run with pkexec), spectacle.

Usage: tests/windowswitcher/e2e.py [screenshot.png]
Exit status: 0 when the switcher opened without QML errors.
"""

import json
import pathlib
import shutil
import subprocess
import sys
import time

try:
    from evdev import UInput, ecodes as e
except ImportError:
    sys.exit("python3-evdev is required (Fedora: python3-evdev, Debian: python3-evdev)")

REPO = pathlib.Path(__file__).resolve().parents[2]
PACKAGE = REPO / "plasma/windowswitcher/org.kde.windowsmodern.alttab"
TABBOX_DIR = pathlib.Path.home() / ".local/share/kwin/tabbox"


def kwin_config(key, value=None):
    if value is None:
        return subprocess.run(["kreadconfig6", "--file", "kwinrc", "--group", "TabBox", "--key", key],
                              capture_output=True, text=True).stdout.strip()
    args = ["kwriteconfig6", "--file", "kwinrc", "--group", "TabBox", "--key", key]
    subprocess.run(args + (["--delete"] if value == "" else [value]), check=True)


def kwin_reconfigure():
    subprocess.run(["dbus-send", "--session", "--type=method_call", "--dest=org.kde.KWin",
                    "/KWin", "org.kde.KWin.reconfigure"], check=True)


def kwin_errors(since, layout_id):
    log = subprocess.run(["journalctl", "--user", "-b", "--since", since, "--no-pager", "-o", "cat"],
                         capture_output=True, text=True).stdout
    return [line for line in log.splitlines()
            if layout_id in line or "Could not load window switcher" in line]


def main():
    screenshot = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "alttab-e2e.png").resolve()
    layout_id = f"org.kde.windowsmodern.alttab.e2e{int(time.time())}"
    copy = TABBOX_DIR / layout_id
    previous = kwin_config("LayoutName")

    shutil.copytree(PACKAGE, copy)
    meta = json.loads((copy / "metadata.json").read_text())
    meta["KPlugin"]["Id"] = layout_id
    (copy / "metadata.json").write_text(json.dumps(meta, indent=4))

    since = time.strftime("%Y-%m-%d %H:%M:%S")
    try:
        kwin_config("LayoutName", layout_id)
        kwin_reconfigure()
        time.sleep(0.5)

        keyboard = UInput({e.EV_KEY: [e.KEY_LEFTALT, e.KEY_TAB]}, name="windows-modern-alttab-e2e")
        time.sleep(1.5)  # let the compositor pick up the new device
        try:
            keyboard.write(e.EV_KEY, e.KEY_LEFTALT, 1); keyboard.syn(); time.sleep(0.15)
            keyboard.write(e.EV_KEY, e.KEY_TAB, 1); keyboard.syn(); time.sleep(0.05)
            keyboard.write(e.EV_KEY, e.KEY_TAB, 0); keyboard.syn()
            time.sleep(1.2)  # switcher opens and previews render
            subprocess.run(["spectacle", "--background", "--nonotify", "--fullscreen",
                            "--output", str(screenshot)], timeout=30, check=True)
        finally:
            keyboard.write(e.EV_KEY, e.KEY_LEFTALT, 0); keyboard.syn()
            time.sleep(0.3)
            keyboard.close()
        time.sleep(0.5)
        errors = kwin_errors(since, layout_id)
    finally:
        kwin_config("LayoutName", previous)
        kwin_reconfigure()
        shutil.rmtree(copy, ignore_errors=True)

    print(f"screenshot: {screenshot}")
    if errors:
        print("KWin reported problems:")
        for line in errors:
            print("  " + line)
        return 1
    print("OK: switcher opened with no QML errors")
    return 0


if __name__ == "__main__":
    sys.exit(main())
