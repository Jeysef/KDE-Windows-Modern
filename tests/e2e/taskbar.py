"""The taskbar's task buttons, found through AT-SPI, and KWin's active window.

Panel positions from AT-SPI are screen coordinates (popups are not: their
positions are relative to the popup window).
"""
import pathlib
import subprocess
import tempfile
import time

from e2e import a11y

NOT_TASKS = ("Search", "Task View")       # optional Windows Modern buttons next to Start


def task_buttons(include_buttons=False):
    """Buttons right of Start on the same panel row, up to the first gap (the tray).

    Other widgets on the panel (system monitors left of Start, the tray) are
    not tasks; the Search/Task View buttons are skipped unless asked for.
    """
    start = a11y.find("plasmashell", "Start", role="button", visible=False)
    if not start:
        raise RuntimeError("Start button not found")
    row_y, panel_win = start.rect[1], start.window
    nodes = sorted((n for n in a11y.nodes("plasmashell")
                    if n.showing and n.role == "button" and n.window == panel_win and n.rect[1] == row_y
                    and n.rect[2] > 0 and n.name and n.rect[0] >= start.rect[0] + start.rect[2]),
                   key=lambda n: n.rect[0])
    out, edge = [], start.rect[0] + start.rect[2]
    for n in nodes:
        if n.rect[0] - edge > 8:
            break
        out.append(n)
        edge = n.rect[0] + n.rect[2]
    return out if include_buttons else [n for n in out if n.name not in NOT_TASKS]


def active_window():
    """resourceClass of KWin's active window ("" if none), via a one-off KWin script."""
    marker = f"WM-ACTIVE-{time.time_ns()}"
    js = pathlib.Path(tempfile.mkdtemp()) / "active.js"
    js.write_text(f'var w = workspace.activeWindow; console.info("{marker} " + (w ? w.resourceClass : ""));')
    call = ["dbus-send", "--session", "--print-reply", "--type=method_call", "--dest=org.kde.KWin", "/Scripting"]
    name = f"wm-active-{marker}"
    sid = subprocess.run([*call, "org.kde.kwin.Scripting.loadScript", f"string:{js}", f"string:{name}"],
                         capture_output=True, text=True).stdout.split()[-1]
    subprocess.run(["dbus-send", "--session", "--type=method_call", "--dest=org.kde.KWin",
                    f"/Scripting/Script{sid}", "org.kde.kwin.Script.run"])
    time.sleep(0.4)
    subprocess.run([*call, "org.kde.kwin.Scripting.unloadScript", f"string:{name}"], capture_output=True)
    log = subprocess.run(["journalctl", "--user", "--since", "-30s", "--no-pager", "-o", "cat"],
                         capture_output=True, text=True).stdout
    line = next((l for l in reversed(log.splitlines()) if marker in l), "")
    return line.split(marker, 1)[1].strip() if line else ""
