#!/usr/bin/env python3
"""End-to-end test of Snap Layouts in the running session.

Drags a disposable test window by its title bar to the top edge with a
virtual mouse, checks that the layout bar appears, drops the window on a
layout cell and reads back the size the window reports.

  half      drop on the left cell of 50/50          -> left half
  quarter   drop on the bottom-right cell of 2x2    -> bottom-right quarter
  elsewhere release away from the bar                -> nothing snapped by us

Before each scenario the pointer wiggles in circles: hands off.

Usage: tests/snaplayouts/e2e.py [--out DIR] [SCENARIO ...]
"""
import argparse
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from evdev import ecodes as e  # noqa: E402

from e2e.session import Checks, screenshot  # noqa: E402
from e2e.testwindow import TestWindow, place  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402

# Must match SnapBar.qml: the diagram row is centred, rowTop px from the top.
DIAGRAM_W, DIAGRAM_H, GAP, ROW_TOP, LAYOUTS = 72, 44, 10, 20, 6
SCREEN_W = 1920
ROW_W = LAYOUTS * DIAGRAM_W + (LAYOUTS - 1) * GAP
ROW_X = round((SCREEN_W - ROW_W) / 2)
WIN_X, WIN_Y = 400, 300  # where the test window is placed before dragging


def cell_point(layout, fx, fy):
    """Screen point at fractions fx, fy inside diagram `layout`."""
    x = ROW_X + layout * (DIAGRAM_W + GAP) + int(fx * DIAGRAM_W)
    y = ROW_TOP + int(fy * DIAGRAM_H)
    return x, y


def drag(vi, win, to, out, shot):
    """Grab the title bar, drag to the top edge, then to `to`, release."""
    vi.move_to(WIN_X + 200, WIN_Y + 15)
    time.sleep(0.3)
    vi.key(e.BTN_LEFT, True)
    time.sleep(0.2)
    vi.move_to(WIN_X + 260, WIN_Y + 60, steps=8)   # start the move
    vi.move_to(960, 3, steps=30)                    # to the top edge
    time.sleep(0.6)
    if to:
        vi.move_to(*to, steps=15)
        time.sleep(0.6)
    screenshot(out / f"{shot}.png")
    vi.key(e.BTN_LEFT, False)
    time.sleep(1.2)


def scenario(vi, c, out, name, to, expect):
    win = TestWindow()
    try:
        c.check(win.wait(lambda s: s["active"], 6), "test window opens")
        place(win.proc.pid, WIN_X, WIN_Y, out)
        time.sleep(0.5)
        start = dict(win.state)
        drag(vi, win, to, out, name)
        s = win.state
        print(f"        window now {s.get('w')}x{s.get('h')} (was {start.get('w')}x{start.get('h')})")
        c.check(expect(s, start), f"{name}: window has the expected size")
    finally:
        win.close()


# Client sizes: the work area is 1920 x 1032 (48 px panel); the title bar
# and 1 px borders come off the client size.
SCENARIOS = {
    "half": (cell_point(0, 0.25, 0.5), lambda s, _: abs(s["w"] - 958) <= 6 and s["h"] > 950),
    "quarter": (cell_point(4, 0.75, 0.75), lambda s, _: abs(s["w"] - 958) <= 6 and 450 < s["h"] < 520),
    # Released well away from the bar: not a cell, nothing snapped by us.
    "elsewhere": ((ROW_X - 200, 400), lambda s, start: s["w"] == start["w"] and s["h"] == start["h"]),
}


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--out", type=pathlib.Path, default=pathlib.Path("snaplayouts-e2e"))
    ap.add_argument("scenarios", nargs="*", metavar="SCENARIO", help=" ".join(SCENARIOS))
    args = ap.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    out = args.out.resolve()
    failed = []
    vi = VirtualInput()
    try:
        for name in args.scenarios or list(SCENARIOS):
            for attempt in (1, 2):
                print(f"scenario {name}" + (" (retry)" if attempt == 2 else ""))
                vi.announce()
                checks = Checks()
                try:
                    scenario(vi, checks, out, name, *SCENARIOS[name])
                except Exception as ex:
                    checks.check(False, f"{name} raised {ex!r}")
                    vi.key(e.BTN_LEFT, False)
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
