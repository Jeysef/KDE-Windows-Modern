#!/usr/bin/env python3
"""End-to-end tests of the Windows Modern panel inside the running session.

Drives real input (uinput), finds panel items by accessible name (AT-SPI)
and checks results by reading state: KWin's showingDesktop, the Start
menu's search text, which tray page heading is visible. Screenshots of
every step go to --out for a human (or agent) to look at.

Before each scenario the pointer wiggles in circles: hands off the mouse.
A scenario that fails is announced and retried once, since a person
touching the mouse is the most common cause.

Nothing here changes system state: no toggles are switched, the keyboard
layout and power buttons are not pressed.

Usage: tests/panel/e2e.py [--out DIR] [SCENARIO ...]
Scenarios: show-desktop start-meta start-click start-hover tray-order tray-pages
           clock quick-settings flyout-scroll flyout-hover  (default: all)

Not covered: the taskbar's right-click menu. It is a native Qt menu, and
under uinput input it closes the instant it opens (a real mouse works), so
check it by hand.
Exit status: 0 when every check passed.
"""

import argparse
import pathlib
import subprocess
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from evdev import ecodes as e  # noqa: E402

from e2e import a11y  # noqa: E402
from e2e.session import Checks, kwin_property, now, qml_warnings, screenshot  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402

APP = "plasmashell"
# Our code, for the "no new QML warnings" check.
OURS = ("windowsmodern", "/plasma/icontasks/")


class Panel:
    def __init__(self, vi, out):
        self.vi, self.out = vi, out

    def item(self, name):
        node = a11y.find(APP, name, visible=False)
        if node is None or node.rect[1] < 0:
            raise RuntimeError(f"panel item {name!r} not found")
        return node

    @property
    def screen_height(self):
        clock = self.item("Show desktop")
        return clock.rect[1] + clock.rect[3]

    def click(self, name, button=e.BTN_LEFT):
        x, y = self.item(name).centre
        self.vi.push_bottom_edge(x, self.screen_height)   # reveal an auto-hiding panel
        self.vi.move_to(x, y)
        time.sleep(0.3)
        self.vi.click(button)

    def leave(self):
        self.vi.move_to(960, 400)
        time.sleep(0.4)

    def close_popups(self):
        self.vi.tap(e.KEY_ESC)
        self.vi.tap(e.KEY_ESC)
        self.leave()

    def shot(self, name):
        screenshot(self.out / f"{name}.png")


def visible(name, role=None, exclude_window=None):
    """A node that is on screen now (AT-SPI 'showing'; closed popups keep
    their old extents, so geometry alone is not enough)."""
    for node in a11y.nodes(APP):
        if node.name == name and (role is None or node.role == role) and node.showing \
                and node.window != exclude_window:
            return node
    return None


def wait_for(predicate, timeout=3.0, step=0.25):
    deadline = time.time() + timeout
    while time.time() < deadline:
        result = predicate()
        if result:
            return result
        time.sleep(step)
    return predicate()


# ── Scenarios ──────────────────────────────────────────────────────────
def show_desktop(p, c):
    if kwin_property("showingDesktop") == "true":
        p.click("Show desktop"); time.sleep(1)
    p.click("Show desktop")
    on = wait_for(lambda: kwin_property("showingDesktop") == "true")
    p.shot("show-desktop-on")
    c.check(on, "first click shows the desktop")
    p.click("Show desktop")
    off = wait_for(lambda: kwin_property("showingDesktop") == "false")
    p.shot("show-desktop-off")
    c.check(off, "second click brings the windows back")
    p.leave()


def _start_typing(p, c, how):
    c.check(visible("Pinned") is None, "Start menu is closed before the test")
    if how == "meta":
        p.vi.tap(e.KEY_LEFTMETA)
    else:
        p.click("Start")
    opened = wait_for(lambda: visible("Pinned"))
    c.check(opened is not None, f"Start menu opens ({how})")
    time.sleep(0.4)
    query = "settings"
    p.vi.type_text(query)
    time.sleep(1.2)
    field = next((n for n in a11y.nodes(APP) if n.showing and n.role in ("text", "entry")
                  and (n.text() or "").lower() == query), None)
    p.shot(f"start-{how}-typed")
    c.check(field is not None, f"typing right after opening goes to the search field ({how})")
    c.check(visible("Pinned") is None, f"the search results replace the Pinned page ({how})")
    p.close_popups()
    c.check(wait_for(lambda: visible("Pinned") is None), f"Esc closes the Start menu ({how})")


def start_meta(p, c):
    _start_typing(p, c, "meta")


def _results():
    """Search result rows on screen, top to bottom."""
    rows = [n for n in a11y.nodes(APP) if n.showing and n.role == "list item" and n.visible
            and n.rect[2] > 200]
    return sorted(rows, key=lambda n: n.rect[1])


def start_hover(p, c):
    """Results appearing under a resting pointer must not take the
    selection (Enter runs the best match); moving the pointer does."""
    query = "settings"
    p.vi.tap(e.KEY_LEFTMETA)
    c.check(wait_for(lambda: visible("Pinned")) is not None, "Start menu opens")
    time.sleep(0.4)
    p.vi.type_text(query)
    rows = wait_for(lambda: len(_results()) >= 3 and _results(), timeout=5)
    c.check(bool(rows), "search shows at least 3 results")
    if not rows:
        p.close_popups(); return
    resting = rows[2].centre
    p.close_popups()
    wait_for(lambda: visible("Pinned") is None)

    p.vi.move_to(*resting)          # the pointer rests where the third result will be
    time.sleep(0.5)
    p.vi.tap(e.KEY_LEFTMETA)
    wait_for(lambda: visible("Pinned"))
    time.sleep(0.4)
    p.vi.type_text(query)
    rows = wait_for(lambda: len(_results()) >= 3 and _results(), timeout=5)
    time.sleep(0.8)
    rows = _results()
    p.shot("start-hover-resting")
    selected = [r.name for r in rows if r.selected]
    c.check(rows and selected == [rows[0].name],
            f"with the pointer resting, the top result stays selected (selected: {selected})")

    # Results stream in and reorder, so which row ends up under the pointer
    # is not known in advance: the check is that the selection left the
    # top result for the row the pointer moved onto.
    target = (resting[0], resting[1] + rows[1].rect[3])
    p.vi.move_to(*target, steps=8)
    time.sleep(0.5)
    rows = _results()
    selected = [r for r in rows if r.selected]
    p.shot("start-hover-moved")
    c.check(len(selected) == 1 and selected[0].name != rows[0].name,
            f"moving the pointer selects the row under it ({[r.name for r in selected]})")
    p.close_popups()


def start_click(p, c):
    c.check(a11y.find(APP, "Start", role="button", visible=False) is not None,
            "Start button is in the accessibility tree")
    _start_typing(p, c, "click")


TRAY_PAGES = ["Clipboard", "Audio Volume", "Bluetooth", "Brightness & Color", "KDE Connect",
              "Networks", "Power & Battery", "Notifications"]


def tray_pages(p, c):
    panel_window = p.item("Show desktop").window
    row_y = p.item("Show desktop").rect[1]
    for name in TRAY_PAGES:
        try:
            icon = p.item(name)
        except RuntimeError:
            icon = None
        if icon is None or icon.window != panel_window or icon.rect[1] != row_y:
            # Not in the panel row right now (e.g. Notifications hides itself
            # into the overflow when there is nothing unread).
            print(f"        ({name} is not in the panel row right now — skipped)")
            continue
        p.click(name)
        page = wait_for(lambda: visible(name, exclude_window=panel_window))
        p.shot(f"tray-{name.lower().replace(' & ', '-').replace(' ', '-')}")
        c.check(page is not None, f"tray icon {name!r} opens the {name!r} page")
        p.close_popups()


# Windows 11 ends the tray with these, left to right, before the clock.
TRAY_TAIL = ["Keyboard Layout", "Networks", "Audio Volume", "Power & Battery"]
# Not Windows tray icons: they wait behind the chevron unless pinned.
OVERFLOW_BY_DEFAULT = {"Clipboard": "org.kde.plasma.clipboard", "Bluetooth": "org.kde.plasma.bluetooth",
                       "Brightness & Color": "org.kde.plasma.brightness", "KDE Connect": "org.kde.kdeconnect"}


def pinned_tray_items():
    """Item ids the user pinned ("Always shown") in any tray."""
    rc = pathlib.Path.home() / ".config/plasma-org.kde.plasma.desktop-appletsrc"
    ids = set()
    for line in rc.read_text(errors="replace").splitlines() if rc.exists() else []:
        if line.startswith("shownItems="):
            ids.update(x for x in line.split("=", 1)[1].split(",") if x)
    return ids


def tray_order(p, c):
    """Reads positions only; nothing is clicked."""
    panel_window = p.item("Show desktop").window
    row_y = p.item("Show desktop").rect[1]
    xs = {}
    for node in a11y.nodes(APP):
        if node.window == panel_window and node.rect[1] == row_y and node.rect[2] > 0 \
                and node.role == "button" and node.name:
            xs.setdefault(node.name, node.rect[0])
    tail = [n for n in TRAY_TAIL if n in xs]
    p.shot("tray-order")
    print(f"        tray, left to right: {sorted((n for n in xs if xs[n] > xs.get('Start', 0) + 400), key=xs.get)}")
    c.check(len(tail) >= 3, f"most of {TRAY_TAIL} are in the panel row (found {tail})")
    c.check(sorted(tail, key=xs.get) == tail, f"{' → '.join(tail)} in Windows order")
    others = [n for n, x in xs.items() if n not in TRAY_TAIL and tail and xs[tail[0]] < x < xs[tail[-1]]]
    c.check(not others, f"nothing sits between them (found {others})")
    pinned = pinned_tray_items()
    stray = [n for n, i in OVERFLOW_BY_DEFAULT.items() if n in xs and i not in pinned]
    c.check(not stray, f"non-Windows icons wait behind the chevron unless pinned (in the row: {stray})")
    if tail and "Clock" in xs:
        between = [n for n, x in xs.items() if xs[tail[-1]] < x < xs["Clock"] and n != "Show hidden icons"]
        c.check(not between, f"only the chevron between {tail[-1]!r} and the clock (found {between})")


def clock(p, c):
    panel_window = p.item("Show desktop").window
    year = time.strftime("%Y")
    p.click("Clock")
    header = wait_for(lambda: next((n for n in a11y.nodes(APP) if n.window != panel_window and n.showing
                                    and n.role == "label" and n.name.endswith(year)), None))
    p.shot("clock")
    c.check(header is not None, f"clock opens the calendar ({header.name!r})" if header else "clock opens the calendar")
    labels = [n.name for n in a11y.nodes(APP) if header and n.window == header.window and n.showing
              and n.role == "label" and len(n.name) > 8 and not n.name.endswith(year)]
    print(f"        flyout labels: {labels[:3]}")
    p.close_popups()


def quick_settings(p, c):
    panel_window = p.item("Show desktop").window
    p.click("Show hidden icons")
    tile = wait_for(lambda: visible("Wi-Fi", exclude_window=panel_window))
    p.shot("quick-settings")
    c.check(tile is not None, "chevron opens Quick Settings (Wi-Fi tile visible)")
    gear = visible("All settings", exclude_window=panel_window)
    c.check(gear is not None, "Quick Settings has the Settings gear in its footer")
    if pathlib.Path("/sys/class/power_supply/BAT0").exists() or pathlib.Path("/sys/class/power_supply/BAT1").exists():
        battery = next((n for n in a11y.nodes(APP) if n.showing and n.window != panel_window
                        and n.name.startswith("Battery ") and n.name.endswith("%")), None)
        c.check(battery is not None, f"the footer shows the battery level ({battery.name if battery else None})")
    p.close_popups()


def _cards(panel_window):
    """The hidden-icon cards in the flyout (above the Quick Settings tiles)."""
    wifi = visible("Wi-Fi", exclude_window=panel_window)
    return sorted((n for n in a11y.nodes(APP) if n.showing and n.role == "list item" and n.visible
                   and n.window != panel_window and wifi and n.rect[1] < wifi.rect[1]),
                  key=lambda n: (n.rect[1], n.rect[0]))


def _patch(img, x, y, size=5):
    """Mean colour of a small square."""
    px = [img.getpixel((x + i, y + j)) for i in range(size) for j in range(size)]
    return tuple(sum(c[k] for c in px) / len(px) for k in range(3))


def _differs(a, b, threshold=4):
    return max(abs(a[k] - b[k]) for k in range(3)) > threshold


def flyout_hover(p, c):
    """A card shows a background only while the pointer is on it: none is
    left behind on a card the pointer has left (the grid's keyboard
    highlight used to follow the pointer and stay)."""
    from PIL import Image
    panel_window = p.item("Show desktop").window
    p.click("Show hidden icons")
    c.check(wait_for(lambda: visible("Wi-Fi", exclude_window=panel_window)) is not None, "Quick Settings opens")
    time.sleep(0.8)
    cards = _cards(panel_window)
    if len(cards) < 2:
        print(f"        (only {len(cards)} hidden-icon cards: skipped)")
        p.close_popups()
        return
    # Every card's name fits inside the card (two-line names used to spill
    # past its bottom edge, visible on hover).
    labels = [n for n in a11y.nodes(APP) if n.showing and n.role == "label" and n.window != panel_window
              and n.visible]
    spill = []
    for card in cards:
        x, y, w, h = card.rect
        for lab in labels:
            lx, ly, lw, lh = lab.rect
            if x <= lx + lw // 2 <= x + w and y <= ly < y + h and ly + lh > y + h:
                spill.append(f"{lab.name!r} ({ly + lh - (y + h)} px)")
    c.check(not spill, f"every card's name fits inside the card (spilling: {spill})")

    a, b = cards[0], cards[1]
    corner = lambda n: (n.rect[0] + 4, n.rect[1] + 4)  # noqa: E731
    gap = (a.rect[0] - 4, a.rect[1] + a.rect[3] // 2)  # flyout background left of card A

    def look(name):
        p.shot(name)
        img = Image.open(p.out / f"{name}.png").convert("RGB")
        return _patch(img, *gap), _patch(img, *corner(a)), _patch(img, *corner(b))

    p.vi.move_to(a.rect[0] + a.rect[2] // 2, a.rect[1] + a.rect[3] - 8)
    time.sleep(0.6)
    bg, ca, cb = look("hover-a")
    c.check(_differs(ca, bg), f"hovering {a.name!r} shows its background")
    p.vi.move_to(b.rect[0] + b.rect[2] // 2, b.rect[1] + b.rect[3] - 8)
    time.sleep(0.6)
    bg, ca, cb = look("hover-b")
    c.check(not _differs(ca, bg), f"{a.name!r} goes back to plain when the pointer moves on")
    c.check(_differs(cb, bg), f"{b.name!r} shows the hover")
    p.vi.move_to(gap[0] - 60, gap[1])  # off the cards, left of the flyout
    time.sleep(0.6)
    bg, ca, cb = look("hover-none")
    c.check(not _differs(ca, bg) and not _differs(cb, bg), "no card keeps a background once the pointer left")
    # Open B's page and come back: the grid gets focus again when shown.
    p.vi.move_to(b.rect[0] + b.rect[2] // 2, b.rect[1] + b.rect[3] - 8)
    time.sleep(0.3)
    p.vi.click()
    back = wait_for(lambda: visible("Back", exclude_window=panel_window)
                    or visible("Go Back", exclude_window=panel_window))  # ours / stock pages
    c.check(back is not None, f"{b.name!r} opens its page")
    if back:
        p.vi.move_to(*back.centre)
        time.sleep(0.3)
        p.vi.click()
        wait_for(lambda: len(_cards(panel_window)) >= 2)
        p.vi.move_to(gap[0] - 60, gap[1])
        time.sleep(0.8)
        cards = _cards(panel_window)
        p.shot("after-back")
        img = Image.open(p.out / "after-back.png").convert("RGB")
        bg = _patch(img, *gap)
        lit = [n.name or f"card {i + 1}" for i, n in enumerate(cards) if _differs(_patch(img, *corner(n)), bg)]
        c.check(not lit, f"after Back, no card looks selected (lit: {lit})")
        # Not checked: keyboard navigation of the cards. After Back the arrow
        # keys do not reach the card grid (a limitation older than this test).
    p.close_popups()


def brightness():
    out = subprocess.run(["busctl", "--user", "get-property", "org.kde.ScreenBrightness",
                          "/org/kde/ScreenBrightness/display0", "org.kde.ScreenBrightness.Display",
                          "Brightness"], capture_output=True, text=True).stdout.split()
    return int(out[1]) if len(out) == 2 else None


def flyout_scroll(p, c):
    """Scrolling over the flyout's cards must not act on them (it moved the
    brightness). The wheel goes up then down, so even a failure ends where
    it started."""
    panel_window = p.item("Show desktop").window
    p.click("Show hidden icons")
    card = wait_for(lambda: visible("Brightness & Color", exclude_window=panel_window), timeout=6)
    if card is None:
        # Hidden by default (Quick Settings has the slider); the check runs
        # when the user brings the card back ("Always hidden" in the tray).
        print("        (no Brightness & Color card in the flyout — skipped)")
        p.close_popups()
        return
    time.sleep(1)  # the flyout settles (cards shift as sections fill in)
    card = visible("Brightness & Color", exclude_window=panel_window)
    before = brightness()
    p.vi.move_to(*card.centre)
    p.shot("flyout-scroll-at")
    print(f"        scrolling at {card.centre}")
    p.vi.scroll(-3)
    after = brightness()
    p.shot("flyout-scroll")
    moved = visible("Brightness & Color", exclude_window=panel_window)
    print(f"        the card moved {card.rect[1]} → {moved.rect[1] if moved else '(scrolled out)'}"
          " (the grid scrolls when it has more than 3 rows)")
    p.vi.scroll(3)
    after = after if after != before else brightness()
    c.check(before is not None and after == before,
            f"scrolling over the Brightness card leaves brightness alone ({before} → {after})")
    p.close_popups()


SCENARIOS = {"show-desktop": show_desktop, "start-meta": start_meta, "start-click": start_click,
             "start-hover": start_hover,
             "tray-order": tray_order, "tray-pages": tray_pages, "clock": clock,
             "quick-settings": quick_settings, "flyout-scroll": flyout_scroll,
             "flyout-hover": flyout_hover}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--out", type=pathlib.Path, default=pathlib.Path("panel-e2e"))
    parser.add_argument("scenarios", nargs="*", metavar="SCENARIO", help=" ".join(SCENARIOS))
    args = parser.parse_args()
    unknown = [s for s in args.scenarios if s not in SCENARIOS]
    if unknown:
        parser.error(f"unknown scenario(s): {', '.join(unknown)}")
    args.out.mkdir(parents=True, exist_ok=True)
    chosen = args.scenarios or list(SCENARIOS)

    since = now()
    failed = []
    with a11y.enabled():
        time.sleep(2)  # let Qt apps join the accessibility tree
        vi = VirtualInput()
        panel = Panel(vi, args.out.resolve())
        try:
            for name in chosen:
                for attempt in (1, 2):
                    print(f"scenario {name}" + (" (retry)" if attempt == 2 else ""))
                    vi.announce()
                    checks = Checks()
                    try:
                        SCENARIOS[name](panel, checks)
                    except Exception as ex:  # a missing item, a timeout
                        checks.check(False, f"{name} raised {ex!r}")
                        panel.close_popups()
                    if not checks.failures:
                        break
                else:
                    failed.append(name)
        finally:
            vi.tap(e.KEY_ESC)
            vi.close()

    ours = [w for w in qml_warnings(since) if any(o in w for o in OURS)]
    others = [w for w in qml_warnings(since) if w not in ours]
    print(f"QML warnings from our applets: {len(ours)}")
    for w in sorted(set(ours)):
        print("        " + w)
    if others:
        print(f"(QML warnings from other Plasma components: {len(others)}, not ours)")
    if ours:
        failed.append("qml-warnings")
    print(f"screenshots in {args.out.resolve()}")
    print("FAILED: " + ", ".join(failed) if failed else "ALL PASSED")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
