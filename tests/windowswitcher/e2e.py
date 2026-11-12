#!/usr/bin/env python3
"""End-to-end tests of the Alt+Tab switcher inside the running KWin.

KWin caches compiled QML for the whole session, keyed by file URL, so a
switcher that was already shown never picks up edits until you log out.
Each run therefore installs the switcher under a one-off layout ID (new
path, fresh compile), points KWin at it, drives real input through uinput
virtual devices, saves screenshots with Spectacle, and checks KWin's log.
It always restores your previous switcher setting and removes the copy.

The installed copy is instrumented: it logs card geometry and close-button
visibility changes to KWin's log, which is how the mouse is aimed and how
flicker is detected. The repository code itself is never modified.

Scenarios:
  open           Alt+Tab opens the switcher without QML errors.
  close-buttons  Opens three disposable windows, then with Alt held: clicks
                 the X on the selected window, moves onto the X of a
                 window that is not selected, and clicks it. Both windows
                 must close, and the second X must not flicker.

Releasing Alt at the end switches to the selected window, like a real
Alt+Tab.

Requirements: Plasma session, python3-evdev, write access to /dev/uinput
(granted to the logged-in user on most distros; otherwise use pkexec),
spectacle, and the Qt 6 `qml` tool for the disposable windows.

Usage: tests/windowswitcher/e2e.py [--scenario NAME] [--package DIR] [--out DIR]
Exit status: 0 when every check passed.
"""

import argparse
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

try:
    from evdev import ecodes as e
except ImportError:
    sys.exit("python3-evdev is required (Fedora/Debian: python3-evdev)")

from e2e.session import Checks, journal, kwin_reconfigure, screenshot  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402

REPO = pathlib.Path(__file__).resolve().parents[2]
DEFAULT_PACKAGE = REPO / "plasma/windowswitcher/org.kde.windowsmodern.alttab"
TABBOX_DIR = pathlib.Path.home() / ".local/share/kwin/tabbox"

# ── Instrumentation injected into the installed copy only ──────────────
GEOMETRY_LOGGER = """
    // e2e instrumentation (tests/windowswitcher/e2e.py)
    Timer {
        interval: 100; repeat: true; running: true
        onTriggered: {
            const out = { current: root.currentIndex, cards: [] };
            for (let i = 0; i < cards.count; ++i) {
                const c = cards.itemAt(i);
                if (!c) continue;
                const closeW = Math.round(26 * root.unit);
                const close = c.mapToGlobal(root.cardPadding + c.previewWidth - closeW / 2,
                                            root.cardPadding + root.headerHeight / 2);
                const centre = c.mapToGlobal(c.width / 2, c.height / 2);
                out.cards.push({ caption: c.model.caption, showClose: c.showClose,
                                 close: [Math.round(close.x), Math.round(close.y)],
                                 centre: [Math.round(centre.x), Math.round(centre.y)] });
            }
            console.warn("WM-E2E-GEOM " + JSON.stringify(out));
        }
    }
"""
SHOWCLOSE_LOGGER = (
    '                onShowCloseChanged: console.warn("WM-E2E-SHOWCLOSE " + '
    'JSON.stringify({ caption: model.caption, visible: showClose }))\n'
)

TEST_WINDOW_QML = """
import QtQuick
import QtQuick.Window
Window {
    title: Qt.application.arguments[Qt.application.arguments.length - 1]
    width: 640; height: 400; visible: true
    color: "#2d5f8a"
    Text { anchors.centerIn: parent; text: parent.title; color: "white"; font.pixelSize: 32 }
}
"""


# ── Helpers ────────────────────────────────────────────────────────────
def kwin_config(key, value=None):
    if value is None:
        return subprocess.run(["kreadconfig6", "--file", "kwinrc", "--group", "TabBox", "--key", key],
                              capture_output=True, text=True).stdout.strip()
    args = ["kwriteconfig6", "--file", "kwinrc", "--group", "TabBox", "--key", key]
    subprocess.run(args + (["--delete"] if value == "" else [value]), check=True)



def latest_geometry(since):
    for line in reversed(journal(since)):
        if "WM-E2E-GEOM " in line:
            return json.loads(line.split("WM-E2E-GEOM ", 1)[1])
    return None


def showclose_events(since):
    events = []
    for line in journal(since):
        if "WM-E2E-SHOWCLOSE " in line:
            events.append(json.loads(line.split("WM-E2E-SHOWCLOSE ", 1)[1]))
    return events


def qml_errors(since, layout_id):
    return [line for line in journal(since)
            if (layout_id in line and "WM-E2E-" not in line) or "Could not load window switcher" in line]



# ── Install an instrumented one-off copy ────────────────────────────────
def install_copy(package, layout_id):
    copy = TABBOX_DIR / layout_id
    shutil.copytree(package, copy)
    meta = json.loads((copy / "metadata.json").read_text())
    meta["KPlugin"]["Id"] = layout_id
    (copy / "metadata.json").write_text(json.dumps(meta, indent=4))

    view = copy / "contents/ui/SwitcherView.qml"
    qml = view.read_text()
    # Root-level geometry logger, before the root object's closing brace.
    qml = qml[:qml.rstrip().rfind("}")] + GEOMETRY_LOGGER + "}\n"
    # Close-button visibility logger inside the card delegate.
    anchor = "                // Preview width follows the window's aspect ratio"
    if anchor in qml:
        qml = qml.replace(anchor, SHOWCLOSE_LOGGER + anchor, 1)
    view.write_text(qml)
    return copy


# ── Scenarios ──────────────────────────────────────────────────────────
def scenario_open(vi, out, checks, since):
    vi.key(e.KEY_LEFTALT, True); time.sleep(0.15)
    vi.tap(e.KEY_TAB); time.sleep(1.0)
    try:
        geometry = latest_geometry(since)
        screenshot(out / "open.png")
    finally:
        vi.key(e.KEY_LEFTALT, False); time.sleep(0.3)
    checks.check(geometry is not None and len(geometry["cards"]) > 0,
                 f"switcher shows windows ({len(geometry['cards']) if geometry else 0} cards)")


def find_card(geometry, caption):
    return next((c for c in geometry["cards"] if c["caption"] == caption), None)


def scenario_close_buttons(vi, out, checks, since):
    qml_tool = next((t for t in ["qml6", "/usr/lib64/qt6/bin/qml", "/usr/lib/qt6/bin/qml", "qml"]
                     if shutil.which(t) or pathlib.Path(t).exists()), None)
    if not qml_tool:
        checks.check(False, "Qt 6 qml tool available for the disposable windows")
        return
    window_qml = pathlib.Path(tempfile.mkdtemp()) / "TestWindow.qml"
    window_qml.write_text(TEST_WINDOW_QML)
    names = ["WM-E2E-1", "WM-E2E-2", "WM-E2E-3"]
    procs = {}
    try:
        for name in names:
            procs[name] = subprocess.Popen([qml_tool, str(window_qml), "--", name],
                                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(0.8)
        time.sleep(1.0)

        vi.key(e.KEY_LEFTALT, True); time.sleep(0.15)
        try:
            vi.tap(e.KEY_TAB); time.sleep(1.0)
            geometry = latest_geometry(since)
            checks.check(geometry is not None, "switcher opened and reported its layout")
            if geometry is None:
                return
            current = geometry["cards"][geometry["current"]]["caption"]
            print(f"        selected window: {current}")

            # 1. Click the X on the selected window (it is visible without hover).
            first = find_card(geometry, current)
            checks.check(current in procs, f"selected window is a disposable test window ({current})")
            if current not in procs:
                return
            vi.move_to(*first["centre"])
            vi.move_to(*first["close"])
            screenshot(out / "1-hover-x-on-selected.png")
            vi.click()
            time.sleep(1.0)
            checks.check(procs[current].poll() is not None, f"clicking the X on {current} closed it")

            # 2. Move onto the X of a window that is NOT selected and click it.
            geometry = latest_geometry(since)
            selected = geometry["cards"][geometry["current"]]["caption"]
            target_name = next(n for n in names if n != current and n != selected and procs[n].poll() is None)
            target = find_card(geometry, target_name)
            checks.check(target is not None, f"{target_name} is still listed after the first close")
            if target is None:
                return
            vi.move_to(*target["centre"])
            time.sleep(0.3)
            arrived = time.strftime("%Y-%m-%d %H:%M:%S")
            vi.move_to(*target["close"])
            time.sleep(0.8)
            screenshot(out / "2-hover-x-on-unselected.png")
            flips = [ev for ev in showclose_events(arrived) if ev["caption"] == target_name]
            geometry = latest_geometry(since)
            shown = find_card(geometry, target_name)["showClose"]
            checks.check(shown, f"X on unselected {target_name} is visible while hovered")
            checks.check(len(flips) <= 1, f"X on {target_name} does not flicker ({len(flips)} visibility changes)")
            vi.click()
            time.sleep(1.0)
            checks.check(procs[target_name].poll() is not None, f"clicking the X on {target_name} closed it")
            screenshot(out / "3-after-second-close.png")
        finally:
            vi.key(e.KEY_LEFTALT, False); time.sleep(0.4)
    finally:
        for p in procs.values():
            if p.poll() is None:
                p.terminate()
        for p in procs.values():
            try:
                p.wait(timeout=5)
            except subprocess.TimeoutExpired:
                p.kill()
        shutil.rmtree(window_qml.parent, ignore_errors=True)


SCENARIOS = {"open": scenario_open, "close-buttons": scenario_close_buttons}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--scenario", choices=SCENARIOS, default="open")
    parser.add_argument("--package", type=pathlib.Path, default=DEFAULT_PACKAGE,
                        help="switcher package to test (default: the repository's)")
    parser.add_argument("--out", type=pathlib.Path, default=pathlib.Path("."),
                        help="directory for screenshots")
    args = parser.parse_args()
    args.out = args.out.resolve()
    args.out.mkdir(parents=True, exist_ok=True)

    layout_id = f"org.kde.windowsmodern.alttab.e2e{int(time.time())}"
    previous = kwin_config("LayoutName")
    if previous.startswith("org.kde.windowsmodern.alttab.e2e"):
        # Left selected by an interrupted run (its cleanup never ran): put the
        # real switcher back at the end, not a test copy that is about to go.
        previous = "org.kde.windowsmodern.alttab"
    copy = install_copy(args.package.resolve(), layout_id)
    since = time.strftime("%Y-%m-%d %H:%M:%S")
    checks = Checks()
    print(f"scenario {args.scenario} (layout {layout_id})")
    try:
        kwin_config("LayoutName", layout_id)
        kwin_reconfigure()
        time.sleep(0.5)
        vi = VirtualInput()
        try:
            vi.announce()
            SCENARIOS[args.scenario](vi, args.out, checks, since)
        finally:
            vi.close()
        time.sleep(0.5)
        errors = qml_errors(since, layout_id)
        checks.check(not errors, "no QML errors in KWin's log")
        for line in errors:
            print("        " + line)
    finally:
        kwin_config("LayoutName", previous)
        kwin_reconfigure()
        shutil.rmtree(copy, ignore_errors=True)

    print(f"screenshots in {args.out}")
    return 1 if checks.failures else 0


if __name__ == "__main__":
    sys.exit(main())
