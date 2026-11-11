"""Virtual keyboard + mouse through uinput, as real input to the compositor.

The mouse is switched to flat acceleration (through KWin's input-device
D-Bus API), so relative motion maps 1:1 to logical pixels and absolute
positions are reached by homing to the top-left corner first.
"""

import math
import re
import time

from evdev import UInput, ecodes as e

from .session import kwin_call

DEVICE_NAME = "windows-modern-e2e"
KEYS = [e.KEY_LEFTALT, e.KEY_LEFTMETA, e.KEY_TAB, e.KEY_ESC, e.KEY_ENTER, e.KEY_BACKSPACE,
        e.KEY_LEFT, e.KEY_RIGHT, e.KEY_UP, e.KEY_DOWN, e.KEY_SPACE,
        e.KEY_LEFTSHIFT, e.KEY_LEFTCTRL, e.KEY_SYSRQ, e.KEY_HOME] + \
       [getattr(e, f"KEY_{c}") for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"]


class VirtualInput:
    def __init__(self):
        caps = {e.EV_KEY: KEYS + [e.BTN_LEFT, e.BTN_RIGHT, e.BTN_MIDDLE], e.EV_REL: [e.REL_X, e.REL_Y, e.REL_WHEEL]}
        self.ui = UInput(caps, name=DEVICE_NAME)
        self.pos = None
        time.sleep(1.5)  # let the compositor pick up the device
        self._make_mouse_flat()

    def _make_mouse_flat(self):
        tree = kwin_call("/org/kde/KWin/InputDevice", "org.freedesktop.DBus.Introspectable.Introspect")
        for node in re.findall(r'node name="([^"]+)"', tree):
            path = f"/org/kde/KWin/InputDevice/{node}"
            name = kwin_call(path, "org.freedesktop.DBus.Properties.Get",
                             "string:org.kde.KWin.InputDevice", "string:name")
            if DEVICE_NAME in name:
                for prop, value in (("pointerAccelerationProfileFlat", "variant:boolean:true"),
                                    ("pointerAcceleration", "variant:double:0")):
                    kwin_call(path, "org.freedesktop.DBus.Properties.Set",
                              "string:org.kde.KWin.InputDevice", f"string:{prop}", value)

    # ── keyboard ──
    def key(self, code, down):
        self.ui.write(e.EV_KEY, code, 1 if down else 0)
        self.ui.syn()

    def tap(self, code, hold=0.05, after=0.25):
        self.key(code, True); time.sleep(hold); self.key(code, False); time.sleep(after)

    def type_text(self, text):
        for ch in text:
            self.tap(e.KEY_SPACE if ch == " " else getattr(e, f"KEY_{ch.upper()}"), after=0.08)

    # ── pointer ──
    def _rel(self, dx, dy):
        self.ui.write(e.EV_REL, e.REL_X, dx)
        self.ui.write(e.EV_REL, e.REL_Y, dy)
        self.ui.syn()
        time.sleep(0.01)

    def _glide(self, dx_total, dy_total, steps):
        done_x = done_y = 0
        for i in range(1, steps + 1):
            tx, ty = round(dx_total * i / steps), round(dy_total * i / steps)
            self._rel(tx - done_x, ty - done_y)
            done_x, done_y = tx, ty
            time.sleep(0.015)

    def move_to(self, x, y, steps=20):
        """Move to absolute (x, y). The first move homes to the top-left
        corner; later moves glide from the last known position (small steps
        also produce the hover events a real mouse does)."""
        if self.pos is None:
            for _ in range(12):
                self._rel(-500, -500)
            self.pos = (0, 0)
        self._glide(x - self.pos[0], y - self.pos[1], steps)
        self.pos = (x, y)
        time.sleep(0.15)

    def push_bottom_edge(self, x, screen_height):
        """Reveal an auto-hiding bottom panel the way a user does: push the
        pointer into the bottom edge. The compositor clamps the pointer to
        the last row, so the position afterwards is exact."""
        self.move_to(x, screen_height - 20)
        for _ in range(25):
            self._rel(0, 20); time.sleep(0.02)
        self.pos = (x, screen_height - 1)
        time.sleep(0.9)

    def click(self, button=e.BTN_LEFT):
        self.key(button, True); time.sleep(0.06); self.key(button, False); time.sleep(0.1)

    def scroll(self, notches):
        """Wheel notches at the pointer: positive scrolls up."""
        step = 1 if notches > 0 else -1
        for _ in range(abs(notches)):
            self.ui.write(e.EV_REL, e.REL_WHEEL, step)
            self.ui.syn()
            time.sleep(0.08)
        time.sleep(0.3)

    def right_click(self):
        self.click(e.BTN_RIGHT)

    def announce(self, centre=(960, 540), radius=80, seconds=2.0):
        """Wiggle the pointer in circles so a person at the machine knows an
        automated run is starting and keeps their hands off the mouse."""
        self.move_to(centre[0] + radius, centre[1])
        x, y = centre[0] + radius, centre[1]
        steps = int(seconds / 0.02)
        for i in range(1, steps + 1):
            angle = 2 * math.pi * 2 * i / steps  # two full circles
            nx = round(centre[0] + radius * math.cos(angle))
            ny = round(centre[1] + radius * math.sin(angle))
            self._rel(nx - x, ny - y)
            x, y = nx, ny
            time.sleep(0.01)
        self.pos = (x, y)
        time.sleep(0.3)

    def close(self):
        self.ui.close()
