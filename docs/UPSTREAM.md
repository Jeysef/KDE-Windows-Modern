# Upstream KDE code in Windows Modern

Some components started as copies of KDE Plasma code. This file records
where each came from, what we changed, and how to bring in upstream
changes. It answers issue #9.

Rule: keep KDE's backend and infrastructure as upstream has it, and limit
our changes to presentation and the behaviour Windows needs. Upstream code
is never merged automatically: read the upstream diff, then port by hand.

## Components

| Component | Upstream source | Based on | Plasma it needs |
|---|---|---|---|
| System tray (`plasma/applets/org.kde.windowsmodern.systemtray`) | plasma-workspace `applets/systemtray` | 6.7.0 (July 2026), ported to 6.8 | 6.7 |
| Taskbar, Icon Tasks (`plasma/applets/org.kde.windowsmodern.icontasks`) | plasma-desktop `applets/taskmanager` | 6.7 (July 2026); C++ backend synced to 6.8.0 | 6.7, KDE Frameworks 6.26 |
| Digital clock (`plasma/applets/org.kde.windowsmodern.digitalclock`) | plasma-workspace `applets/digital-clock` | 6.7 (July 2026) | 6.6 |
| Show desktop (`plasma/applets/org.kde.windowsmodern.showdesktop`) | plasma-desktop `applets/showdesktop` | June 2026 (6.6/6.7) | any 6 |
| Lock screen (`plasma/shells/org.kde.windowsmodern.lockscreen`) | plasma-workspace `lookandfeel/org.kde.breeze/contents/lockscreen` | 6.8.2 | older than 6.8 still loads (see below) |
| Login screen, greeter (`third_party/plasma-login-manager` + `plasma/look-and-feel/org.kde.windowsmodern.dark/patches`) | plasma-login-manager | v6.8.2, commit `e061af40` (git submodule) | 6.6 (Plasma Login Manager first shipped then) |

Not forks: the Start menu, Search box and Task View are our own code. The
Start menu uses KDE's Kicker models (`org.kde.plasma.private.kicker`),
which are internal and can change between Plasma versions.

Exact upstream commits were not recorded when the older forks were made
(mid-2026); the "based on" versions come from the build machine's Plasma
at the time and from comparing files with upstream tags. From now on,
record the tag or commit in this table whenever a component is synced.

## What we changed

- **System tray**: a C++ `Plasma::Containment` like upstream; the changes
  are the Windows 10 style icon row and the Quick Settings flyout
  (network, Bluetooth, volume, brightness). Upstream's `main.qml` is kept
  byte for byte. 6.8 port: applets are owned through `std::unique_ptr`
  (written so it also builds on 6.7).
- **Taskbar**: Windows 11 window previews (our own floating tooltip
  window, `floatingtooltipdialog.cpp`, shown as a tooltip so it never takes
  keyboard focus), hover tiles, window-shaped preview cards, Win+1..9
  registered by the applet itself (Plasma 6.8 moved these shortcuts into
  the stock task manager), a Chromium logo guard. `backend.cpp` and the
  smart launcher files are upstream's.
- **Digital clock**: Windows 11 flyout (big time, calendar with month,
  year and decade zoom, picked day's agenda). Time zones and the calendar
  plugins use stock Plasma's plugins
  (`org.kde.plasma.private.digitalclock`, `org.kde.plasma.workspace.calendar`).
  Stock's "Add…" button is left out on purpose: it opens the preferred
  `text/calendar` app, which on Fedora with KOrganizer is KOrganizer's file
  viewer (`korganizer --view %u`), so it does nothing without a file.
- **Show desktop**: a thin sliver at the end of the taskbar.
- **Lock screen**: Windows 11 layout; the password logic follows stock
  6.8.2. `ActiveScreenMonitor` (kscreenlocker 6.8+) is loaded through
  `ScreenMonitor.qml`, so on older Plasma the prompt simply stays shown on
  every screen.
- **Greeter**: `patches/main-cpp.patch` on top of plasma-login-manager;
  the submodule itself stays clean.

## Updating to a new Plasma version

1. Read what changed upstream since our base, for example:
   `git log --oneline v6.8.0..v6.9.0 -- applets/systemtray` in a
   plasma-workspace checkout.
2. Port the changes that matter by hand; keep ours on top.
3. Build (`./install.sh systray`, `./install.sh icontasks`), run
   `./verify-all.sh` and the live tests in `tests/` on the desktop.
4. Update the "Based on" column above.

The greeter has its own tool: `./scripts/update-plm.sh Plasma/6.N` checks
out the branch, checks the patches still apply and builds; then commit the
new submodule pointer.
