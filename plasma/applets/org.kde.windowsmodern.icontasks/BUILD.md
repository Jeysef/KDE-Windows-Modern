# Build Instructions: Windows Modern Icon Tasks

## Prerequisites

This applet requires C++ compilation (forked from `org.kde.plasma.taskmanager`
in plasma-desktop, with full backend functionality preserved).

### Install Build Dependencies

**Fedora:**
```bash
sudo dnf install gcc-c++ cmake extra-cmake-modules \
  qt6-qtbase-devel qt6-qtdeclarative-devel \
  kf6-kpackage-devel kf6-kconfig-devel kf6-ki18n-devel kf6-kcoreaddons-devel \
  kf6-kwindowsystem-devel kf6-kio-devel kf6-kservice-devel kf6-kxmlgui-devel \
  kf6-knotifications-devel \
  plasma-activities-devel plasma-activities-stats-devel \
  libplasma-devel plasma-workspace-devel \
  libksysguard-devel
```

**Arch Linux:**
```bash
sudo pacman -S cmake extra-cmake-modules qt6-base qt6-declarative \
  kpackage kconfig ki18n kwindowsystem kio kservice kxmlgui knotifications \
  plasma-activities plasma-activities-stats \
  plasma-framework plasma-workspace \
  libksysguard
```

**Debian/Ubuntu:**
```bash
sudo apt install cmake extra-cmake-modules \
  qt6-base-dev qt6-declarative-dev \
  libkf6package-dev libkf6config-dev libkf6i18n-dev \
  libkf6windowsystem-dev libkf6kio-dev libkf6service-dev libkf6xmlgui-dev \
  libkf6notifications-dev \
  libplasma-dev plasma-workspace-dev \
  plasma-activities-dev plasma-activities-stats-dev \
  libksysguard-dev
```

## Build

```bash
cd plasma/applets/org.kde.windowsmodern.icontasks

cmake -B build -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build --parallel $(nproc)
```

## Install

The recommended way is to use the repository-wide installer, which builds,
installs the `.so`, removes any conflicting KPackage, prunes stale local
copies, and restarts plasmashell:

```bash
cd plasma/applets/org.kde.windowsmodern.icontasks
./dev.sh
```

Or from the repo root:

```bash
./install.sh icontasks
```

If you prefer a manual install:

```bash
sudo cmake --install build
systemctl --user restart plasma-plasmashell.service
```

## Local plugin shadowing

If you have an old copy of the plugin at
`~/.local/lib64/qt6/plugins/plasma/applets/org.kde.windowsmodern.icontasks.so`
(or `~/.local/lib/qt6/plugins/...`), Qt will load that local copy instead of
the system one, and your changes will appear to have no effect. The install
scripts above remove these stale copies automatically.

## Pre-compiled Binary Distribution

After building, the only runtime artifact is:

```
/usr/lib64/qt6/plugins/plasma/applets/org.kde.windowsmodern.icontasks.so
```

The QML and config files are compiled into the `.so` via
`ecm_target_qml_sources`. A separate KPackage directory at
`/usr/share/plasma/plasmoids/org.kde.windowsmodern.icontasks/` must
**not** be installed — it causes rendering bugs.

For distribution, bundle the `.so` with an install script that copies it to
the distro-specific Qt plugin directory. Users do not need a C++ compiler —
they just need the runtime libs which come with any Plasma installation.

## File Summary

### C++ Source (from upstream plasma-desktop, unchanged)
```
backend.cpp/.h                  - Jump lists, places, recent docs, app categories, parent PID
smartlauncherbackend.cpp/.h     - Smart launcher badge backend
smartlauncheritem.cpp/.h        - Per-app badge count items
kactivitymanagerd_plugins_settings.kcfg   - Activity manager config schema
kactivitymanagerd_plugins_settings.kcfgc  - KCFG code generation settings
```

### QML UI (from upstream, with Win11 customizations)
```
contents/ui/main.qml                    - Root plasmoid
contents/ui/Task.qml                    - Task button + tooltip trigger
contents/ui/ToolTipDelegate.qml         - Tooltip content loader
contents/ui/ToolTipInstance.qml         - Single-window tooltip (Win11-styled)
contents/ui/ToolTipWindowMouseArea.qml  - Tooltip hover mouse area
contents/ui/ToolTipDialog.qml           - Custom PlasmaCore.Dialog (translucency)
contents/ui/ConfigAppearance.qml        - Appearance settings (+ translucency)
contents/ui/ConfigBehavior.qml          - Behavior settings
contents/ui/ContextMenu.qml             - Right-click context menu
contents/ui/GroupDialog.qml             - Grouped task popup
contents/ui/code/theme.js               - Translucency constants
contents/ui/code/LayoutMetrics.js       - Layout calculations
contents/ui/code/TaskTools.js           - Shared task utilities
contents/config/main.xml                - KConfig schema
```
