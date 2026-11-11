"""Live-session helpers: screenshots, KWin D-Bus calls, the user journal."""

import json
import subprocess
import time


def screenshot(path):
    subprocess.run(["spectacle", "--background", "--nonotify", "--fullscreen", "--output", str(path)],
                   timeout=30, check=True)


def kwin_call(path, method, *args):
    return subprocess.run(["dbus-send", "--session", "--print-reply", "--type=method_call",
                           "--dest=org.kde.KWin", path, method, *args],
                          capture_output=True, text=True).stdout


def kwin_property(name):
    reply = kwin_call("/KWin", "org.freedesktop.DBus.Properties.Get", "string:org.kde.KWin", f"string:{name}")
    return reply.split()[-1] if reply else None


def kwin_reconfigure():
    kwin_call("/KWin", "org.kde.KWin.reconfigure")


def now():
    return time.strftime("%Y-%m-%d %H:%M:%S")


def journal(since, comm=None):
    args = ["journalctl", "--user", "-b", "--since", since, "--no-pager", "-o", "cat"]
    if comm:
        args.append(f"_COMM={comm}")
    return subprocess.run(args, capture_output=True, text=True).stdout.splitlines()


def qml_warnings(since, comm="plasmashell", ignore=()):
    """QML warnings (lines carrying a qrc:/ or file:/ location) since a time."""
    return [line for line in journal(since, comm)
            if ("qrc:/" in line or "file:/" in line) and not any(i in line for i in ignore)]


class Checks:
    """Collects PASS/FAIL lines; a scenario fails if any check fails."""

    def __init__(self):
        self.failures = []

    def check(self, ok, message):
        print(("  PASS  " if ok else "  FAIL  ") + message)
        if not ok:
            self.failures.append(message)
        return ok


def dump(obj):
    return json.dumps(obj, ensure_ascii=False)
