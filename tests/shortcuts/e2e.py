#!/usr/bin/env python3
"""End-to-end test of the Windows keyboard shortcuts in the running session.

Presses the real keys through a virtual keyboard (uinput) and reads what
happened from KWin, AT-SPI, the process list and a disposable test window
that reports its own size and focus.

  snap            Win+Up/Down on a test window: maximize, restore, left half,
                  top-left quarter, back, bottom-left quarter, minimize
  minimize-all    Win+M minimizes the test window, Win+M again restores it
  task-view       Win+Tab opens KWin's Overview
  run             Win+R opens KRunner
  quick-settings  Win+A opens and closes Quick Settings
  notifications   Win+N opens the notifications page
  screenshot      Win+PrtSc saves a screenshot without opening Spectacle
                  (the file is deleted afterwards)
  snip            Win+Shift+S opens Spectacle's region selection; Esc cancels
  task-manager    Ctrl+Shift+Esc opens Mission Center (closed afterwards)

Before each scenario the pointer wiggles in circles: hands off. A failing
scenario is retried once. Nothing is clicked.

Usage: tests/shortcuts/e2e.py [--out DIR] [SCENARIO ...]   (default: all)
"""
import argparse
import pathlib
import subprocess
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from evdev import ecodes as e  # noqa: E402

from e2e import a11y  # noqa: E402
from e2e.session import Checks, kwin_call, screenshot  # noqa: E402
from e2e.testwindow import TestWindow  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402

SCREENSHOTS = pathlib.Path.home() / "Pictures/Screenshots"

def press(vi, *codes):
    """A key combination: press in order, release in reverse."""
    for c in codes:
        vi.key(c, True)
        time.sleep(0.03)
    for c in reversed(codes):
        vi.key(c, False)
        time.sleep(0.03)
    time.sleep(0.6)


META = e.KEY_LEFTMETA


def wait_for(predicate, timeout=4.0, step=0.2):
    end = time.time() + timeout
    while time.time() < end:
        result = predicate()
        if result:
            return result
        time.sleep(step)
    return None


def active_effects():
    reply = kwin_call("/Effects", "org.freedesktop.DBus.Properties.Get",
                      "string:org.kde.kwin.Effects", "string:activeEffects")
    return reply


def showing(app, name):
    try:
        return next((n for n in a11y.nodes(app) if n.name == name and n.showing), None)
    except RuntimeError:  # the app is not running / not in the accessibility tree
        return None


def pids(name):
    out = subprocess.run(["pgrep", "-x", name], capture_output=True, text=True, check=False).stdout.split()
    return {int(p) for p in out}


# ── Scenarios ─────────────────────────────────────────────────────────
def snap(vi, c, out):
    win = TestWindow()
    try:
        c.check(win.wait(lambda s: s["active"], 6), "test window opens and has focus")
        start_w = win.state["w"]
        press(vi, META, e.KEY_UP)
        c.check(win.wait(lambda s: s["w"] > 1500), f"Win+Up maximizes (width {win.state.get('w')})")
        full_w, full_h = win.state["w"], win.state["h"]
        screenshot(out / "snap-maximized.png")
        press(vi, META, e.KEY_DOWN)
        c.check(win.wait(lambda s: abs(s["w"] - start_w) < 8), f"Win+Down restores ({win.state.get('w')} px wide)")
        press(vi, META, e.KEY_LEFT)
        half = lambda s: abs(s["w"] - full_w / 2) < 40  # noqa: E731
        c.check(win.wait(lambda s: half(s) and s["h"] > full_h * 0.85), "Win+Left snaps to the left half")
        press(vi, META, e.KEY_UP)
        c.check(win.wait(lambda s: half(s) and s["h"] < full_h * 0.6),
                f"Win+Up on the left half goes to the top-left quarter (h {win.state.get('h')})")
        screenshot(out / "snap-quarter.png")
        press(vi, META, e.KEY_DOWN)
        c.check(win.wait(lambda s: half(s) and s["h"] > full_h * 0.85), "Win+Down on the top quarter returns to the half")
        press(vi, META, e.KEY_DOWN)
        c.check(win.wait(lambda s: half(s) and s["h"] < full_h * 0.6), "Win+Down on the half goes to the bottom quarter")
        press(vi, META, e.KEY_DOWN)
        c.check(win.wait(lambda s: not s["active"]), "Win+Down on the bottom quarter minimizes")
    finally:
        win.close()


def minimize_all(vi, c, out):
    win = TestWindow()
    try:
        c.check(win.wait(lambda s: s["active"], 6), "test window opens and has focus")
        press(vi, META, e.KEY_M)
        c.check(win.wait(lambda s: not s["active"]), "Win+M minimizes it")
        screenshot(out / "minimize-all.png")
        press(vi, META, e.KEY_M)
        c.check(win.wait(lambda s: s["active"], 4), "Win+M again brings it back")
    finally:
        win.close()


def task_view(vi, c, out):
    press(vi, META, e.KEY_TAB)
    opened = wait_for(lambda: "overview" in active_effects())
    screenshot(out / "task-view.png")
    c.check(bool(opened), "Win+Tab opens Task View (KWin Overview)")
    vi.tap(e.KEY_ESC)
    c.check(bool(wait_for(lambda: "overview" not in active_effects())), "Esc closes it")


def run(vi, c, out):
    press(vi, META, e.KEY_R)
    box = wait_for(lambda: next((n for n in a11y.nodes("krunner") if n.showing and n.role in ("text", "entry")), None))
    screenshot(out / "run.png")
    c.check(box is not None, "Win+R opens KRunner with its search field")
    vi.tap(e.KEY_ESC)


def quick_settings(vi, c, out):
    press(vi, META, e.KEY_A)
    tile = wait_for(lambda: showing("plasmashell", "Wi-Fi"))
    screenshot(out / "quick-settings.png")
    c.check(tile is not None, "Win+A opens Quick Settings")
    press(vi, META, e.KEY_A)
    c.check(bool(wait_for(lambda: showing("plasmashell", "Wi-Fi") is None)), "Win+A again closes it")


def notifications(vi, c, out):
    press(vi, META, e.KEY_N)
    page = wait_for(lambda: next((n for n in a11y.nodes("plasmashell") if n.showing and n.role == "heading"
                                  and n.name == "Notifications"), None))
    screenshot(out / "notifications.png")
    c.check(page is not None, "Win+N opens the notifications page")
    vi.tap(e.KEY_ESC)


def screenshot_key(vi, c, out):
    before = set(SCREENSHOTS.glob("*")) if SCREENSHOTS.exists() else set()
    press(vi, META, e.KEY_SYSRQ)
    new = wait_for(lambda: set(SCREENSHOTS.glob("*")) - before if SCREENSHOTS.exists() else None, timeout=6)
    c.check(bool(new), f"Win+PrtSc saves a screenshot to {SCREENSHOTS}")
    time.sleep(1)
    c.check(not wait_for(lambda: showing("spectacle", "Spectacle"), timeout=1),
            "without opening Spectacle's window")
    for f in new or ():
        f.unlink()


def snip(vi, c, out):
    before = set(SCREENSHOTS.glob("*")) if SCREENSHOTS.exists() else set()
    old = pids("spectacle")
    press(vi, META, e.KEY_LEFTSHIFT, e.KEY_S)
    started = wait_for(lambda: pids("spectacle") - old)
    time.sleep(1)
    screenshot(out / "snip.png")
    c.check(bool(started), "Win+Shift+S starts Spectacle's region selection")
    vi.tap(e.KEY_ESC)
    c.check(bool(wait_for(lambda: not (pids("spectacle") - old))), "Esc cancels it")
    c.check(not (set(SCREENSHOTS.glob("*")) - before if SCREENSHOTS.exists() else set()),
            "a cancelled snip saves nothing")


def task_manager(vi, c, out):
    old = pids("missioncenter")
    press(vi, e.KEY_LEFTCTRL, e.KEY_LEFTSHIFT, e.KEY_ESC)
    started = wait_for(lambda: pids("missioncenter") - old, timeout=10)
    time.sleep(2)
    screenshot(out / "task-manager.png")
    c.check(bool(started), "Ctrl+Shift+Esc opens Mission Center")
    for pid in started or ():
        subprocess.run(["kill", str(pid)], check=False)


SCENARIOS = {"snap": snap, "minimize-all": minimize_all, "task-view": task_view, "run": run,
             "quick-settings": quick_settings, "notifications": notifications,
             "screenshot": screenshot_key, "snip": snip, "task-manager": task_manager}


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--out", type=pathlib.Path, default=pathlib.Path("shortcuts-e2e"))
    ap.add_argument("scenarios", nargs="*", metavar="SCENARIO", help=" ".join(SCENARIOS))
    args = ap.parse_args()
    unknown = [s for s in args.scenarios if s not in SCENARIOS]
    if unknown:
        ap.error(f"unknown scenario(s): {', '.join(unknown)}")
    args.out.mkdir(parents=True, exist_ok=True)
    out = args.out.resolve()
    failed = []
    with a11y.enabled():
        time.sleep(2)
        vi = VirtualInput()
        try:
            for name in args.scenarios or list(SCENARIOS):
                for attempt in (1, 2):
                    print(f"scenario {name}" + (" (retry)" if attempt == 2 else ""))
                    vi.announce()
                    checks = Checks()
                    try:
                        SCENARIOS[name](vi, checks, out)
                    except Exception as ex:
                        checks.check(False, f"{name} raised {ex!r}")
                        vi.tap(e.KEY_ESC)
                    if not checks.failures:
                        break
                else:
                    failed.append(name)
        finally:
            vi.close()
    print(f"screenshots in {out}")
    print("ALL PASSED" if not failed else f"FAILED: {', '.join(failed)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
