#!/usr/bin/env python3
"""Screenshot each taskbar button while hovered, plus the taskbar at rest.

Shows which frame the theme draws for a hovered task (tasks.svg's
<state>-hover pieces). Saves OUT_DIR/rest.png and hover-N.png, cropped to
the task buttons (between Start and the tray). No clicks.

Usage: tests/panel/task_hover.py OUT_DIR
"""
import pathlib
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from PIL import Image  # noqa: E402

from e2e import a11y  # noqa: E402
from e2e.session import screenshot  # noqa: E402
from e2e.taskbar import task_buttons  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402


def main():
    out = pathlib.Path(sys.argv[1]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    with a11y.enabled():
        time.sleep(2)
        buttons = task_buttons(include_buttons=True)
        vi = VirtualInput()
        try:
            vi.announce()
            left = buttons[0].rect[0] - 52
            right = buttons[-1].rect[0] + buttons[-1].rect[2] + 4
            top, height = buttons[0].rect[1], buttons[0].rect[3]

            def capture(name):
                full = out / f"full-{name}.png"
                screenshot(full)
                Image.open(full).crop((left, top, right, top + height)).save(out / f"{name}.png")
                full.unlink()

            vi.move_to(960, 500)
            time.sleep(0.6)
            capture("rest")
            for i, b in enumerate(buttons):
                vi.move_to(*b.centre)
                vi.move_to(b.centre[0] + 2, b.centre[1] + 1, steps=3)
                time.sleep(0.7)
                capture(f"hover-{i}")
                print(f"hover-{i}: {b.name[:40]!r}")
            vi.move_to(960, 500)
        finally:
            vi.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
