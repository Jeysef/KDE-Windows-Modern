#!/usr/bin/env python3
"""Screenshot a Plasma-style text field at rest, hovered and focused.

Uses the clipboard popup's search field (Win+V). The popup opens at the
pointer; on Wayland AT-SPI positions are relative to the popup, so the
popup is opened from a known point. Never types into the field (the
clipboard filter is left empty) and closes the popup with Esc.

Usage: tests/panel/field_states.py OUT_DIR   (writes field-{rest,hover,focus}.png)
"""
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from evdev import ecodes as e  # noqa: E402

from e2e import a11y  # noqa: E402
from e2e.session import screenshot  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402

ORIGIN = (300, 150)
AWAY = (1500, 900)


def main():
    out = pathlib.Path(sys.argv[1]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    with a11y.enabled():
        time.sleep(2)
        vi = VirtualInput()
        try:
            vi.announce()
            vi.move_to(*ORIGIN)
            time.sleep(0.3)
            vi.key(e.KEY_LEFTMETA, True)
            vi.tap(e.KEY_V, after=0.1)
            vi.key(e.KEY_LEFTMETA, False)
            time.sleep(1.0)
            field = next((n for n in a11y.nodes("plasmashell")
                          if n.showing and n.role in ("entry", "text") and n.rect[2] > 150), None)
            if field is None:
                print("search field not found")
                return 1
            fx, fy = ORIGIN[0] + field.centre[0], ORIGIN[1] + field.centre[1]
            print("field", field.rect, "screen centre", (fx, fy))
            vi.move_to(*AWAY)
            time.sleep(0.8)
            screenshot(out / "field-rest.png")
            vi.move_to(fx, fy)
            vi.move_to(fx + 3, fy + 1, steps=3)
            time.sleep(0.8)
            screenshot(out / "field-hover.png")
            vi.click()                         # focus the field
            time.sleep(0.3)
            vi.move_to(*AWAY)
            time.sleep(0.8)
            screenshot(out / "field-focus.png")
        finally:
            vi.tap(e.KEY_ESC, after=0.3)
            vi.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
