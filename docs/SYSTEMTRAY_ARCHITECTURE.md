# System Tray — Architecture & History

## Overview

The Windows Modern system tray (`org.kde.windowsmodern.systemtray`) is a C++ `Plasma::Containment` fork of the upstream plasma-workspace system tray. It replaces the default `org.kde.plasma.systemtray` with identical Plasma containment behavior — child applets (network, volume, battery, clipboard, etc.) are managed by the containment and appear/disappear automatically.

---

## Architecture

```
┌─────────────────────────────────────────────┐
│  Panel (org.kde.panel)                      │
│  ┌───────────────────────────────────────┐  │
│  │  System Tray (CustomEmbedded)         │  │
│  │  ├─ PlasmoidItem (network)            │  │
│  │  ├─ PlasmoidItem (volume)             │  │
│  │  ├─ PlasmoidItem (battery)            │  │
│  │  ├─ PlasmoidItem (notifications)      │  │
│  │  ├─ StatusNotifierItem (Discord)      │  │
│  │  ├─ StatusNotifierItem (Steam)        │  │
│  │  └─ ...                               │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Key Components

| File | Purpose |
|------|---------|
| `systemtray.cpp/.h` | C++ `Plasma::Containment` — manages child applets, DBus model, XDG activation |
| `contents/ui/main.qml` | Root `ContainmentItem` — GridView of active icons, AppletPopup, ExpanderArrow |
| `contents/ui/SystemTrayState.qml` | State machine — expanded/collapsed, active applet tracking |
| `contents/ui/ExpandedRepresentation.qml` | Popup content — heading, PlasmoidPopupsContainer, HiddenItemsView |
| `contents/ui/PlasmoidPopupsContainer.qml` | StackView for child applet FullRepresentations |
| `contents/ui/PlasmoidItem.qml` | Wrapper for each child applet icon — handles click/tooltip/context menu |
| `contents/ui/ExpanderArrow.qml` | Chevron toggle for hidden items popup |

### Data Flow

```
Plasmoid.systemTrayModel (C++ multi-source model)
  ├─ PlasmoidModel (embedded plasmoids)
  ├─ StatusNotifierModel (SNI via DBus)
  └─ BackgroundAppsModel (flatpak/background)
       │
       ▼
  KSortFilterProxyModel
  ├─ activeModel (ActiveStatus → panel icons)
  └─ hiddenModel (PassiveStatus → expander popup)
```

### Popup Mechanism

```
User clicks icon
  → PlasmoidItem.onActivated → applet.Plasmoid.activated()
  → applet.expanded = true (framework event)
  → Instantiator detects onExpandedChanged
  → SystemTrayState.setActiveApplet(applet)
  → systemTrayState.expanded = true
  → root.expanded = true (containment sync, triggers framework child-embedding)
  → dialog.visible = true (QML AppletPopup opens)
  → PlasmoidPopupsContainer shows applet.fullRepresentationItem
```

The `rootConnections` block in SystemTrayState.qml prevents the framework from independently expanding the containment (the "double popup" problem):

```qml
readonly property Connections rootConnections: Connections {
    function onExpandedChanged() {
        if (systemTrayState.acceptExpandedChange) {
            systemTrayState.expanded = root.expanded  // user-initiated
        } else {
            root.expanded = systemTrayState.expanded  // suppress framework
        }
    }
}
```

---

## Installation

The applet is a C++ plugin loaded from a shared library (`.so`). **It must NOT be installed as a KPackage plasmoid** (see [Critical Bug below](#critical-bug-duplicate-kpackage-installation)).

```bash
# Build and deploy
./dev.sh

# What dev.sh does:
# 1. cmake --build  → compile .so with embedded QML
# 2. Stop plasmashell, fix layout config if corrupted
# 3. Install .so to /usr/lib64/qt6/plugins/plasma/applets/
# 4. Remove any stale KPackage at /usr/share/plasma/plasmoids/
# 5. Restart plasmashell
```

The QML files are embedded in the `.so` via `plasma_add_applet(QML_SOURCES ...)` — same as the stock `org.kde.plasma.systemtray`.

---

## Critical Bug: Duplicate KPackage Installation

### Symptom

A dark rectangle (following the global theme) appeared alongside the system tray popup when clicking individual icons (network, volume, battery, etc.). The expander arrow did NOT have this issue.

### Root Cause

The `CMakeLists.txt` and `install.sh` installed the applet in **two** locations:

1. **`.so` plugin** at `/usr/lib64/qt6/plugins/plasma/applets/org.kde.windowsmodern.systemtray.so`
2. **KPackage plasmoid** at `/usr/share/plasma/plasmoids/org.kde.windowsmodern.systemtray/metadata.json` + `contents/`

This created a duplicate applet registration. The framework found two instances with the same plugin ID. When a child icon was clicked, the framework's child-applet-embedding lookup matched the **KPackage instance** (which had no AppletPopup with content), creating an empty themed popup window — the dark rectangle.

The stock `org.kde.plasma.systemtray` is installed ONLY as a `.so` (no KPackage), which is why it never had this issue.

### Fix

1. **Removed `install(DIRECTORY ...)` from `CMakeLists.txt`** — eliminated KPackage installation at build time
2. **Modified `dev.sh`** to only install the `.so` and `rm -rf` any existing KPackage directory
3. **Maintained `.so`-only deployment** matching the stock system tray pattern exactly

After this fix, the system tray behaves identically to the stock `org.kde.plasma.systemtray` — one popup for expander, one popup for icons, no dark rectangles.

---

## History: Original Windows 11-Style Custom Tray (v0)

Before the C++ containment fork, the system tray was a pure-QML plasmoid with a custom Windows 11-style design. The code is preserved in `contents/ui-old-windowsmodern/` and in git history (commits `5d3f6eb` through `ec3cc01`).

### Visual Design

**Panel Tray (CompactRepresentation)**
```
┌────┬────┬────┬────┬────┬────┐
│  ^  │  ♫  │  ⎘  │  ⚡  │  🔔  │  🔋  │
│hidden│media│clip │devices│notif│battery│
└────┴────┴────┴────┴────┴────┘
```
- Row of icon buttons with hover/press highlight effects
- Each button: rounded Rectangle with semi-transparent white overlay on hover/press
- `Kirigami.Icon` with symbolic variants and `T.ToolTipArea` tooltips
- Optional media player icon (visible only when MPRIS player is active)
- Hidden icons chevron rotates when popup is open (180° animation)
- Per-icon right-click context menus via `Plasmoid.contextualActions`

**Popup (FullRepresentation)**
```
┌──────────────────────────────┐
│  HIDDEN ICONS          ✕     │  ← header with label
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│  │ 🎮│ │ 💬│ │ 📡│ │ 🖨│    │  ← GridView of hidden SNI icons
│  └───┘ └───┘ └───┘ └───┘   │
└──────────────────────────────┘
```
- `StackLayout` with pages: TrayIcons, Clipboard, Devices, Notifications, Battery, MediaPlayer
- Each page: header label + content area with ListView/GridView
- Pages toggle on re-click (click clipboard icon → show clipboard page, click again → close)
- Context menus dynamically rebuilt based on hovered icon

**Page Details**

| Page | Content | Data Source |
|------|---------|-------------|
| TrayIconsPage | GridView of hidden SNI icons with tooltips | `SniModel` (DBus: `org.kde.StatusNotifierWatcher`) |
| ClipboardPage | List of clipboard entries, clear button | Klipper via DBus |
| DevicesPage | Removable devices with mount/unmount/eject | UDisks2 via DBus |
| NotificationsPage | Notification list with clear all | `NotificationManager` QML model |
| BatteryPage | Percentage, progress bar, health, sleep/lock inhibitor | `powermanagement` engine + UPower |
| MediaPlayerPage | Album art, track info, play/pause/prev/next | MPRIS via DBus (`org.mpris.MediaPlayer2.Player`) |

**Reusable TrayButton component**
```qml
component TrayButton : Item {
    Rectangle {  // hover/press background
        radius: 4
        color: containsPress ? Qt.rgba(1,1,1,0.12)
             : containsMouse ? Qt.rgba(1,1,1,0.08)
             : "transparent"
    }
    Kirigami.Icon { anchors.centerIn: parent }  // icon
    PlasmaCore.ToolTipArea { }                   // tooltip
    MouseArea { hoverEnabled: true }             // interaction
}
```

### Why It Was Replaced

The pure-QML custom tray had limitations:
- **SNI polling**: `SniModel` used a 5-second polling timer to query DBus, causing latency
- **No applet containment**: Icons were hardcoded buttons, not real Plasma applets. Network/volume/bluetooth couldn't be managed by the tray — they appeared as separate panel items
- **Limited SNI support**: Basic SNI activation only; no per-item visibility config, no keyboard shortcuts, limited context menu integration
- **UI inconsistency**: Custom pages didn't match Plasma's standard popup behavior (pin, floating, border removal)

The C++ fork (`Phase 1` commit `ec3cc01`) replaced this with a full `Plasma::Containment` based on the upstream plasma-workspace system tray, providing proper applet containment, event-driven SNI, and full Plasma integration while keeping the old custom pages in `ui-old-windowsmodern/` for future reference.
