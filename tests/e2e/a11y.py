"""Find UI by accessible name through AT-SPI, with screen coordinates.

Qt applications only join the accessibility tree while the session's
org.a11y.Status.IsEnabled switch is on; `enabled()` turns it on for the
duration of a test and restores the previous value.

Coordinates: panel items report real screen coordinates. Items inside
popups report coordinates relative to the popup (Wayland does not tell
clients where their popups are), so use those only to read names/state.
"""

import contextlib
import subprocess
import time

import gi
gi.require_version("Atspi", "2.0")
from gi.repository import Atspi  # noqa: E402


def _a11y_property(name, value=None):
    base = ["busctl", "--user"]
    if value is None:
        out = subprocess.run(base + ["get-property", "org.a11y.Bus", "/org/a11y/bus", "org.a11y.Status", name],
                             capture_output=True, text=True).stdout.split()
        return out[-1] == "true" if out else False
    subprocess.run(base + ["set-property", "org.a11y.Bus", "/org/a11y/bus", "org.a11y.Status", name,
                           "b", "true" if value else "false"], check=True)


@contextlib.contextmanager
def enabled():
    previous = _a11y_property("IsEnabled")
    _a11y_property("IsEnabled", True)
    try:
        yield
    finally:
        _a11y_property("IsEnabled", previous)


class Node:
    def __init__(self, acc, depth, window):
        self.acc, self.depth, self.window = acc, depth, window
        self.name = acc.get_name() or ""
        self.role = acc.get_role_name()
        ext = acc.get_extents(Atspi.CoordType.SCREEN)
        self.rect = (ext.x, ext.y, ext.width, ext.height)

    @property
    def centre(self):
        x, y, w, h = self.rect
        return x + w // 2, y + h // 2

    @property
    def visible(self):
        return self.rect[2] > 0 and self.rect[3] > 0

    @property
    def showing(self):
        """On screen right now. Closed popups keep their old extents, so use
        this rather than `visible` for anything inside a popup."""
        try:
            return self.acc.get_state_set().contains(Atspi.StateType.SHOWING)
        except Exception:
            return False

    @property
    def selected(self):
        try:
            return self.acc.get_state_set().contains(Atspi.StateType.SELECTED)
        except Exception:
            return False

    def text(self):
        try:
            return Atspi.Text.get_text(self.acc, 0, Atspi.Text.get_character_count(self.acc))
        except Exception:
            return None

    def __repr__(self):
        return f"<{self.role} {self.name!r} {self.rect} window={self.window}>"


def application(name, timeout=10):
    deadline = time.time() + timeout
    while time.time() < deadline:
        desk = Atspi.get_desktop(0)
        for i in range(desk.get_child_count()):
            app = desk.get_child_at_index(i)
            if app and app.get_name() == name:
                return app
        time.sleep(0.5)
    raise RuntimeError(f"{name} is not in the accessibility tree")


def nodes(app_name):
    """Every accessible node of an application, flattened."""
    app = application(app_name)
    out = []

    def walk(acc, depth, window):
        try:
            out.append(Node(acc, depth, window))
            for i in range(acc.get_child_count()):
                child = acc.get_child_at_index(i)
                if child:
                    walk(child, depth + 1, window)
        except Exception:
            pass

    for w in range(app.get_child_count()):
        win = app.get_child_at_index(w)
        if win:
            walk(win, 0, w)
    return out


def find(app_name, name, role=None, visible=True):
    """First node whose name matches exactly (and role, if given)."""
    for node in nodes(app_name):
        if node.name == name and (role is None or node.role == role) and (not visible or node.visible):
            return node
    return None
