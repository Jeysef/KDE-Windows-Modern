#!/usr/bin/env python3
"""End-to-end tests of the taskbar (Icon Tasks) inside the running session.

Drives real input (uinput), finds the taskbar through AT-SPI, and reads what
a disposable test window received.

  focus  Issue #14: hovering a taskbar icon must not take keyboard focus
         from the window the user is typing in.
  shortcut  Win+1..9 activates the Nth taskbar entry (Plasma 6.8 moved these
         shortcuts into the task manager; the fork registers them itself).

Before each scenario the pointer wiggles in circles: hands off the mouse.
A scenario that fails is announced and retried once.

Nothing here changes system state: the only window opened is the test
window, and it is closed again.

Usage: tests/icontasks/e2e.py [--out DIR] [SCENARIO ...]  (default: all)
"""
import argparse
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from evdev import ecodes as e  # noqa: E402

from e2e import a11y  # noqa: E402
from e2e.session import Checks  # noqa: E402
from e2e.testwindow import TestWindow, place  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402

WIN_X, WIN_Y = 300, 200          # where the test window is put (frame top-left)


def task_button_centre():
    """A taskbar button: a named button in the panel row of Show desktop."""
    desktop = a11y.find("plasmashell", "Show desktop", visible=False)
    if not desktop:
        raise RuntimeError("Show desktop not found")
    row_y, panel_win = desktop.rect[1], desktop.window
    for node in a11y.nodes("plasmashell"):
        if (node.showing and node.role == "button" and node.window == panel_win
                and node.rect[1] == row_y and node.rect[2] > 0 and node.name
                and node.name not in ("Show desktop", "Start")):
            return node.centre
    raise RuntimeError("no taskbar button found")


def focus(vi, out, c):
    """#14: hovering a taskbar icon must leave typing in the focused window."""
    x, y = task_button_centre()
    win = TestWindow()
    try:
        c.check(win.wait(lambda s: s["active"], 6), "test window opens focused")
        place(win.proc.pid, WIN_X, WIN_Y, out)
        vi.move_to(WIN_X + 320, WIN_Y + 220)
        vi.click()
        time.sleep(0.4)
        vi.type_text("before")
        c.check(win.wait(lambda s: s.get("typed") == "before"),
                f"typing reaches the window (got {win.state.get('typed')!r})")

        vi.move_to(x, y)
        time.sleep(0.6)
        vi.move_to(x + 3, y + 2, steps=3)   # a real hover, not one motion event
        time.sleep(1.0)                     # long enough for the tooltip to open
        vi.type_text("after")
        c.check(win.wait(lambda s: s.get("typed") == "beforeafter"),
                f"after hovering a task, typing still reaches the window "
                f"(got {win.state.get('typed')!r}, active={win.state.get('active')})")
    finally:
        vi.move_to(WIN_X + 320, WIN_Y + 220)   # off the taskbar: close its tooltip
        win.close()


def task_buttons():
    """Taskbar buttons left to right (launchers and windows), as AT-SPI nodes."""
    desktop = a11y.find("plasmashell", "Show desktop", visible=False)
    if not desktop:
        raise RuntimeError("Show desktop not found")
    row_y, panel_win = desktop.rect[1], desktop.window
    nodes = [n for n in a11y.nodes("plasmashell")
             if n.showing and n.role == "button" and n.window == panel_win and n.rect[1] == row_y
             and n.rect[2] > 0 and n.name and n.name not in ("Show desktop", "Start")
             and n.rect[0] < desktop.rect[0] - 200]          # left of the tray area
    return sorted(nodes, key=lambda n: n.rect[0])


def shortcut(vi, out, c):
    """Win+N activates the Nth task: on the active window's own task it minimizes, again restores."""
    win = TestWindow()
    try:
        c.check(win.wait(lambda s: s["active"], 6), "test window opens focused")
        time.sleep(1.0)                                  # its task button appears
        buttons = task_buttons()
        names = [b.name for b in buttons]
        index = next((i for i, n in enumerate(names) if "WM-SHORTCUTS-E2E" in n or n.lower().startswith("qml")), None)
        c.check(index is not None and index < 9, f"test window has a taskbar button among the first 9 ({names})")
        if index is None or index >= 9:
            return
        key = getattr(e, f"KEY_{index + 1}")
        for expect_active, what in ((False, "minimizes"), (True, "restores")):
            vi.key(e.KEY_LEFTMETA, True)
            vi.tap(key, after=0.1)
            vi.key(e.KEY_LEFTMETA, False)
            c.check(win.wait(lambda s: s["active"] == expect_active, 3),
                    f"Win+{index + 1} {what} the test window (active={win.state.get('active')})")
    finally:
        win.close()


SCENARIOS = {"focus": focus, "shortcut": shortcut}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--out", type=pathlib.Path, default=pathlib.Path("icontasks-e2e"))
    parser.add_argument("scenarios", nargs="*", metavar="SCENARIO", help=" ".join(SCENARIOS))
    args = parser.parse_args()
    unknown = [s for s in args.scenarios if s not in SCENARIOS]
    if unknown:
        parser.error(f"unknown scenario(s): {', '.join(unknown)}")
    args.out = args.out.resolve()
    args.out.mkdir(parents=True, exist_ok=True)

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
                        SCENARIOS[name](vi, args.out, checks)
                    except Exception as ex:  # noqa: BLE001 — report, then retry
                        checks.check(False, f"{name} raised {ex!r}")
                    if not checks.failures:
                        break
                else:
                    failed.append(name)
        finally:
            vi.close()

    print(f"FAILED: {', '.join(failed)}" if failed else "ALL PASSED")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
