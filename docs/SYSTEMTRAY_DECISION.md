# System Tray Architecture Decision

**Date**: 2026-06-29  
**Decision**: Track 2 — Full C++ Fork with Pre-compilation

## Chosen Approach

Fork the plasma-workspace `applets/systemtray/` C++ code, rebrand as `org.kde.windowsmodern.systemtray`, apply Windows 11 visual styling to the QML layer, and distribute pre-compiled binaries.

## Rationale

- **Full feature parity**: Only the C++ containment model supports real Plasma applets appearing/disappearing automatically in the tray. Pure QML cannot host child applets (Containment-level PlasmoidModel is not exported to QML).
- **Event-driven SNI**: The C++ `StatusNotifierModel` reacts to DBus signals instantly, unlike the current 5-second polling.
- **Per-item configuration**: The full settings system (visibility, shortcuts, configure buttons) requires the Settings/Model architecture from C++.
- **Pre-compilation solves distribution**: By pre-compiling for target distributions, users don't need a build toolchain. They just drop files and restart plasmashell.

## Distribution Strategy

### Current: Build on Install

The system tray is a C++ Plasma::Containment. It is compiled on the user's
machine during installation via `./install.sh systray` (repo root) or
`./dev.sh` (inside the applet directory). The install scripts:

- build the `.so` with QML embedded via `ecm_target_qml_sources`,
- copy it to the distro-specific Qt plugin directory,
- remove any conflicting KPackage at `/usr/share/plasma/plasmoids/...`,
- remove stale local copies at `~/.local/lib*/qt6/plugins/plasma/applets/...`,
- restart plasmashell.

This avoids maintaining per-distribution pre-compiled binaries and ensures the
applet is built against the Plasma/Qt versions actually installed.

### Future: Pre-compiled Binaries

Once a CI pipeline is in place, per-distro `.so` artifacts may be shipped so
users without a compiler can install the applet directly. Until then, the
build-on-install approach is the supported path.

Target distributions (in priority order):
1. **Fedora** (current dev machine, `plasma-workspace-6.7.0`) — first
2. **Arch Linux** — second
3. **Debian/Ubuntu** — third
4. **openSUSE** — fourth

### Installation

```bash
./install.sh systray
```

## What Files to Fork

From `plasma-workspace/applets/systemtray/`:

**C++ Backend (keep, minimal changes):**
- `systemtray.cpp/.h` — Rename class, update metadata ID
- `systemtraymodel.cpp/.h` — Keep as-is
- `systemtraysettings.cpp/.h` — Keep as-is
- `plasmoidregistry.cpp/.h` — Keep as-is
- `statusnotifieritemhost.cpp/.h` — Keep as-is  
- `statusnotifieritemsource.cpp/.h` — Keep as-is
- `dbusserviceobserver.cpp/.h` — Keep as-is
- `sortedsystemtraymodel.cpp/.h` — Keep as-is
- `systemtraytypes.cpp/.h` — Keep as-is
- `main.xml` — Keep, add our settings entries if needed

**QML UI (full Windows 11 redesign):**
- `qml/main.qml` — Major restyle
- `qml/AbstractItem.qml` — Windows 11 hover/press effects
- `qml/StatusNotifierItem.qml` — Windows 11 icon styling
- `qml/PlasmoidItem.qml` — Windows 11 applet wrapper
- `qml/CompactApplet.qml` — Keep mostly
- `qml/ExpanderArrow.qml` — Windows 11 chevron
- `qml/ExpandedRepresentation.qml` — Windows 11 popup
- `qml/HiddenItemsView.qml` — Windows 11 grid
- `qml/ItemLoader.qml` — Keep as-is
- `qml/ConfigGeneral.qml` — Windows 11 settings page
- `qml/SystemTrayState.qml` — Keep as-is
- `qml/CurrentItemHighLight.qml` — Windows 11 highlight
- `qml/PulseAnimation.qml` — Keep
- `qml/PlasmoidPopupsContainer.qml` — Keep
- `qml/BackgroundAppItem.qml` — Windows 11 styling
- `qml/config.qml` — Keep

**Build System:**
- `CMakeLists.txt` — Rework for standalone build

## Build Dependencies (Fedora)

```
gcc-c++ cmake extra-cmake-modules
qt6-qtbase-devel qt6-qtdeclarative-devel
kf6-kpackage-devel kf6-kconfig-devel kf6-ki18n-devel kf6-kcoreaddons-devel
kf6-kwindowsystem-devel kf6-kio-devel kf6-kiconthemes-devel
kf6-kitemmodels-devel kf6-kservice-devel kf6-kxmlgui-devel
kf6-kjobwidgets-devel kf6-kcmutils-devel
libplasma-devel plasma-workspace-devel plasma-workspace-libs
```

See `plasma/applets/org.kde.windowsmodern.systemtray/BUILD.md` for
Arch Linux and Debian/Ubuntu dependency lists.

## Success Criteria

- [ ] Compiles on Fedora with plasma-workspace 6.7.0
- [ ] Installs correctly via install.sh
- [ ] Appears in Plasma panel as "System Tray (Windows Modern)"
- [ ] All existing Plasma applets appear/disappear automatically
- [ ] SNI icons appear instantly via event-driven model
- [ ] Per-item visibility configuration works
- [ ] Popups work (click, right-click context menu, activate)
- [ ] Settings page shows all items with config options
- [ ] Windows 11 visual style applied to panel icons
- [ ] Windows 11 visual style applied to popup
- [ ] Windows 11 visual style applied to settings page
