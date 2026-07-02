# System Tray (Windows Modern) — Build & Install

This is a C++ `Plasma::Containment` applet. It must be compiled — it's not a pure-QML plasmoid.

## Quick Start

```bash
cd plasma/applets/org.kde.windowsmodern.systemtray
./dev.sh
```

That's it. `dev.sh` builds the `.so`, installs it, and restarts plasmashell.

## What Not To Do

**Do NOT** copy the source directory to `~/.local/share/plasma/plasmoids/` or `/usr/share/plasma/plasmoids/`. This creates a duplicate KPackage registration that causes a "dark rectangle" popup alongside the real tray popup. The applet loads from the `.so` only.

## Dependencies (Fedora)

```
sudo dnf install gcc-c++ cmake extra-cmake-modules \
  qt6-qtbase-devel qt6-qtdeclarative-devel \
  kf6-kpackage-devel kf6-kconfig-devel kf6-ki18n-devel \
  kf6-kwindowsystem-devel kf6-kio-devel kf6-kiconthemes-devel \
  kf6-kitemmodels-devel kf6-kservice-devel kf6-kxmlgui-devel \
  kf6-kjobwidgets-devel \
  libplasma-devel plasma-workspace-devel
```

No external `dbusmenu-qt6` is needed — it's embedded from plasma-workspace's `libdbusmenuqt`.

## Manual Build

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release -S .
cmake --build build --parallel $(nproc)
```

## Manual Install

```bash
# Install .so only (no KPackage)
sudo cp build/lib/plasma/applets/org.kde.windowsmodern.systemtray.so \
        /usr/lib64/qt6/plugins/plasma/applets/

# Remove any stale KPackage
sudo rm -rf /usr/share/plasma/plasmoids/org.kde.windowsmodern.systemtray/

# Restart
systemctl --user restart plasma-plasmashell.service
```

## File Structure

```
systemtray.cpp/h          — Plasma::Containment main class
systemtraymodel.cpp/h     — Multi-source data model
systemtraysettings.cpp/h  — KConfig settings
plasmoidregistry.cpp/h    — Applet lifecycle
dbusserviceobserver.cpp/h — DBus service monitoring
statusnotifieritemhost.cpp/h — SNI watcher
statusnotifieritemsource.cpp/h — Per-SNI data (~700 lines)
sortedsystemtraymodel.cpp/h — Sorting proxy
systemtraytypes.cpp/h     — DBus type marshalling
systemtraytypedefs.h      — KDbusImageStruct, KDbusToolTipStruct
dbusmenuimporter.cpp/h    — DBusMenu protocol (from libdbusmenuqt)
dbusmenushortcut_p.cpp/h  — DBusMenu shortcut parsing
dbusmenutypes_p.cpp/h     — DBusMenu type marshalling
utils.cpp/h               — DBusMenu utility helpers
*.xml                     — DBus interface definitions

contents/ui/main.qml      — Root ContainmentItem
contents/ui/SystemTrayState.qml — State machine
contents/ui/ExpandedRepresentation.qml — Popup content
contents/ui/PlasmoidPopupsContainer.qml — Child applet popups
contents/ui/ConfigGeneral.qml — Settings page (custom)
... (14 more QML files matching upstream plasma-workspace)
```
