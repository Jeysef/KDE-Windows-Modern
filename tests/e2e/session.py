"""Live-session helpers: screenshots, KWin D-Bus calls, the user journal."""

import json
import pathlib
import subprocess
import time


def _spectacle_last_save(value=None):
    """Read, or with value write back, Spectacle's remembered save location."""
    args = ["--file", "spectaclerc", "--group", "ImageSave", "--key", "lastImageSaveLocation"]
    if value is None:
        return subprocess.run(["kreadconfig6", *args], capture_output=True, text=True).stdout.strip()
    if value:
        subprocess.run(["kwriteconfig6", *args, value], check=False)
    else:
        subprocess.run(["kwriteconfig6", *args, "--delete"], check=False)
    return value


def screenshot(path):
    # Spectacle remembers every --output path as the user's last save
    # location ("Save As" then opens in our temp folder). Put it back.
    pathlib.Path(path).parent.mkdir(parents=True, exist_ok=True)
    saved = _spectacle_last_save()
    try:
        subprocess.run(["spectacle", "--background", "--nonotify", "--fullscreen", "--output", str(path)],
                       timeout=30, check=True)
        # spectacle can return before it has saved (it may hand the capture
        # to a running instance) and writes its config after the file.
        end = time.time() + 10
        while time.time() < end and not pathlib.Path(path).exists():
            time.sleep(0.1)
        time.sleep(0.5)
    finally:
        _spectacle_last_save(saved)


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
