#!/usr/bin/env python3
"""Click through the optional Search/Task View buttons and the calendar zoom.

  search    clicking the Search box opens the Start menu
  taskview  clicking Task View opens KWin's Overview
  calendar  the clock flyout's title zooms out to the year; reopening shows
            today's month again
  dayshape  picking a day leaves the calendar where it was (the agenda used
            to grow the popup upwards), and the picked day stays a circle while
            hovered (it turned into a rounded square)

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
from PIL import Image  # noqa: E402

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


def dayshape(vi, out, c):
    click_node(vi, "Clock")
    time.sleep(1.2)
    days = [n for n in a11y.nodes("plasmashell") if n.showing and n.role == "button"
            and re.fullmatch(r"\d{1,2}(, .*)?", n.name) and n.rect[2] > 0]
    today = next((n for n in days if ", today" in n.name), None)
    number = lambda n: int(n.name.split(",")[0])  # noqa: E731
    # A neighbour of today in this month (spill-over days of other months are far off in number).
    pick = next((n for n in days if today and n is not today and 0 < abs(number(n) - number(today)) <= 6), None)
    c.check(pick is not None, f"a day other than today to pick ({pick and (pick.name, pick.rect)!r}, today {today and today.rect!r})")
    if not pick:
        vi.tap(e.KEY_ESC, after=0.5)
        return
    x, y = pick.centre
    vi.move_to(x, y, steps=8)
    time.sleep(0.3)
    vi.click()
    time.sleep(0.8)                                   # picked, pointer still on it: ring + hover fill
    moved = next((n for n in a11y.nodes("plasmashell") if n.showing and n.role == "button"
                  and n.name.split(",")[0] == pick.name.split(",")[0] and n.rect[0] == pick.rect[0]), None)
    c.check(moved is not None and moved.rect == pick.rect,
            f"the calendar does not move when a day is picked ({pick.rect} -> {moved and moved.rect})")
    shot = out / "dayshape.png"
    screenshot(shot)
    im = Image.open(shot).convert("RGB")
    left, top, w, h = pick.rect
    corner = im.getpixel((left + 3, top + 3))
    background = im.getpixel((left + 1, top + 1))      # the very edge of the cell
    fill = im.getpixel((x - w // 4, y))
    painted = lambda p, q: max(abs(a - b) for a, b in zip(p, q)) > 8  # noqa: E731
    c.check(painted(fill, corner), f"the hovered picked day is filled ({fill} vs corner {corner})")
    c.check(not painted(corner, background),
            f"its corners stay unpainted: a circle, not a rounded square ({corner} vs {background})")
    vi.tap(e.KEY_ESC, after=0.5)


SCENARIOS = {"search": search, "taskview": taskview, "calendar": calendar, "dayshape": dayshape}


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
