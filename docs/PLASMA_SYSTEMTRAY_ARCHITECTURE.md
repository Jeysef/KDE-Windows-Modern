# Plasma Generic System Tray Architecture — Reverse Engineered

## Source Location

```
plasma-workspace/applets/systemtray/
├── CMakeLists.txt
├── metadata.json                    # Plugin: org.kde.plasma.systemtray
├── main.xml                         # KConfig schema (9 settings)
├── Messages.sh
├── autotests/                       # Unit tests
├── tests/                           # Integration tests
├── qml/                             # QML UI layer (17 files)
│   ├── main.qml                     # Root ContainmentItem (17.9KB)
│   ├── AbstractItem.qml             # Base delegate (6.3KB)
│   ├── BackgroundAppItem.qml        # Flatpak background app delegate (2.2KB)
│   ├── CompactApplet.qml            # Wrapper for applet compact rep (2.0KB)
│   ├── ConfigGeneral.qml            # Settings UI (23.2KB)
│   ├── config.qml                   # Config shell (0.3KB)
│   ├── CurrentItemHighLight.qml     # Active item highlight (5.5KB)
│   ├── ExpandedRepresentation.qml   # Popup content (13.0KB)
│   ├── ExpanderArrow.qml            # Chevron button (3.4KB)
│   ├── HiddenItemsView.qml          # Grid of hidden items (2.4KB)
│   ├── ItemLoader.qml               # Dynamic delegate loader (1.3KB)
│   ├── PlasmoidItem.qml             # Applet delegate (7.3KB)
│   ├── PlasmoidPopupsContainer.qml  # Active applet popup container (4.1KB)
│   ├── PulseAnimation.qml           # Attention pulse effect (1.0KB)
│   ├── StatusNotifierItem.qml       # SNI delegate (2.8KB)
│   └── SystemTrayState.qml          # State management object (3.6KB)
├── dbusserviceobserver.cpp/.h       # Watches DBus service start/stop
├── plasmoidregistry.cpp/.h          # Applet discovery & lifecycle
├── sortedsystemtraymodel.cpp/.h     # Sorting proxy model
├── statusnotifieritemhost.cpp/.h    # SNI watcher singleton
├── statusnotifieritemsource.cpp/.h  # Per-SNI data source
├── systemtray.cpp/.h                # Main Containment class
├── systemtraymodel.cpp/.h           # All data models
├── systemtraysettings.cpp/.h        # Settings management
└── systemtraytypes.cpp/.h           # Common types
```

## C++ Class Hierarchy

```
SystemTray (Plasma::Containment)
├── SystemTraySettings (QObject)             # Settings read/write/notify
│   └── SystemTray::onEnabledAppletsChanged() # Reacts to config changes
│
├── PlasmoidRegistry (QObject)               # Applet lifecycle manager
│   ├── DBusServiceObserver                  # Watches DBus activatable services
│   └── SystemTraySettings                   # Reads/writes known/enabled plugins
│
├── SystemTrayModel (QConcatenateTablesProxyModel)  # Combined model
│   ├── PlasmoidModel (BaseModel)            # Plasma applet items
│   │   ├── KPluginMetaData per registered applet
│   │   └── Plasma::Applet* per running applet
│   ├── StatusNotifierModel (BaseModel)      # SNI items
│   │   └── StatusNotifierItemSource* per SNI service
│   └── BackgroundAppsFilteredModel          # Flatpak background apps
│       └── BackgroundAppsModel (BaseModel)
│
├── SortedSystemTrayModel (QSFPM)           # First sorting layer
│   ├── Used for panel display (SystemTray sorting)
│   └── Used for config page (ConfigurationPage sorting)
│
└── QML Layer (17 files)                     # Visual representation
```

## Data Models Deep Dive

### BaseModel (base class)

```cpp
class BaseModel : public QAbstractListModel {
    enum BaseRole {
        ItemType = Qt::UserRole + 1,   // "Plasmoid", "StatusNotifier", "BackgroundApp"
        ItemId,                          // Plugin ID or SNI service+path
        CanRender,                       // bool (applet != null)
        Category,                        // "ApplicationStatus", "Hardware", etc.
        Status,                          // Active/Passive/NeedsAttention/Hidden
        EffectiveStatus,                 // Computed: considers config overrides
    };

    // EffectiveStatus logic:
    //  if !canRender → Hidden
    //  if showAllItems || shownItems.contains(id) → Active (forced shown)
    //  if hiddenItems.contains(id) || isDisabledSni(id) → Hidden
    //  if status == Active → Active
    //  if status == Passive && !forced_shown → Passive
};
```

### PlasmoidModel

```
Row data:
  Qt::DisplayRole         → pluginMetaData.name()
  Qt::DecorationRole      → applet ? applet->icon() : pluginMetaData.iconName()
  BaseRole::ItemType      → "Plasmoid"
  BaseRole::ItemId        → pluginMetaData.pluginId()
  BaseRole::CanRender     → applet != nullptr
  BaseRole::Category      → X-Plasma-NotificationAreaCategory
  BaseRole::Status        → applet ? applet->status() : Unknown
  BaseRole::EffectiveStatus → calculateEffectiveStatus(...)
  Role::Applet            → AppletQuickItem for the applet
  Role::HasApplet         → applet != nullptr
```

Lifecycle:
1. PlasmoidRegistry emits `pluginRegistered(KPluginMetaData)`
2. `PlasmoidModel::appendRow(metaData)` → row added with null applet
3. SystemTray creates applet → `PlasmoidModel::addApplet(applet)`
4. Sets applet pointer, connects to statusChanged
5. `PlasmoidModel::removeApplet(applet)` → sets applet to null (doesn't remove row!)
6. `PlasmoidModel::removeRow(pluginId)` → removes row entirely (on uninstall)

### StatusNotifierModel

```
Row data:
  Qt::DisplayRole         → sniData->title()
  Qt::DecorationRole      → sniData->iconName()
  BaseRole::ItemType      → "StatusNotifier"
  BaseRole::ItemId        → sniData->id() (with Dropbox/Chromium workarounds)
  BaseRole::CanRender     → always true
  BaseRole::Category      → sniData->category()
  BaseRole::Status        → extractStatus(sniData->status())
  BaseRole::EffectiveStatus → calculateEffectiveStatus(...)
  Role::DataEngineSource  → source string (service+path)
  Role::AttentionIcon     → sniData->attentionIcon()
  Role::AttentionIconName → sniData->attentionIconName()
  Role::Icon              → sniData->icon()
  Role::IconName          → sniData->iconName()
  Role::Id                → sniData->id()
  Role::ItemIsMenu        → sniData->itemIsMenu()
  Role::Title             → sniData->title()
  Role::ToolTipTitle      → sniData->toolTipTitle()
  Role::ToolTipSubTitle   → sniData->toolTipSubTitle()
  Role::WindowId          → sniData->windowId()
  (and more...)
```

Lifecycle:
1. `StatusNotifierItemHost` (singleton) monitors `org.kde.StatusNotifierWatcher`
2. When `StatusNotifierItemRegistered` signal fires → `StatusNotifierItemHost::itemAdded(service)`
3. → `StatusNotifierModel::addSource(service)` → row appended
4. When `StatusNotifierItemUnregistered` → `StatusNotifierModel::removeSource(service)` → row removed
5. On property changes, SNI source emits `dataUpdated` → model emits `dataChanged`

### BackgroundAppsModel

Used only on Plasma Mobile. Detects flatpak apps running in background via `org.freedesktop.background.Monitor` DBus interface. The `BackgroundAppsFilteredModel` filters out apps that already have a registered SNI (to avoid duplicates).

### SystemTrayModel (QConcatenateTablesProxyModel)

Combines all three models horizontally:
```
[PlasmoidModel rows] + [StatusNotifierModel rows] + [BackgroundAppsFilteredModel rows]
```

Unified roleNames from all three source models.

### SortedSystemTrayModel (QSortFilterProxyModel)

Two sorting modes:
- **SystemTray**: `Hardware` > `SystemServices` > `ApplicationStatus` > `Communications` > `UnknownCategory`, then alphabetical by display name
- **ConfigurationPage**: Same categories but with more refinement, then alphabetical

## QML Architecture

### Main QML Tree

```
main.qml → ContainmentItem
├── KSortFilterProxyModel "activeModel"   # filters effectiveStatus == Active
├── KSortFilterProxyModel "hiddenModel"    # filters effectiveStatus == Passive
├── Instantiator "hiddenInstantiator"      # Creates Connections per hidden item
│   └── onExpandedChanged → systemTrayState.setActiveApplet(applet, row)
├── Instantiator "activeInstantiator"      # Creates Connections per active item
│   └── onExpandedChanged → systemTrayState.setActiveApplet(applet, row)
├── MouseArea (covers everything)
│   ├── SystemTrayState                    # State object
│   ├── CurrentItemHighLight               # Visual highlight overlay
│   ├── DropArea                            # Accept drag-drop of plasmoid
│   ├── GridLayout "mainLayout"
│   │   ├── GridView "tasksGrid"           # Active model items
│   │   │   └── delegate: ItemLoader → loads PlasmoidItem/StatusNotifierItem/BackgroundAppItem
│   │   └── ExpanderArrow                  # Chevron to show/hide popup
│   ├── Timer "expandedSync"               # Sync expanded state to dialog visible
│   └── PlasmaCore.AppletPopup "dialog"    # The main popup window
│       └── ExpandedRepresentation          # Popup content
│           ├── PlasmaExtras.PlasmoidHeading (header)
│           │   ├── Back button
│           │   ├── Title ("Status and Notifications" or applet name)
│           │   ├── Primary action buttons (context actions with HighPriority)
│           │   ├── More actions menu (NormalPriority actions)
│           │   ├── Configure button
│           │   └── Pin button
│           ├── HiddenItemsView             # 2-column grid of passive items
│           │   └── GridView with model: hiddenModel
│           │       └── delegate: ItemLoader → same as tasksGrid
│           └── PlasmoidPopupsContainer     # Active applet's expanded view
│               └── Shows applet.fullRepresentation when active
└── PlasmaExtras.PlasmoidHeading (footer)
```

### AbstractItem (Base Delegate)

All three item types (PlasmoidItem, StatusNotifierItem, BackgroundAppItem) extend AbstractItem.

```qml
PlasmaCore.ToolTipArea {
    property Item iconContainer         # Container for the icon (scales on press)
    property bool inHiddenLayout        # true if in the HiddenItemsView popup grid
    property bool inVisibleLayout       # true if in the panel GridView
    property bool effectivePressed      # Managed by subclasses for scale animation
    
    // Subclass responsibilities:
    // - Bind mainText, subText, textFormat for tooltip
    // - Handle onActivated (key press / input-agnostic activation)
    // - Handle onClicked, onPressed, onWheel
    // - Handle onContextMenu
    
    MouseArea {
        // Click handling delegates to subclass signals
        // In hidden layout: sets current index on position change
        // Press: scales iconContainer to 0.8
    }
    
    RowLayout {
        FocusScope "iconContainer" {
            scale: effectivePressed || containsPress ? 0.8 : 1
            size: inVisibleLayout ? root.itemSize : Kirigami.Units.iconSizes.medium
            // Key handling: Space/Enter → activated, Menu → contextMenu
        }
        Label {
            visible: inHiddenLayout       # Shows text next to icon in popup
            maximumLineCount: 2
        }
    }
}
```

### StatusNotifierItem Delegate

```qml
AbstractItem {
    iconContainer contains: Kirigami.Icon {
        source: status == NeedsAttention ? AttentionIcon : Icon || IconName || ""
    }
    
    onActivated: {
        if ItemIsMenu → openContextMenu (instead of activate)
        else → Plasmoid.activate(service, pos, taskIcon)
    }
    
    onClicked: {
        LeftButton → activated(pos)
        RightButton → contextMenu (proper QMenu with positioning)
        MiddleButton → secondaryActivate
    }
    
    onWheel: {
        scroll(service, delta.y, "vertical")
        scroll(service, delta.x, "horizontal")
    }
}
```

### PlasmoidItem Delegate

```qml
AbstractItem {
    property Item applet: model?.applet ?? null
    
    // The actual Plasma::Applet is parented into iconContainer
    // Its compact representation covers the icon area
    // Its full representation is preloaded into preloadedStorage
    
    onAppletChanged: {
        applet.parent = iconContainer
        applet.anchors.fill = iconContainer
        preloadFullRepresentationItem(applet.fullRepresentationItem)
    }
    
    // Forwards all mouse events to applet's internal MouseArea
    onClicked: findMouseArea(applet.compactRepresentationItem).clicked(mouse)
    onPressed: findMouseArea(applet.compactRepresentationItem).onPressed(mouse)
    onWheel: findMouseArea(applet.compactRepresentationItem).wheel(wheel)
    
    // Context menu uses Plasmoid.showPlasmoidMenu(applet, x, y)
    // Creates real QMenu from applet's contextualActions
}
```

### ItemLoader

Dynamically loads the correct delegate based on item type:

```qml
Loader {
    url: model.itemType === "Plasmoid" → "PlasmoidItem.qml"
         model.itemType === "StatusNotifier" → "StatusNotifierItem.qml"
         model.itemType === "BackgroundApp" → "BackgroundAppItem.qml"
    
    // Passes index, status, effectiveStatus, model as initial properties
}
```

### ExpandedRepresentation

```
Item {
    ┌────────────────────────────────┐
    │ Header Row                     │
    │ [< Back] [Title          ] [★]  │  ← Action buttons, pin, configure
    │                                │
    ├────────────────────────────────┤
    │ HiddenItemsView OR             │
    │ PlasmoidPopupsContainer        │
    │                                │
    │ ┌──────┐ ┌──────┐ ┌──────┐    │
    │ │ Icon │ │ Icon │ │ Icon │    │  ← 2-column grid when in hidden view
    │ │ Name │ │ Name │ │ Name │    │
    │ └──────┘ └──────┘ └──────┘    │
    │                                │
    ├────────────────────────────────┤
    │ Footer (if applet has one)     │
    └────────────────────────────────┘
}
```

## Event Flow: How Icons Appear/Disappear

### Case 1: SNI Icon (e.g., KDE Connect, Telegram, Discord)

```
1. App registers with StatusNotifierWatcher
   → DBus: org.kde.StatusNotifierWatcher.RegisterStatusNotifierItem(service)
   
2. StatusNotifierItemHost (C++ singleton)
   → Receives StatusNotifierItemRegistered signal
   → Emits itemAdded(service)
   
3. StatusNotifierModel
   → addSource(service) called
   → row inserted with default data
   → Queries SNI properties via GetAll
   → On reply: updates row with Icon, Title, Status, etc.
   → dataChanged signal emitted
   
4. SystemTrayModel (concatenating model)
   → Row addition propagates
   
5. SortedSystemTrayModel
   → Re-sorts, new item inserted at correct position
   
6. QML activeModel / hiddenModel (KSortFilterProxyModel)
   → Filters: effectiveStatus == Active → goes to activeModel
   → filters: effectiveStatus == Passive → goes to hiddenModel
   
7. GridView tasksGrid (active items)
   → New delegate created via ItemLoader
   → StatusNotifierItem.qml loaded
   → Icon renders in panel
   
8. HiddenItemsView (passive items)
   → If hidden: new item appears in popup grid
   → ExpanderArrow becomes visible (was 0, now > 0)
```

### Case 2: Plasma Applet (e.g., Networks, Bluetooth, Updates)

```
1. PlasmoidRegistry detects existing applet at startup
   OR
   Plasmashell installs new applet package
   → DBus: /KPackage/Plasma/Applet, signal: packageInstalled(pluginId)
   
2. PlasmoidRegistry::registerPlugin(metaData)
   → PlasmoidModel::appendRow(metaData) — row with null applet
   → If enabled by default: adds to knownItems and extraItems
   
3. PlasmoidRegistry::plasmoidEnabled(pluginId) emitted
   → SystemTray::startApplet(pluginId)
   → Creates Plasma::Applet via PluginLoader::loadApplet()
   → addApplet(applet) — applet added to containment
   
4. SystemTray::appletAdded signal
   → PlasmoidModel::addApplet(applet)
   → Sets applet pointer on existing row
   → dataChanged emitted (now CanRender = true)
   
5. QML: effectiveStatus changes (was Hidden, now computed)
   → If Active: appears in panel GridView
   → If Passive: appears in hidden popup
   
6. Applet stops (DBus service stops)
   → PlasmoidRegistry::plasmoidStopped(pluginId)
   → SystemTray::stopApplet(pluginId)
   → Applet deleted
   → PlasmoidModel::removeApplet(applet) — sets applet to null
   → CanRender becomes false
   → effectiveStatus becomes Hidden
   → Icon disappears from panel
```

## The Containment Key

The critical insight: `SystemTray` is a `Plasma::Containment`, not a regular `Plasma::Applet`. This means:

1. **It can host child applets** — the system tray is wired to create/destroy Plasma applets as plasmoid containers within itself
2. **JSON metadata declares** `"X-Plasma-ContainmentType": "CustomEmbedded"` — this is a special containment type that renders its applets inside its own QML rather than in separate panel positions
3. **System tray plasmoids** have `"X-Plasma-NotificationAreaCategory"` in their metadata (e.g., `"ApplicationStatus"`, `"Hardware"`, `"SystemServices"`) — this is how the PlasmoidRegistry discovers which applets are system tray applets

## QML Plugin Module

The `org.kde.plasma.private.systemtray` QML module exposes:
- `StatusNotifierModel` — the C++ model, available for QML use directly

This plugin is installed at:
```
/usr/lib64/qt6/qml/org/kde/plasma/private/systemtray/libsystemtrayplugin.so
```

It exports `StatusNotifierModel` with `QML_ELEMENT`, making it available in QML without the full Containment.

## Settings Architecture

### KConfig Schema (main.xml)

```xml
extraItems:      StringList  # Enabled plasma applets
disabledStatusNotifiers: StringList  # "Disabled" SNI items
hiddenItems:     StringList  # Force-hidden items
shownItems:      StringList  # Force-shown items
showAllItems:    bool        # Global "show all" toggle
knownItems:      StringList  # Internal: all known applets
reverseIconOrder: bool        # Panel ordering direction
scaleIconsToFit: bool        # Icon sizing mode
iconSpacing:     int         # Spacing multiplier (1/2/6)
pin:             bool        # Keep popup open
```

### SystemTraySettings Class

Wraps `KConfigLoader` with methods:
- `isKnownPlugin()` — has user seen this plugin?
- `addKnownPlugin()` / `removeKnownPlugin()` — manage known list
- `isEnabledPlugin()` — is in extraItems?
- `addEnabledPlugin()` / `removeEnabledPlugin()` — manage extraItems
- `isDisabledStatusNotifier()` — is in disabled list?
- `isShowAllItems()` / `shownItems()` / `hiddenItems()` — visibility config
- `cleanupPlugin()` — removes from all lists (on uninstall)

Emits `enabledPluginsChanged(enabled, disabled)` for SystemTray to start/stop applets.
Emits `configurationChanged()` for BaseModel to recalculate effectiveStatus.

### ConfigGeneral.qml Settings UI

The settings page is extensive (500+ lines):

```
┌─────────────────────────────────────────────┐
│ [Panel icon size: [Small ▼]]               │
│ [Spacing:         [Normal ▼]]              │
│ [Direction:       [Right-to-left ▼]]      │
│                                             │
│ ── Entries ───────────────── [☐ Always show all] [🔍 Search] ── │
│                                             │
│ | Application Status                       │
│ ┌─────────────────────────────────────────┐ │
│ │ [🔊] Volume                     [auto ▼] [Ctrl+Space ✕] [⚙] │
│ ├─────────────────────────────────────────┤ │
│ │ [🌐] Networks                   [auto ▼] [Ctrl+N ✕]    [⚙] │
│ ├─────────────────────────────────────────┤ │
│ │ [📋] Clipboard                  [auto ▼]               [⚙] │
│ ├─────────────────────────────────────────┤ │
│ │ [🔔] Notifications             [auto ▼]               [⚙] │
│ └─────────────────────────────────────────┘ │
│                                             │
│ | Hardware Control                          │
│ ┌─────────────────────────────────────────┐ │
│ │ [🔋] Battery & Brightness       [auto ▼] [Ctrl+B ✕]    [⚙] │
│ ├─────────────────────────────────────────┤ │
│ │ [🖥] Displays                   [auto ▼] [Ctrl+D ✕]    [⚙] │
│ └─────────────────────────────────────────┘ │
│                                             │
│ | Communications                           │
│ ┌─────────────────────────────────────────┐ │
│ │ [📱] KDE Connect                [auto ▼]               [⚙] │
│ └─────────────────────────────────────────┘ │
│                                             │
│ | System Services                           │
│ ┌─────────────────────────────────────────┐ │
│ │ [🔼] Updates                    [auto ▼]               [⚙] │
│ └─────────────────────────────────────────┘ │
│                                             │
│ | Miscellaneous                            │
│ ┌─────────────────────────────────────────┐ │
│ │ [💬] Signal                     [auto ▼]               [⚙] │
│ ├─────────────────────────────────────────┤ │
│ │ [🟢] Discord                    [auto ▼]               [⚙] │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

Per-item controls:
1. **Visibility combo**: auto / shown / hidden / disabled
2. **Keyboard shortcut**: KeySequenceItem for global shortcut
3. **Configure button**: Opens applet's settings dialog

Section headers organize items by category (ApplicationStatus, Hardware, Communications, SystemServices, Miscellaneous).

Warning messages for disabling critical items:
- Clipboard: warns about losing clipboard data
- Notifications: warns about missing notifications
- SNI items (non-plasmoid): warns about unexpected behavior
