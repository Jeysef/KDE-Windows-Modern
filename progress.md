# Quick Settings — Tier 1 Checklist

Autonomous loop worklist for `docs/QUICKSETTINGS-INVESTIGATION.md`.
Operational rules and verification steps live in `loop-prompt.md`.
This file is a pure checklist — only edit it to:
- flip `- [ ]` → `- [x]` when an item is done and verified
- mark `- [~] BLOCKED: <reason>` when an item cannot be completed
- add new `- [ ]` lines under `## Follow-ups`
- flip the stop marker under `## Stop Markers` when Group J is complete

Work groups in order: **A → B → C → D → E → F → G → H → I → J**.

---

## Group A — Wire in dead code

- [x] **A1 (#1)** Add `ColorSchemeToggle` to `MainPage.qml` grid. File exists and is complete (`plasma-apply-colorscheme` via `Plasma5Support.DataSource`). Add `showColorScheme` config key (default true) in `contents/config/main.xml`, gate visibility.
- [x] **A2 (#2)** Add `DndToggle` to `MainPage.qml` grid. File exists (`NotificationManager.Settings` + `Funcs.toggleDnd`). Add `showDnd` config key (default true), gate visibility.
- [x] **A3 (#3)** Add `PowerButton` to `Footer.qml` left of the settings gear. File exists (`SessionManagement.requestLogoutPrompt()`).

## Group B — Missing toggles

- [x] **B1 (#5)** Power profile 3-way (Performance / Balanced / Power-saver). Backend: `PowerProfilesControl` (already imported in `BatterySaverToggle.qml`) — `profiles` + `setProfile()`. New `PowerProfilePage` detail page (3 `ListRow`s). Replace or augment `BatterySaverToggle`.
- [x] **B2 (#6)** Inhibit-sleep toggle. **Reuse logic from `org.kde.windowsmodern.systemtray/contents/ui/BatteryPage.qml`** (`_toggleBlockSleep`, `_checkInhibitor`, `_blockerName` via `systemd-inhibit` + `Plasma5Support.DataSource`). New `InhibitSleepToggle.qml`. Add `showInhibitSleep` config key.
- [x] **B3 (#14)** Microphone mute toggle. Backend: `Vol.SourceModel` + `Vol.PulseObjectFilterModel`, preferred source `Muted`. New `MicMuteToggle.qml` (icon `microphone-sensitivity-*` / `audio-input-microphone-muted`). Add `showMicMute` config key.

## Group C — Slider interactions

- [x] **C1 (#15)** Click volume icon → mute/unmute. Add `iconClicked` signal + `MouseArea` over the icon in `lib/Slider.qml` (lines 28–35). Connect in `VolumeSlider.qml` → `sink.muted = !sink.muted`.
- [x] **C2 (#16)** Click brightness icon → toggle Night Light. Connect `iconClicked` (from C1) in `BrightnessSlider.qml` → `NightLightInhibitor.toggleInhibition()`. Import NightLight DBus bits from `NightLightToggle.qml`.
- [x] **C3 (#20)** Per-display brightness. `BrightnessSlider.refreshDisplays()` does `model.index(0,0)` — iterate `sbControl.displays.rowCount()` and render one slider per display (label as subtext). Single-display behavior unchanged.

## Group D — Tooltips

- [x] **D1 (#23)** Tile tooltips. Wrap `Tile`/`SplitTile` `Rectangle` in `PlasmaCore.ToolTipArea`. Expose `tooltipText` from each toggle: Wi-Fi → "Wi-Fi — Connected to <SSID>" / "Wi-Fi — Off"; Bluetooth → "Bluetooth — <N> connected" / "On, not connected"; etc.
- [x] **D2 (#25)** Footer battery rich tooltip: "76% — 3h 12m remaining" / "Charging — 76%" via `BatteryControlModel` `remainingTime`/`state`. (Coordinate with J2 where battery becomes a FooterButton.)
- [x] **D3 (#26)** Footer gear tooltip: "Open System Settings".
- [x] **D4 (#27)** Power button tooltip: "Power off / Log out".

## Group E — Detail pages

- [x] **E1 (#29)** Battery / Power detail page. **Lift design from sibling `BatteryPage.qml`**: big % + icon, progress bar, time remaining, health (`upower -i`), power profile 3-way (depends B1), inhibit-sleep switch (depends B2), "Power settings" → `kcm_powerdevilprofilesconfig`. New `components/BatteryPage.qml`. Register in `QuickSettings.qml` `pageMap`.
- [x] **E2 (#30)** Brightness / Display detail page. Per-monitor sliders (depends C3), night light toggle, "Night color settings" → `kcm_nightcolor`, "Display configuration" → `kcm_kscreen`. New `components/BrightnessPage.qml`. Add chevron to brightness slider that pushes this page.
- [x] **E3 (#31)** Volume page: Input/Microphone section. New `components/volume/InputDeviceSection.qml` (mirror `OutputDeviceSection.qml`). Backend: `Vol.SourceModel` + `Vol.PulseObjectFilterModel`. Preferred source volume + mute + device selector.
- [x] **E4 (#37)** Bluetooth page: "Add device" button in `BluetoothPage.qml`. Launch `bluedevil-wizard` (via `Qt.openUrlExternally` or `Plasma5Support` executable).

## Group F — Right-click / context menus

- [x] **F1 (#42–#47)** Plasmoid contextual menu. **Copy pattern from sibling `main.qml`**: `PlasmaCore.Action` array in `main.qml`, rebuild in `onContextualActionsAboutToShow`, trigger via index. Entries: "Configure Quick Settings…" (opens H1 page), "Open System Settings", "Lock screen" (`org.freedesktop.ScreenSaver.Lock`), "Suspend"/"Hibernate"/"Log out"/"Restart"/"Shut down" (`login1.Manager` + `SessionManagement` — see sibling `_suspend`/`_hibernate`), "Do Not Disturb" (`Funcs.toggleDnd`).
- [x] **F2 (#48)** Wi-Fi tile right-click. Add `acceptedButtons: Qt.LeftButton | Qt.RightButton` to `SplitTile` toggle `MouseArea`, emit `rightClicked`. In `NetworkToggle` pop `PlasmaComponents3.Menu`: "Open Wi-Fi settings", "Create hotspot…", "Connect to hidden network…", "Known networks…".
- [x] **F3 (#49)** Bluetooth tile right-click. Menu: "Add new device…", "Send file…", "Bluetooth settings" (`bluedevil-wizard` / `bluedevil-sendfile`).
- [x] **F4 (#50)** Volume slider right-click. Menu: "Mute/unmute", "Test sound" (`Vol.VolumeFeedback.play`), "Audio settings".
- [ ] **F5 (stretch, #51–#55)** Right-click for Brightness / Power / Night Light / Color scheme / DnD tiles. Only if F2–F4 pattern generalizes cleanly into `Tile`/`SplitTile`. Otherwise defer to Tier 2.

## Group G — Compact representation

- [x] **G1 (#66)** Bluetooth icon in tray cluster. Edit `CompactRepresentation.qml`: add `BluezQt.Manager`-backed icon (22×22) visible when `btManager.bluetoothOperational`.
- [x] **G2 (#69)** Rich cluster tooltip. Replace bare "Quick Settings" with state summary: "Wi-Fi: <SSID> · BT: <state> · <N>% battery" (+ "· DnD on" / "· Night Light on" when active).

## Group H — Config UI

- [x] **H1 (#72)** Config UI. Create `contents/ui/config/main.qml` + `contents/ui/ConfigGeneral.qml` (mirror sibling tray `ConfigGeneral.qml`). Expose: spinbox `scale` (80–150), checkbox per `show*` key, two text fields `darkTheme`/`lightTheme`.
- [x] **H2 (#73)** Per-tile visibility config. Verify every toggle (incl. Groups A/B) has a `show*` key (default true) and `MainPage.qml` gates `visible` on it. Verify H1 exposes all.

## Group I — Keyboard & accessibility

- [x] **I1 (#76)** Esc pops detail page. `Keys.onEscapePressed` on `StackView` in `QuickSettings.qml` → `pageStack.pop()` when `depth > 1`. Ensure flyout has focus when shown.
- [x] **I2 (#79)** Enter/Space toggles focused tile. `focus: true` + `activeFocusOnTab: true` on tiles; `Keys.onReturnPressed`/`Keys.onSpacePressed` → `tile.clicked()` in `Tile.qml`/`SplitTile.qml`.

## Group J — Footer as action row

- [x] **J1 (#81)** Extract `lib/FooterButton.qml` (icon + tooltip + click + right-click hook). Refactor `Footer.qml` to use it for gear and power button. (Per-button right-click menu is Tier 2 — leave hook only.)
- [x] **J2 (#4 + #83)** Battery as `FooterButton` opening Battery detail page (depends E1). Push `pageMap["battery"]` on click. Add rich tooltip from D2. Verify `BatteryPage` registered in `pageMap`.

---

## Follow-ups

(Non-Tier-1 tasks discovered during work. Do not work these during Tier 1 unless they block a listed item.)

- [ ] Layout constraint: with current 400px flyout height, max 9 toggle tiles (3 rows) before sliders get pushed off-screen. Adding more tiles requires either increasing flyout height or making it scrollable.
- [ ] (none yet)

## Blocked

(Items that cannot be completed. Mark in the group above as `- [~] BLOCKED: <reason>` and list here.)

- (none yet)

---

## Stop Markers

(When Group J is fully checked and no non-blocked items remain in A–J, replace `TIER1_PENDING` with `TIER1_DONE` on its own line.)

TIER1_DONE
