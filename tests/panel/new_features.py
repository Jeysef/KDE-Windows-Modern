#!/usr/bin/env python3
"""Click through the optional Search/Task View buttons and the calendar zoom.

  search    clicking the Search box opens the Start menu
  taskview  clicking Task View opens KWin's Overview
  calendar  the clock flyout's title zooms out to the year; reopening shows
            today's month again

Each scenario closes what it opened (Esc). Screenshots go to OUT_DIR.
Usage: tests/panel/new_features.py OUT_DIR [SCENARIO ...]
"""
import pathlib
import re
import subprocess
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from evdev import ecodes as e  # noqa: E402

from e2e import a11y  # noqa: E402
from e2e.session import Checks, screenshot  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402


def start_menu_open():
    """The Start menu's search field is showing."""
    return any(n.showing and n.role in ("entry", "text") and n.rect[2] > 200
               and n.window != a11y.find("plasmashell", "Start", visible=False).window
               for n in a11y.nodes("plasmashell"))


def overview_active():
    out = subprocess.run(["dbus-send", "--session", "--print-reply", "--dest=org.kde.KWin", "/Effects",
                          "org.freedesktop.DBus.Properties.Get", "string:org.kde.kwin.Effects",
                          "string:activeEffects"], capture_output=True, text=True).stdout
    return '"overview"' in out


def wait_for(pred, timeout=4.0):
    end = time.time() + timeout
    while time.time() < end:
        if pred():
            return True
        time.sleep(0.2)
    return False


def click_node(vi, name):
    n = a11y.find("plasmashell", name, visible=False)
    if not n:
        raise RuntimeError(f"{name} not found")
    vi.move_to(*n.centre)
    time.sleep(0.3)
    vi.click()


def search(vi, out, c):
    click_node(vi, "Search")
    time.sleep(1.2)
    screenshot(out / "search-click.png")
    c.check(start_menu_open(), "clicking the Search box opens the Start menu")
    vi.tap(e.KEY_ESC, after=0.6)
    c.check(not start_menu_open(), "Esc closes it")


def taskview(vi, out, c):
    click_node(vi, "Task View")
    c.check(wait_for(overview_active), "clicking Task View opens the Overview")
    vi.tap(e.KEY_ESC, after=0.3)
    c.check(wait_for(lambda: not overview_active()), "Esc closes it")


def texts():
    return {n.name for n in a11y.nodes("plasmashell") if n.showing and n.name}


def calendar(vi, out, c):
    click_node(vi, "Clock")
    time.sleep(1.2)
    screenshot(out / "calendar-month.png")
    # "listopad 2026", "November 2026": a word and a year, nothing else
    month_title = next((t for t in texts() if re.fullmatch(r"[^\d\W][^\d]* \d{4}", t)), None)
    c.check(month_title is not None, f"the flyout shows a 'Month Year' title ({month_title!r})")
    if not month_title:
        vi.tap(e.KEY_ESC, after=0.5)
        return
    click_node(vi, month_title)
    time.sleep(0.8)
    screenshot(out / "calendar-year.png")
    year = month_title[-4:]
    c.check(wait_for(lambda: year in texts() and month_title not in texts()),
            f"the title zooms out to the year ({year})")
    vi.tap(e.KEY_ESC, after=0.6)
    click_node(vi, "Clock")
    time.sleep(1.2)
    c.check(month_title in texts(), "reopening the flyout shows today's month again")
    screenshot(out / "calendar-reopen.png")
    vi.tap(e.KEY_ESC, after=0.5)


SCENARIOS = {"search": search, "taskview": taskview, "calendar": calendar}


def main():
    out = pathlib.Path(sys.argv[1]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    chosen = sys.argv[2:] or list(SCENARIOS)
    failed = []
    with a11y.enabled():
        time.sleep(2)
        vi = VirtualInput()
        try:
            vi.announce()
            for name in chosen:
                print(f"scenario {name}")
                c = Checks()
                try:
                    SCENARIOS[name](vi, out, c)
                except Exception as ex:  # noqa: BLE001
                    c.check(False, f"{name} raised {ex!r}")
                    vi.tap(e.KEY_ESC, after=0.5)
                if c.failures:
                    failed.append(name)
        finally:
            vi.close()
    print(f"FAILED: {', '.join(failed)}" if failed else "ALL PASSED")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
