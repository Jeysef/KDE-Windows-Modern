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
from e2e.taskbar import active_window, task_buttons  # noqa: E402
from e2e.testwindow import TestWindow, place  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402

WIN_X, WIN_Y = 300, 200          # where the test window is put (frame top-left)


def focus(vi, out, c):
    """#14: hovering a taskbar icon must leave typing in the focused window.

    Hovers an app's button long enough for its window preview to open: the
    preview is what took the keyboard (a Wayland toplevel without a tooltip
    role), not only QML focus.
    """
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

        owner = active_window()
        c.check(owner != "", f"KWin reports an active window ({owner!r})")
        others = [b for b in task_buttons() if "WM-SHORTCUTS-E2E" not in b.name] or task_buttons()
        c.check(bool(others), f"an app button to hover ({[b.name[:20] for b in others]})")
        if not others:
            return
        x, y = others[0].centre
        vi.move_to(x, y)
        time.sleep(0.6)
        vi.move_to(x + 3, y + 2, steps=3)   # a real hover, not one motion event
        time.sleep(1.2)                     # the window preview is open now
        during = active_window()
        c.check(during == owner, f"the preview does not become the active window "
                                 f"(active while hovering: {during!r}, before: {owner!r})")
        vi.type_text("after")
        c.check(win.wait(lambda s: s.get("typed") == "beforeafter"),
                f"after hovering a task, typing still reaches the window "
                f"(got {win.state.get('typed')!r}, active={win.state.get('active')})")
    finally:
        vi.move_to(WIN_X + 320, WIN_Y + 220)   # off the taskbar: close its tooltip
        win.close()


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
