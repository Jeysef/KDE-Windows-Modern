# Build Instructions: Windows Modern System Tray

## Prerequisites

This applet requires C++ compilation (it's a Plasma Containment, not a pure QML plasmoid).

### Install Build Dependencies

**Fedora:**
```bash
sudo dnf install gcc-c++ cmake extra-cmake-modules \
  qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel \
  kf6-kpackage-devel kf6-kconfig-devel kf6-ki18n-devel kf6-kcoreaddons-devel \
  kf6-kwindowsystem-devel kf6-kio-devel kf6-kiconthemes-devel \
  kf6-kitemmodels-devel kf6-kservice-devel kf6-kxmlgui-devel \
  kf6-kjobwidgets-devel kf6-kcmutils-devel \
  plasma-framework-devel plasma-workspace-devel plasma-workspace-libs \
  dbusmenu-qt6-devel
```

**Arch Linux:**
```bash
sudo pacman -S cmake extra-cmake-modules qt6-base qt6-declarative \
  kpackage kconfig ki18n kwindowsystem kio kiconthemes \
  kitemmodels kservice kxmlgui kjobwidgets kcmutils \
  plasma-framework plasma-workspace dbusmenu-qt6
```

**Debian/Ubuntu:**
```bash
sudo apt install cmake extra-cmake-modules \
  qt6-base-dev qt6-declarative-dev \
  libkf6package-dev libkf6config-dev libkf6i18n-dev \
  libkf6windowsystem-dev libkf6kio-dev libkf6iconthemes-dev \
  libkf6itemmodels-dev libkf6service-dev libkf6xmlgui-dev \
  libkf6jobwidgets-dev libkf6kcmutils-dev \
  libplasma-dev plasma-workspace-dev \
  libdbusmenu-qt6-dev
```

## Build

```bash
cd plasma/applets/org.kde.windowsmodern.systemtray

cmake -B build -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build --parallel $(nproc)
```

## Install

```bash
sudo cmake --install build
```

Then restart plasmashell:
```bash
systemctl --user restart plasma-plasmashell.service
# or
plasmashell --replace &
```

## Pre-compiled Binary Distribution

After building, the resulting files are:

```
/usr/lib64/qt6/plugins/plasma/applets/org.kde.windowsmodern.systemtray.so
/usr/share/plasma/plasmoids/org.kde.windowsmodern.systemtray/
```

For distribution, bundle these two items together with an install.sh that copies them to the correct locations. Users do not need a C++ compiler — they just need the runtime libs which come with any Plasma installation.

## File Summary

### C++ Source (38 files)
```
systemtray.h/.cpp              - Main Plasma::Containment class
systemtraymodel.h/.cpp         - Data models (PlasmoidModel, StatusNotifierModel, SystemTrayModel)
systemtraysettings.h/.cpp      - KConfig settings management
plasmoidregistry.h/.cpp        - Applet discovery and lifecycle
dbusserviceobserver.h/.cpp     - DBus service start/stop monitoring
statusnotifieritemhost.h/.cpp  - SNI watcher singleton
statusnotifieritemsource.h/.cpp- Per-SNI data source (~700 lines)
sortedsystemtraymodel.h/.cpp   - Sorting proxy model
systemtraytypes.h/.cpp         - DBus type marshalling
systemtraytypedefs.h           - KDbusImageStruct, KDbusToolTipStruct
debug.h                        - Logging category
metadata.json                  - Plugin metadata (org.kde.windowsmodern.systemtray)
kf6_org.kde.StatusNotifierItem.xml        - DBus interface XML
kf6_org.kde.StatusNotifierWatcher.xml     - DBus interface XML
org.freedesktop.DBus.Properties.xml       - DBus interface XML
CMakeLists.txt                 - Build system
```

### QML UI (15 files)
```
contents/ui/main.qml                    - Root ContainmentItem
contents/ui/AbstractItem.qml            - Base delegate for all item types
contents/ui/PlasmoidItem.qml            - Plasma applet delegate
contents/ui/StatusNotifierItem.qml      - SNI icon delegate
contents/ui/BackgroundAppItem.qml       - Flatpak background app delegate
contents/ui/ItemLoader.qml              - Dynamic delegate loader
contents/ui/CompactApplet.qml           - Applet compact view wrapper
contents/ui/ExpanderArrow.qml           - Chevron toggle button
contents/ui/ExpandedRepresentation.qml  - Popup content
contents/ui/HiddenItemsView.qml         - Hidden items grid
contents/ui/PlasmoidPopupsContainer.qml - Active applet popup container
contents/ui/ConfigGeneral.qml           - Settings page
contents/ui/SystemTrayState.qml         - State management
contents/ui/CurrentItemHighLight.qml    - Active item highlight
contents/ui/PulseAnimation.qml          - Attention pulse animation
contents/ui/config.qml                  - Config category
contents/config/main.xml                - KConfig schema (9 settings)
```

### Old Windows Modern Files (preserved for Phase 3)
```
contents/ui-old-windowsmodern/
  BatteryPage.qml, ClipboardPage.qml, CompactRepresentation.qml,
  DevicesPage.qml, FullRepresentation.qml, MediaPlayerModel.qml,
  MediaPlayerPage.qml, NotificationsPage.qml, SniModel.qml,
  TrayIconsPage.qml
```
