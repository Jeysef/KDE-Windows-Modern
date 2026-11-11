#!/usr/bin/env python3
"""Windows keyboard shortcuts for KDE Plasma, applied through kglobalaccel.

Keys KDE already maps like Windows (Win+E, Win+I, Win+L, Win+D, Win+V, Win+.,
Win+P, Win+Shift+S, Win+Left/Right, Win+1..9) are left alone. This moves the
rest to where Windows has them:

  Win+Up / Win+Down   maximize / restore / minimize / quarter-snap (KWin script)
  Win+Tab             Task View (KWin Overview), not window cycling
  Win+R               Run (KRunner), not screen recording
  Win+M, Win+Home     minimize all / all others
  Win+A / Win+N       Quick Settings / notifications (tray, see "tray" below)
  Win+PrtSc           full screenshot saved silently; Alt+PrtSc active window
  Ctrl+Shift+Esc      Mission Center (group "apps")

The previous keys of every touched action are saved once to
~/.local/share/windows-modern/backup/shortcuts.json; --restore puts them back.

Usage: windows-shortcuts.py apply   [--group shortcuts|apps] [--dry-run]
       windows-shortcuts.py restore [--group shortcuts|apps]
       windows-shortcuts.py tray-apply | tray-restore   (Plasma Shell must be stopped)
       windows-shortcuts.py show
"""
import argparse
import json
import pathlib
import subprocess
import sys

from gi.repository import Gio, GLib

BACKUP = pathlib.Path.home() / ".local/share/windows-modern/backup/shortcuts.json"

MODS = {"Meta": 0x10000000, "Ctrl": 0x04000000, "Alt": 0x08000000, "Shift": 0x02000000}
KEYS = {"F2": 0x01000031, "Search": 0x01000092, "Up": 0x01000013, "Down": 0x01000015, "Left": 0x01000012, "Right": 0x01000014,
        "Tab": 0x01000001, "Backtab": 0x01000002, "Print": 0x01000009, "Esc": 0x01000000,
        "Home": 0x01000010, "Space": 0x20}
MOD_MASK = 0xFE000000

# (group, component, action, friendly component, friendly action, change)
# change: ("remove", [keys]) | ("remove-mod", "Meta") | ("add", [keys]) | ("set", [keys])
# Removals run before additions, so a key is free before it is taken.
CHANGES = [
    ("shortcuts", "kwin", "Window Quick Tile Top", "", "", ("remove", ["Meta+Up"])),
    ("shortcuts", "kwin", "Window Quick Tile Bottom", "", "", ("remove", ["Meta+Down"])),
    ("shortcuts", "kwin", "Walk Through Windows", "", "", ("remove-mod", "Meta")),
    ("shortcuts", "kwin", "Walk Through Windows (Reverse)", "", "", ("remove-mod", "Meta")),
    ("shortcuts", "plasmashell", "next activity", "", "", ("remove", ["Meta+A"])),
    ("shortcuts", "org.kde.spectacle.desktop", "RecordRegion", "", "", ("remove", ["Meta+R"])),
    ("shortcuts", "kwin", "Windows Modern: Maximize or Snap Up", "", "", ("set", ["Meta+Up"])),
    ("shortcuts", "kwin", "Windows Modern: Restore, Minimize or Snap Down", "", "", ("set", ["Meta+Down"])),
    ("shortcuts", "kwin", "Overview", "", "", ("add", ["Meta+Tab"])),
    ("shortcuts", "kwin", "MinimizeAll", "", "", ("set", ["Meta+M"])),
    ("shortcuts", "kwin", "minimizeAllOthers", "", "", ("set", ["Meta+Home"])),
    ("shortcuts", "org.kde.krunner.desktop", "_launch", "", "", ("add", ["Meta+R"])),
    ("shortcuts", "org.kde.spectacle.desktop", "ActiveWindowScreenShot", "", "", ("set", ["Alt+Print"])),
    ("shortcuts", "windowsmodern-screenshot.desktop", "_launch", "Screenshot (full screen, saved)",
     "Screenshot (full screen, saved)", ("set", ["Meta+Print"])),
    ("apps", "org.kde.plasma-systemmonitor.desktop", "_launch", "", "", ("remove", ["Ctrl+Shift+Esc"])),
    ("apps", "io.missioncenter.MissionCenter.desktop", "_launch", "Mission Center", "Mission Center",
     ("add", ["Ctrl+Shift+Esc"])),
]


def parse(text):
    *mods, key = text.split("+")
    value = KEYS.get(key) or ord(key.upper())
    for m in mods:
        value |= MODS[m]
    return value


def fmt(value):
    names = [m for m, bit in MODS.items() if value & bit]
    key = value & ~MOD_MASK
    names.append(next((k for k, v in KEYS.items() if v == key), chr(key) if 32 <= key < 127 else hex(key)))
    return "+".join(names)


class GlobalAccel:
    def __init__(self):
        self.proxy = Gio.DBusProxy.new_for_bus_sync(
            Gio.BusType.SESSION, Gio.DBusProxyFlags.NONE, None,
            "org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel", None)

    def _call(self, method, sig, args):
        return self.proxy.call_sync(method, GLib.Variant(sig, args), Gio.DBusCallFlags.NONE, 5000, None)

    def keys(self, aid):
        """Combined key values of an action (first key of each sequence)."""
        result = self._call("shortcutKeys", "(as)", (aid,)).unpack()[0]
        return [seq[0][0] for seq in result if seq[0] and seq[0][0]]

    def set_keys(self, aid, values, present=False):
        seqs = [([v, 0, 0, 0],) for v in values]
        if present:
            # A launcher entry registered at runtime only fires once it is
            # marked present (normally done when kglobalaccel loads it at
            # login); setForeignShortcutKeys stores the keys but never does.
            set_present, no_autoloading = 0x2, 0x4
            self._call("setShortcutKeys", "(asa(ai)u)", (aid, seqs, set_present | no_autoloading))
        else:
            self._call("setForeignShortcutKeys", "(asa(ai))", (aid, seqs))

    def register(self, aid):
        self._call("doRegister", "(as)", (aid,))


def action_id(component, action, fcomp, faction):
    return [component, action, fcomp, faction]


def wanted(current, change):
    kind, arg = change
    if kind == "remove":
        drop = {parse(k) for k in arg}
        return [k for k in current if k not in drop]
    if kind == "remove-mod":
        return [k for k in current if not k & MODS[arg]]
    if kind == "add":
        return current + [parse(k) for k in arg if parse(k) not in current]
    return [parse(k) for k in arg]  # set


def load_backup():
    return json.loads(BACKUP.read_text()) if BACKUP.exists() else {}


def apply(group, dry_run):
    ga = GlobalAccel()
    backup = load_backup()
    changes = [c for c in CHANGES if c[0] == group]
    failed = 0
    for _, comp, action, fcomp, faction, change in changes:
        aid = action_id(comp, action, fcomp, faction)
        if fcomp and not dry_run:
            ga.register(aid)  # a launcher entry for an app or our .desktop
        current = ga.keys(aid)
        new = wanted(current, change)
        backup.setdefault(f"{comp}|{action}", current)
        line = f"  {comp} :: {action}: {', '.join(map(fmt, current)) or '-'} -> {', '.join(map(fmt, new)) or '-'}"
        if new == current or dry_run:
            print(line + ("" if new != current else "  (already)"))
            continue
        ga.set_keys(aid, new, present=bool(fcomp))
        got = ga.keys(aid)
        ok = sorted(got) == sorted(new)
        failed += not ok
        print(line + ("" if ok else f"  FAILED (now {', '.join(map(fmt, got)) or '-'})"))
    if not dry_run:
        BACKUP.parent.mkdir(parents=True, exist_ok=True)
        BACKUP.write_text(json.dumps(backup, indent=1))
    return 1 if failed else 0


def restore(group):
    ga = GlobalAccel()
    backup = load_backup()
    # Reverse order: our actions give their keys up before the original
    # owners take them back.
    for _, comp, action, fcomp, faction, _change in reversed([c for c in CHANGES if c[0] == group]):
        key = f"{comp}|{action}"
        if key not in backup:
            continue
        ga.set_keys(action_id(comp, action, fcomp, faction), backup.pop(key))
        print(f"  restored {comp} :: {action}")
    if backup:
        BACKUP.write_text(json.dumps(backup, indent=1))
    elif BACKUP.exists():
        BACKUP.unlink()
    return 0


# ── Tray: Win+A opens Quick Settings, Win+N the notifications ────────────
# Plasma keeps an applet's global shortcut in its own config group
# ([...][Applets][N][Shortcuts] global=...), read when Plasma Shell starts.
APPLETSRC = pathlib.Path.home() / ".config/plasma-org.kde.plasma.desktop-appletsrc"
TRAYS = ("org.kde.windowsmodern.systemtray", "org.kde.plasma.systemtray")
TRAY_KEYS = {None: "Meta+A", "org.kde.plasma.notifications": "Meta+N"}  # None = the tray itself


def _groups():
    """{group path tuple: {key: value}} from the applets config."""
    groups, cur = {}, None
    for line in APPLETSRC.read_text(errors="replace").splitlines():
        if line.startswith("[") and line.endswith("]"):
            cur = tuple(line[1:-1].split("]["))
            groups.setdefault(cur, {})
        elif cur and "=" in line:
            k, v = line.split("=", 1)
            groups[cur][k] = v
    return groups


def tray_targets():
    """[(group path, key)] for the tray on the primary screen's panel."""
    groups = _groups()
    panels = sorted((int(g[1]) for g, kv in groups.items()
                     if len(g) == 2 and g[0] == "Containments" and kv.get("plugin") == "org.kde.panel"
                     and kv.get("lastScreen") == "0"))
    for panel in panels:
        for g, kv in groups.items():
            if len(g) == 4 and g[:3] == ("Containments", str(panel), "Applets") and kv.get("plugin") in TRAYS:
                out = [(g, TRAY_KEYS[None])]
                for c, ckv in groups.items():
                    if len(c) == 6 and c[:4] == g and c[4] == "Applets" and ckv.get("plugin") in TRAY_KEYS:
                        out.append((c, TRAY_KEYS[ckv["plugin"]]))
                return out
    return []


def _kconfig(path, value=None, delete=False):
    args = ["--file", str(APPLETSRC)]
    for g in path + ("Shortcuts",):
        args += ["--group", g]
    args += ["--key", "global"]
    if delete:
        return subprocess.run(["kwriteconfig6", *args, "--delete"], check=True)
    if value is not None:
        return subprocess.run(["kwriteconfig6", *args, value], check=True)
    return subprocess.run(["kreadconfig6", *args], check=False, capture_output=True, text=True).stdout.strip()


def tray_apply():
    targets = tray_targets()
    if not targets:
        print("  no system tray found on the primary screen's panel — skipped")
        return 0
    backup = load_backup()
    for path, key in targets:
        backup.setdefault("applet|" + "/".join(path), _kconfig(path))
        _kconfig(path, key)
        print(f"  {'/'.join(path[1:])}: {key}")
    BACKUP.parent.mkdir(parents=True, exist_ok=True)
    BACKUP.write_text(json.dumps(backup, indent=1))
    return 0


def tray_restore():
    backup = load_backup()
    for name in [k for k in backup if k.startswith("applet|")]:
        path = tuple(name.split("|", 1)[1].split("/"))
        old = backup.pop(name)
        if old:
            _kconfig(path, old)
        else:
            _kconfig(path, delete=True)
        print(f"  restored {'/'.join(path[1:])}")
    if backup:
        BACKUP.write_text(json.dumps(backup, indent=1))
    elif BACKUP.exists():
        BACKUP.unlink()
    return 0


def show():
    ga = GlobalAccel()
    for group, comp, action, fcomp, faction, _ in CHANGES:
        keys = ga.keys(action_id(comp, action, fcomp, faction))
        print(f"  [{group}] {comp} :: {action}: {', '.join(map(fmt, keys)) or '-'}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("command", choices=["apply", "restore", "tray-apply", "tray-restore", "show"])
    ap.add_argument("--group", choices=["shortcuts", "apps"], default="shortcuts")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    if args.command == "tray-apply":
        return tray_apply()
    if args.command == "tray-restore":
        return tray_restore()
    try:
        if args.command == "apply":
            return apply(args.group, args.dry_run)
        if args.command == "restore":
            return restore(args.group)
        return show()
    except GLib.Error as ex:
        print(f"kglobalaccel not reachable ({ex.message}) — is a Plasma session running?")
        return 1


if __name__ == "__main__":
    sys.exit(main())
