#!/usr/bin/env python3
"""Screenshot the clipboard popup (Win+V) with the pointer over its first entry.

Shows how the Plasma style draws list-item hover and the search field
(issue #24). Usage: tests/panel/clipboard_hover.py OUT.png
"""
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from evdev import ecodes as e  # noqa: E402

from e2e import a11y  # noqa: E402
from e2e.session import screenshot  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402


def main():
    out = pathlib.Path(sys.argv[1]).resolve()
    with a11y.enabled():
        time.sleep(2)
        vi = VirtualInput()
        try:
            vi.announce()
            # The popup opens at the pointer; on Wayland AT-SPI gives
            # positions inside the popup, so start from a known corner.
            origin = (300, 150)
            vi.move_to(*origin)
            time.sleep(0.3)
            vi.key(e.KEY_LEFTMETA, True)
            vi.tap(e.KEY_V, after=0.1)
            vi.key(e.KEY_LEFTMETA, False)
            time.sleep(1.2)
            items = [n for n in a11y.nodes("plasmashell")
                     if n.showing and n.role in ("list item", "menu item") and n.rect[2] > 100]
            if not items:
                print("no clipboard entries visible")
                return 1
            first = min(items, key=lambda n: n.rect[1])
            x, y = origin[0] + first.centre[0], origin[1] + first.centre[1]
            vi.move_to(x, y)
            vi.move_to(x + 3, y + 1, steps=3)
            time.sleep(0.8)
            screenshot(out)
            print("popup item", first.name[:40], first.rect)
        finally:
            vi.tap(e.KEY_ESC, after=0.3)
            vi.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
