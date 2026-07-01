# System Tray Gap Analysis & Migration Plan

## Current State

The Windows Modern system tray (`org.kde.windowsmodern.systemtray`) is a **from-scratch rewrite** that does not leverage any of Plasma's built-in system tray infrastructure. It works by:

1. Manually polling `org.kde.StatusNotifierWatcher` every 5 seconds for SNI items
2. Building a custom `ListModel` from DBus query results
3. Rendering hidden SNI icons in a `GridView`
4. Hardcoding icons for media, clipboard, devices, notifications, battery

## What's Missing (Ordered by Impact)

### Critical

1. **Plasma Applet Containment** — The core feature. Without this, the following applets never appear in the Windows Modern tray:
   - Networks (Wi-Fi list, known networks, airplane mode)
   - Bluetooth (device list, pairing)
   - KDE Connect (phone notifications, file transfer)
   - Updates (Discover update notifications)
   - Volume/Audio (audio output switching)
   - Battery & Brightness (status + controls)
   - Clipboard (Klipper management)
   - Notifications (notification history + DND)
   - Printers, Displays, Device Notifier, Keyboard Layout, etc.

2. **Event-driven Data Model** — Current polling means:
   - 5-second delay before new icons appear
   - Unnecessary DBus traffic (GetAll on every item every cycle)
   - Misses rapidly appearing/disappearing items
   - No attention/animation status support

3. **Per-Item Configuration** — The Plasma generic tray has full per-item:
   - Visibility control (auto/shown/hidden/disabled)
   - Keyboard shortcut assignment
   - Configure button (opens applet settings)
   - The Windows Modern tray has none of this

### High

4. **Proper SNI Context Menus** — Current implementation just fires a DBus call with no visual feedback. The generic tray creates real QMenus:
   - Right-click → actual menu dropdown
   - Proper positioning relative to icon
   - Wayland xdg_popup support

5. **Pin Popup** — Keep the popup open while interacting with other windows
6. **Settings Richness** — 3 settings vs 9 (missing: showAll, shownItems, hiddenItems, extraItems, disabledSNIs, reverseOrder, scaleToFit, iconSpacing modes, pin)

### Medium

7. **Icon Scaling Modes** — Fixed size vs auto-scale to panel thickness
8. **Reverse Icon Order** — Configure icon flow direction
9. **Attention Animations** — Pulse effect when apps need attention
10. **Drag-and-Drop** — Add applets to system tray by dragging

### Low

11. **Background Apps** — Flatpak background app monitoring (mobile-focused)
12. **CurrentItemHighlight** — Visual indicator for active/focused item

## What Windows Modern Has That Plasma Doesn't

These are features that should be preserved after migration:

1. **Windows 11 Visual Style** — The entire point of the project
   - Hover effects (semi-transparent white overlays, 100ms animation)
   - Press effects (ColorAnimation with Qt.rgba)
   - Rounded corners (radius: 4)
   - Pointing hand cursor
   - Compact, clean layout

2. **Integrated Extra Pages** (built into the popup):
   - Media player page with album art, controls
   - Clipboard history page (Klipper integration)
   - Devices page with mount/unmount/open
   - Notifications page with clear-all
   - Battery page with power controls

3. **Lightweight Architecture** — No C++ compilation needed, pure QML

## Migration Plan

### Phase 1: Fork & Get Working (Preserve ALL Plasma Functionality)

**Goal**: A working copy of the generic system tray under the Windows Modern brand, with zero style changes.

1. Clone `plasma-workspace/applets/systemtray/` into the project
2. Rename metadata:
   - `Id` → `org.kde.windowsmodern.systemtray`
   - `Name` → `System Tray (Windows Modern)`
   - `Icon` → `preferences-system-windows`
3. Update CMakeLists.txt to build as standalone applet
4. Test: Does it compile? Does it work when installed?
5. Verify all features work:
   - Applets appear/disappear automatically
   - Popups work with proper context menus
   - Settings page shows all items
   - Keyboard shortcuts work

**Deliverable**: Working system tray with full Plasma feature parity

### Phase 2: Windows 11 Theming

**Goal**: Apply Windows 11 visual style to the Plasma system tray QML files.

Files to modify:
1. `qml/AbstractItem.qml` — Dark hover/press effects, rounded corners
2. `qml/StatusNotifierItem.qml` — Custom icon rendering
3. `qml/PlasmoidItem.qml` — Custom applet wrapper styling
4. `qml/CompactApplet.qml` — Panel button styling
5. `qml/ExpanderArrow.qml` — Chevron styling
6. `qml/ExpandedRepresentation.qml` — Popup window styling
7. `qml/HiddenItemsView.qml` — Grid styling
8. `qml/ConfigGeneral.qml` — Settings page styling
9. `qml/main.qml` — Overall layout refinements

Key style constants (from Windows Modern):
```qml
// Hover effect
color: containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
// Press effect
color: containsPress ? Qt.rgba(1, 1, 1, 0.12) : (containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
// Animation
Behavior on color { ColorAnimation { duration: 100 } }
// Corners
radius: 4
// Cursor
cursorShape: Qt.PointingHandCursor
```

**Deliverable**: Windows 11-styled system tray with full Plasma feature parity

### Phase 3: Integrate Windows Modern Extra Pages

**Goal**: Add the media player, clipboard, devices, notifications, and battery pages.

Options:

**Option A: As Embedded Pages (like current Windows Modern)**
- Add pages to `ExpandedRepresentation.qml`'s content area
- Toggle between hidden items view and extra pages
- Requires adding toggle buttons in the panel area or popup header

**Option B: As Standalone Plasmoid Applets**
- Convert each page into a proper Plasma applet
- Register them for the system tray via `X-Plasma-NotificationAreaCategory`
- They appear as regular system tray icons with their own popups
- This is the "Plasma way" and more maintainable

**Option C: Hybrid**
- Media player, clipboard, devices, notifications: standalone applets
- Battery: keep as system tray integrated (since it already is in Plasma)
- Add a "quick actions" row in the popup for common operations

**Recommended: Option B** — Clean architecture, leverages the containment model, users can disable individual components.

For each extra page, create a plasmoid:
```
plasma/applets/
  org.kde.windowsmodern.clipboard/     # Clipboard history
  org.kde.windowsmodern.devices/       # Removable devices
  org.kde.windowsmodern.notifications/ # Notification history
  org.kde.windowsmodern.mediaplayer/   # Media player
```

Each with `X-Plasma-NotificationAreaCategory: ApplicationStatus` in metadata.

### Phase 4: Polish & Extras

- Add Windows 11-specific animations (if desired)
- Ensure dark/light theme switching works
- Test with various applet configurations
- Add Windows 11-style notification badges
- Fine-tune spacing, sizing, icon rendering

## Technical Challenges

### Challenge 1: C++ Build System

The Plasma system tray requires C++ compilation (QML plugin + applet shared object). This means:
- Need CMake build file
- Need KDE development libraries (`plasma-framework-devel`, `plasma-workspace-devel`)
- Cannot be a pure QML plasmoid like current Windows Modern

**Mitigation**: Consider if the `org.kde.plasma.private.systemtray` QML plugin (already installed) can be reused. If the installed `StatusNotifierModel` can be accessed from QML in a pure-QML applet, we may not need to compile the full containment.

### Challenge 2: Containment vs Applet

The Windows Modern tray is currently a `PlasmoidItem`. To support containment, it must be a `ContainmentItem` (or use C++ `Plasma::Containment`). QML `ContainmentItem` support in Plasma 6 needs verification.

### Challenge 3: Integration with Windows Modern Theme

The system tray's appearance significantly changes the overall feel. The panel's right side needs to look cohesive with the rest of the Windows Modern theme (start menu, quick settings, etc.).

### Challenge 4: The Windows Modern "Extras" Pages

The current Windows Modern tray has 5 extra pages built in (media, clipboard, devices, notifications, battery). The Plasma system tray handles these differently:
- Battery is a separate plasmoid
- Clipboard is a separate plasmoid (Klipper)
- Notifications is a separate plasmoid
- Media player is a separate plasmoid
- Devices is a separate plasmoid (Device Notifier)

Keeping them integrated vs making them standalone plasmoids is a design decision.

## Quick Wins (Do These First)

These can be done to the current Windows Modern tray immediately:

1. **Replace Polling with Event-Driven SNI Model**
   ```qml
   // Instead of Timer polling, use the installed StatusNotifierModel:
   import org.kde.plasma.private.systemtray as SystemTrayPrivate
   
   SystemTrayPrivate.StatusNotifierModel {
       id: sniModel
   }
   ```
   This eliminates the 5-second delay and polling overhead. The QML plugin is already installed on the system.

2. **Add Real Context Menus**
   Use `PlasmaCore.AppletPopup` or QMenu DBus calls for proper right-click menus on SNI items.

3. **Expand Configuration**
   Add more settings to `main.xml` and `ConfigGeneral.qml` — even simple toggles for icon visibility would help.

## Success Metrics

After Phase 2 completion:
- [ ] All Plasma system tray plasmoids appear/disappear automatically
- [ ] Per-item visibility configuration works
- [ ] Per-item keyboard shortcuts work
- [ ] Context menus appear correctly
- [ ] Popup can be pinned
- [ ] Icons scale with panel
- [ ] Panel icon ordering is configurable
- [ ] Attention animations work
- [ ] Windows 11 visual style applied
- [ ] Settings page shows all items with Windows 11 styling

After Phase 3 completion:
- [ ] Media player page works
- [ ] Clipboard history page works
- [ ] Devices page works
- [ ] Notifications page works
- [ ] Battery page works
