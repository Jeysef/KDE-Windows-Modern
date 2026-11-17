#!/usr/bin/env python3
"""End-to-end tests of the taskbar (Icon Tasks) inside the running session.

Drives real input (uinput), finds the taskbar through AT-SPI, and reads what
a disposable test window received.

  focus  Issue #14: hovering a taskbar icon must not take keyboard focus
         from the window the user is typing in.
  shortcut  Win+1..9 activates the Nth taskbar entry (Plasma 6.8 moved these
         shortcuts into the task manager; the fork registers them itself).
  preview  Two grouped windows: clicking a window preview activates that
         window; the close button on a preview closes only its window.

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
from PIL import Image  # noqa: E402

from e2e import a11y  # noqa: E402
from e2e.session import Checks, screenshot  # noqa: E402
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


CARD_MARGIN = 8     # popup edge to card, card edge to its thumbnail/title (cardPadding)
CLOSE_SIZE = 22     # the close button (iconSizes.smallMedium)


def preview_popup(vi, button, out):
    """Hover a task button until its preview popup shows; return the popup's (left, top, right, bottom).

    The popup is found in a screenshot: its bottom margin, just above the
    panel, is one flat colour; walk along it to the sides and up its edge.
    """
    x, y = button.centre
    vi.move_to(x, y)
    vi.move_to(x + 2, y + 1, steps=3)
    time.sleep(1.6)
    shot = out / "preview.png"
    screenshot(shot)
    im = Image.open(shot).convert("RGB")
    shot.unlink()
    row = button.rect[1] - 10                  # inside the popup's bottom margin
    bg = im.getpixel((x, row))
    same = lambda p: all(abs(a - b) <= 3 for a, b in zip(p, bg))  # noqa: E731
    left, right = x, x
    while left > 0 and same(im.getpixel((left - 1, row))):
        left -= 1
    while right < im.width - 1 and same(im.getpixel((right + 1, row))):
        right += 1
    top = row
    while top > 0 and same(im.getpixel((left + 4, top - 1))):
        top -= 1
    bottom = row
    while same(im.getpixel((x, bottom + 1))):
        bottom += 1
    return left, top, right, bottom


def preview(vi, out, c):
    """Two test windows share one task button; click a preview, then close the other with its X."""
    first, second = TestWindow(), None
    try:
        c.check(first.wait(lambda s: s["active"], 6), "first test window opens focused")
        place(first.proc.pid, 120, 120, out, size=(1000, 600))
        second = TestWindow()
        c.check(second.wait(lambda s: s["active"], 6), "second test window opens focused")
        place(second.proc.pid, 700, 160, out, size=(500, 600))
        c.check(first.wait(lambda s: not s["active"], 3), "the first window is not active now")
        time.sleep(1.0)
        button = next((b for b in task_buttons()
                       if "WM-SHORTCUTS-E2E" in b.name or b.name.lower().startswith("qml")), None)
        c.check(button is not None, f"the test windows have a taskbar button ({[b.name[:20] for b in task_buttons()]})")
        if button is None:
            return
        left, top, right, bottom = preview_popup(vi, button, out)
        c.check(right - left > 300 and bottom - top > 120,
                f"the preview popup shows two cards ({left}, {top}, {right}, {bottom})")
        # Into the first card's thumbnail (the cards follow model order: first window first).
        vi.move_to(left + 3 * CARD_MARGIN, bottom - 6 * CARD_MARGIN, steps=8)
        time.sleep(0.5)
        vi.click()
        c.check(first.wait(lambda s: s["active"], 3),
                f"clicking the first preview activates its window (active={first.state.get('active')})")
        vi.move_to(960, 300, steps=8)
        time.sleep(0.8)

        left, top, right, bottom = preview_popup(vi, button, out)
        vi.move_to(right - 5 * CARD_MARGIN, bottom - 6 * CARD_MARGIN, steps=8)   # the second card
        time.sleep(0.6)
        vi.move_to(right - 2 * CARD_MARGIN - CLOSE_SIZE // 2, top + 2 * CARD_MARGIN + CLOSE_SIZE // 2, steps=6)
        time.sleep(0.5)
        vi.click()
        try:
            second.proc.wait(timeout=4)
            closed = True
        except Exception:  # noqa: BLE001 — still running
            closed = False
        c.check(closed, "the second preview's close button closes its window")
        c.check(first.proc.poll() is None, "the first window stays open")
    finally:
        vi.move_to(960, 300)
        for win in (first, second):
            if win and win.proc.poll() is None:
                win.close()


SCENARIOS = {"focus": focus, "shortcut": shortcut, "preview": preview}


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
