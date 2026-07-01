# System Tray Analysis: Plasma Generic vs Windows Modern

## Executive Summary

The **Plasma generic system tray** (`org.kde.plasma.systemtray`) is a C++/QML hybrid applet that uses a **Containment** model (applets are first-class Plasma applets that can be added/removed). The **Windows Modern system tray** (`org.kde.windowsmodern.systemtray`) is a **pure QML applet** that manually polls DBus for SNI items and replaces the entire system tray experience with a hardcoded Windows 11-style UI.

The key missing capability in Windows Modern: **it does not support Plasma applet containment**. It only displays StatusNotifierItem (SNI) icons via manual DBus polling. The Plasma generic tray can host actual Plasma applets (like Network Manager, Bluetooth, KDE Connect, updates notifier, etc.) that appear/disappear automatically and have full interactive popups.

## Architecture Comparison

### Plasma Generic System Tray (`org.kde.plasma.systemtray`)

**Type**: C++ `Plasma::Containment` + QML UI  
**Location**: `plasma-workspace/applets/systemtray/` (upstream)  

#### Component Architecture

```
SystemTray (C++ Containment)
├── SystemTraySettings         # KConfig-based settings management
│   ├── extraItems             # Enabled plasmoids list
│   ├── knownItems             # All known plasmoids
│   ├── shownItems             # Force-shown items
│   ├── hiddenItems            # Force-hidden items
│   ├── showAllItems           # Global show-all toggle
│   ├── disabledStatusNotifiers # Disabled SNI items
│   ├── reverseIconOrder       # Panel icon ordering
│   ├── scaleIconsToFit        # Auto-scale vs small fixed size
│   └── iconSpacing            # Spacing multiplier
│
├── PlasmoidRegistry           # Discovers & manages Plasma applets
│   ├── Watches for applet install/uninstall via DBus
│   ├── Uses DBusServiceObserver for DBus-activatable applets
│   └── Emits plasmoidEnabled/plasmoidStopped signals
│
├── SystemTrayModel            # Concatenates 3 data models
│   ├── PlasmoidModel          # Plasma applet items
│   │   └── Each item has: applet pointer, KPluginMetaData, status
│   ├── StatusNotifierModel    # SNI items (via StatusNotifierItemHost)
│   │   └── Uses real StatusNotifierWatcher (event-driven, not polling!)
│   └── BackgroundAppsModel    # Flatpak background apps (filtered)
│
├── SortedSystemTrayModel      # Sorting proxy (config page vs panel)
│
├── QML: main.qml              # ContainmentItem with GridLayout
│   ├── activeModel            # KSortFilterProxyModel: effectiveStatus==Active
│   ├── hiddenModel            # KSortFilterProxyModel: effectiveStatus==Passive
│   ├── Instantiator           # Creates plasmoid connections
│   │   ├── activeInstantiator # Tracks expanded state of active applets
│   │   └── hiddenInstantiator # Tracks expanded state of hidden applets
│   ├── GridView (tasksGrid)   # Shows active model items inline
│   ├── ExpanderArrow          # Toggle hidden popup
│   ├── CurrentItemHighLight   # Visual highlight for active item
│   └── PlasmaCore.AppletPopup # Main popup
│       └── ExpandedRepresentation
│           ├── Header (back button, title, pin, configure)
│           └── Content
│               ├── HiddenItemsView  # 2-column grid of hidden items
│               └── PlasmoidPopupsContainer  # Active applet popup
│
├── QML: ItemLoader            # Loads PlasmoidItem.qml, StatusNotifierItem.qml,
│                              # or BackgroundAppItem.qml based on itemType
│
├── QML: AbstractItem          # Base delegate for all item types
│   ├── ToolTipArea with icon + label
│   ├── MouseArea with click/press/contextMenu/wheel
│   ├── PulseAnimation for NeedsAttention status
│   └── Press animation (scale 0.8)
│
├── QML: PlasmoidItem          # Delegate for Plasma applets
│   ├── Wraps actual PlasmoidItem (applet) inside
│   ├── Forwards click/press/wheel to applet's mouse areas
│   └── Preloads fullRepresentation for instant popup
│
├── QML: StatusNotifierItem    # Delegate for SNI icons
│   ├── Uses model roles: Icon, AttentionIcon, Title, etc.
│   ├── Left-click: activate (or open context menu if ItemIsMenu)
│   ├── Middle-click: secondaryActivate
│   ├── Right-click: contextMenu
│   └── Scroll: sends delta to SNI
│
├── QML: BackgroundAppItem     # Delegate for flatpak background apps
│   ├── Shows app icon + label
│   └── Click to open, context menu to stop
│
├── QML: CompactApplet         # Container for applet compact representation
│
├── QML: SystemTrayState       # State object (expanded, activeApplet)
│
└── QML: ConfigGeneral.qml     # Rich settings page
    ├── Per-item visibility: auto/shown/hidden/disabled
    ├── Per-item keyboard shortcut
    ├── Per-item configure button
    ├── Search filter
    ├── Panel icon size: small / scale-with-panel
    ├── Spacing: small/normal/large
    ├── Direction: reverses icon order
    ├── Show all toggle
    └── Warning messages for disabling critical items
```

#### Key Data Flow

```
App Installed/Starts
  → DBus: org.kde.StatusNotifierWatcher emits StatusNotifierItemRegistered
  → StatusNotifierItemHost::itemAdded(service)
  → StatusNotifierModel::addSource(service)
  → Model row inserted
  → SortedSystemTrayModel sorts and filters
  → activeModel / hiddenModel filter by effectiveStatus
  → GridView (active) or HiddenItemsView (passive) updates
  → Icon appears in panel
```

For Plasma applets:
```
PlasmoidRegistry detects new applet
  → Emits plasmoidEnabled(pluginId)
  → SystemTray::startApplet(pluginId)
  → Creates real Plasma::Applet, adds to containment
  → PlasmoidModel::addApplet(applet)
  → Model row inserted (with applet pointer)
  → Same flow as above
```

#### configuration settings (full)

```
main.xml:
  extraItems:             StringList  # Enabled plasma applet IDs
  disabledStatusNotifiers: StringList # Disabled SNI item IDs
  hiddenItems:            StringList  # Force-hidden item IDs
  shownItems:             StringList  # Force-shown item IDs
  showAllItems:           bool        # Show everything in panel
  knownItems:             StringList  # All known applet IDs (internal)
  reverseIconOrder:       bool        # Reverse panel icon direction
  scaleIconsToFit:        bool        # Auto-scale vs fixed 22px
  iconSpacing:            int         # Spacing multiplier
  pin:                    bool        # Keep popup open
```

---

### Windows Modern System Tray (`org.kde.windowsmodern.systemtray`)

**Type**: Pure QML `PlasmoidItem`  
**Location**: `plasma/applets/org.kde.windowsmodern.systemtray/`

#### Component Architecture

```
PlasmoidItem (main.qml)
├── SniModel                   # Manual DBus polling (every 5 sec)
│   ├── Polls StatusNotifierWatcher for RegisteredStatusNotifierItems
│   ├── Queries each SNI item individually via GetAll
│   └── Maintains own ListModel (not real QAbstractItemModel)
│
├── MediaPlayerModel           # Wraps Mpris.MultiplexerModel
│   └── Exposes election logic for best player
│
├── CompactRepresentation      # Panel view: Row of TrayButton
│   ├── Chevron button (tray hidden icons)
│   ├── Media player icon
│   ├── Clipboard icon
│   ├── Removable devices icon
│   ├── Notifications icon
│   └── Battery icon
│   └── Each TrayButton: Rectangle + Kirigami.Icon + ToolTipArea
│
├── FullRepresentation         # Expanded popup: StackLayout with 6 pages
│   ├── TrayIconsPage          # GridView of hidden SNI icons
│   ├── ClipboardPage          # Klipper history via DBus
│   ├── DevicesPage            # UDisks2 devices via DBus
│   ├── NotificationsPage      # Notification history (NM.Notifications)
│   ├── BatteryPage            # Battery info + power controls
│   └── MediaPlayerPage        # Full media player controls
│
├── ConfigGeneral.qml          # Minimal settings
│   ├── iconSize: Int (16-32)
│   ├── spacing: Int (0-12)
│   └── showExpandArrow: Bool
│
└── main.xml                   # KConfig schema (3 entries only)
```

#### Key Data Flow

```
Timer fires (every 5 seconds)
  → SniModel._refreshWatcher()
  → DBus: Get RegisteredStatusNotifierItems
  → _syncItems(): diff old vs new, add/remove items
  → For each new item: GetAll properties via DBus
  → model ListModel updated
  → CompactRepresentation.chevron visibility bound to model.count > 0
  → Hidden icons appear in TrayIconsPage grid
```

#### configuration settings (minimal)

```
main.xml:
  iconSize:      Int (16-32, default 22)
  spacing:       Int (0-12, default 4)
  showExpandArrow: Bool (default true)
```

---

## Feature Gap Matrix

| Feature | Plasma Generic | Windows Modern | Priority |
|---------|---------------|----------------|----------|
| **Plasma applet support** | ✅ Real Plasma::Applet containment | ❌ Not supported | Critical |
| **Auto-icon appearance** | ✅ Event-driven via DBus + signals | ❌ 5-sec polling only | Critical |
| **Plasma applet popups** | ✅ PlasmoidPopupsContainer | ❌ N/A | Critical |
| **Per-item visibility config** | ✅ auto/shown/hidden/disabled | ❌ None | Critical |
| **Per-item keyboard shortcuts** | ✅ Configurable | ❌ None | High |
| **Per-item configure buttons** | ✅ Opens applet settings | ❌ None | High |
| **Pin popup** | ✅ Keep-open toggle | ❌ None | Medium |
| **Icon scaling** | ✅ Fixed 22px or scale-to-panel | ❌ Only fixed configurable | Medium |
| **Icon spacing** | ✅ 3 presets via multiplier | ❌ Simple int range | Low |
| **Reverse icon order** | ✅ Yes | ❌ None | Medium |
| **Show all items toggle** | ✅ Yes | ❌ None | Medium |
| **Disabled SNI support** | ✅ Yes | ❌ None | High |
| **Background apps (Flatpak)** | ✅ Yes | ❌ None | Low |
| **Drag-and-drop applet add** | ✅ Yes | ❌ None | Low |
| **CurrentItemHighlight** | ✅ Visual indicator | ❌ None | Low |
| **Attention pulse animation** | ✅ PulseAnimation | ❌ None | Low |
| **SNI activation** | ✅ Proper xdg_activation + fallback | ✅ DBus direct call | Medium |
| **SNI context menus** | ✅ Real QMenu with positioning | ❌ DBus call only (no visual) | High |
| **SNI scroll support** | ✅ Yes | ❌ None | Low |
| **Media player** | ❌ Separate plasmoid | ✅ Built-in | N/A |
| **Clipboard** | ❌ Separate plasmoid | ✅ Built-in via Klipper DBus | N/A |
| **Devices** | ❌ Separate plasmoid | ✅ Built-in via UDisks2 | N/A |
| **Notifications page** | ❌ Separate plasmoid | ✅ Built-in via NM.Notifications | N/A |
| **Battery page** | ❌ Separate plasmoid | ✅ Built-in + power controls | N/A |
| **Settings richness** | ❌ 9 config entries | ✅ 3 config entries | Critical |
| **Popup style** | ❌ Breeze/standard | ✅ Windows 11 style | Target |

---

## Fundamental Architectural Differences

### 1. Containment vs Applet

**Plasma Generic**: `SystemTray` extends `Plasma::Containment` (can host child applets). This is the secret sauce that enables icons to appear/disappear automatically. The system tray *itself* is a containment that launches and manages child Plasma applets.

**Windows Modern**: `PlasmoidItem` - a simple applet. It cannot host other applets. It manually polls and manages everything itself. This is why it can't auto-add Plasma applet icons.

### 2. Data Model Architecture

**Plasma Generic**:
- `SystemTrayModel` (QConcatenateTablesProxyModel) combines 3 real models
- `PlasmoidModel` (C++) watches for applet add/remove
- `StatusNotifierModel` (C++) uses event-driven `StatusNotifierItemHost`
- `BackgroundAppsModel` (C++) monitors flatpak background apps
- `SortedSystemTrayModel` (QSortFilterProxyModel) sorts by category/name
- `KItemModels.KSortFilterProxyModel` in QML filters active/passive

**Windows Modern**:
- `SniModel` is a pure QML `Item` that manually polls DBus every 5 seconds
- Uses `ListModel` (not QAbstractItemModel), so no proxy/filter/sort
- No model for Plasma applets at all
- Hardcoded icon buttons for media/clipboard/devices/notifications/battery

### 3. SNI Data Source

**Plasma Generic**: Uses `StatusNotifierItemHost` (C++ singleton) which connects to `org.kde.StatusNotifierWatcher` via DBus signals. When a new SNI registers, the signal fires immediately and the model updates. No polling.

**Windows Modern**: Uses `DBus.SessionBus.asyncCall` inside a `Timer` fired every 5 seconds. Slower, more CPU usage, misses rapid add/remove, and has a 5-second delay before new icons appear.

### 4. Popup Mechanism

**Plasma Generic**: Uses `PlasmaCore.AppletPopup` which is a proper window. Popups can be pinned. Each applet's full representation is preloaded (loaded invisible then reparented when needed). Context menus are real QMenus with proper positioning.

**Windows Modern**: Uses `FullRepresentation` as a QML `Item` inside the applet's full representation. A simple `StackLayout` toggles between 6 pages. Context menus are just DBus calls (no visual feedback).

---

## Implementation Strategy Options

### Option A: Start with Plasma Generic Code, Add Windows 11 Style

1. Take the Plasma generic system tray source (C++ + QML)
2. Re-brand it as `org.kde.windowsmodern.systemtray`
3. Modify the QML UI layer to have Windows 11 visual style
4. Keep the C++ backend intact (Containment, models, settings)
5. Add the Windows Modern extras (media player, clipboard, etc.) as additional applets or integrated pages

**Pros**: Full feature parity immediately, proven architecture
**Cons**: Requires C++ compilation, more complex build system, harder to distribute

### Option B: Rewrite in Pure QML Using Available C++ Infrastructure

1. Use `Plasma::Containment` type in QML (if possible in Plasma 6)
2. Use the installed `org.kde.plasma.private.systemtray` QML plugin for `StatusNotifierModel`
3. Re-implement the PlasmoidModel logic in QML (or use Instantiator-based approach)
4. Keep Windows 11 visual style
5. Add the Windows Modern extras

**Pros**: Pure QML (easier distribution), can leverage installed C++ code
**Cons**: Need to verify Containment QML support, may still need some C++

### Option C: Hybrid - Fork the Plasma Generic

1. Fork `applets/systemtray/` from plasma-workspace
2. Replace QML files with Windows 11 styled versions
3. Modify C++ minimally (add hooks for custom popups)
4. Build as separate package

**Pros**: Full feature parity, maintainable
**Cons**: Requires C++ build infrastructure

### Recommended Approach

**Option A** followed by gradual redesign:
1. First: Copy the plasma-workspace systemtray code, rename, get it building with Windows Modern theming
2. Second: Once feature-complete, incrementally redesign the popups and visual style
3. Third: Integrate the Windows Modern "extra" pages as proper Plasmoid applets that the containment can host

This ensures we never lose functionality and can validate at each step.
