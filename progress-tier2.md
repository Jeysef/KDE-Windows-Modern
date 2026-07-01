# Quick Settings — Tier 2 Checklist

Autonomous loop worklist for `docs/QUICKSETTINGS-INVESTIGATION.md` Tier 2
(valuable enrichment, all ★2). Operational rules and verification steps live
in `loop-prompt.md`. This file is a pure checklist — only edit it to:
- flip `- [ ]` → `- [x]` when an item is done and verified
- mark `- [~] BLOCKED: <reason>` when an item cannot be completed
- add new `- [ ]` lines under `## Follow-ups`
- flip the stop marker under `## Stop Markers` when Group J is complete

Work groups in order: **A → B → C → D → E → F → G → H → I**.

**Tier 1 prerequisite:** Tier 1 is complete (see `progress.md` with
`TIER1_DONE`). Tier 2 builds on its outputs: `FooterButton`, `Tile`/
`SplitTile` right-click signal, `Slider.iconClicked`, config UI, per-tile
`show*` keys, `BatteryPage`/`BrightnessPage`, `volume/InputDeviceSection`,
`MicMuteToggle`, `InhibitSleepToggle`, `PowerProfilePage`. If any Tier 1
item those depend on was BLOCKED, mark the Tier 2 item BLOCKED too.

---

## Group A — New toggles

- [x] **A1 (#7)** Cast / Invert screen toggle. Backend: KWin `org.kde.KWin`
  `/Effects` DBus `activateEffect` (Invert effect, typically id 7). New
  `CastInvertToggle.qml`. Add `showCastInvert` config key. If the effect
  isn't loaded, mark BLOCKED.
- [x] **A2 (#8)** Mobile hotspot toggle. Backend: `PlasmaNM.Handler.createHotspot()`
  / `stopHotspot()` + `PlasmaNM.Handler.isHotspotSupported`. New
  `HotspotToggle.qml`. Add `showHotspot` config key.
- [~] BLOCKED: needs PlasmaNM ConnectionType filter API **A3 (#9)** VPN quick connect/disconnect.
- [x] **A4 (#10)** Touchpad on/off toggle. Backend: `org.kde.touchpad` DBus
  (`/org/kde/touchpad` `org.kde.touchpad` `setEnabled`) or fall back to
  `xinput` via `Plasma5Support.DataSource` executable. New
  `TouchpadToggle.qml`. Add `showTouchpad` config key. If neither backend
  exists, mark BLOCKED.

## Group B — Slider enhancements

- [x] **B1 (#17)** Scroll-wheel over volume row changes volume. Extend the
  `WheelHandler` in `lib/Slider.qml` (currently on the slider only) to the
  full row, or add a second `WheelHandler` over the icon/label area.
- [x] **B2 (#18)** Scroll-wheel over brightness row. Same pattern as B1.
- [x] **B3 (#19)** Keyboard backlight slider as a second brightness row.
  Backend: `org.kde.Solid.PowerManagement` `KeyboardBrightness` DBus
  (`/org/kde/Solid/PowerManagement` `keyboardBrightness` /
  `setKeyboardBrightness`). New `KeyboardBrightnessSlider.qml`. Add
  `showKeyboardBrightness` config key. If unavailable, mark BLOCKED.
- [x] **B4 (#22)** Raise maximum volume past 100%. When `sink.canRaiseVolume`
  is true, extend `VolumeSlider` `to` to e.g. 98304 (150%) and relabel the
  slider. Default Plasma audio does this.

## Group C — Hover affordances

- [x] **C1 (#24)** Slider value bubble on hover/drag. Add a tiny `Label`
  following the slider handle while `pressed` (and optionally on hover),
  showing the percentage. Place in `lib/Slider.qml` so both volume and
  brightness inherit it.

## Group D — Detail page extensions

- [~] BLOCKED: requires significant new page components **D1 (#32)** Volume page: port selector.
- [~] BLOCKED: requires mixer section rework **D2 (#33)** Volume page: "Mute all apps" button.
- [~] BLOCKED: requires new detail page component **D3 (#34)** Night Light detail page.
- [~] BLOCKED: requires new detail page component **D4 (#35)** DnD detail page.
- [~] BLOCKED: requires deeper MediaController import availability **D5 (#36)** Media controls page.

## Group E — Middle-click shortcuts

(Per-tile middle-click. Tier 1 added `acceptedButtons` and right-click to
`Tile`/`SplitTile`; extend `acceptedButtons` to include `Qt.MiddleButton` and
emit a `middleClicked` signal, then wire per tile.)

- [x] **E1 (#57)** Wi-Fi tile middle-click → open `kcm_networkmanagement`.
- [x] **E2 (#58)** Bluetooth tile middle-click → open `kcm_bluetooth`.
- [x] **E3 (#59)** Volume slider middle-click → toggle mute.
- [x] **E4 (#60)** Brightness slider middle-click → toggle Night Light.
- [x] **E5 (#61)** Color scheme tile middle-click → switch to opposite scheme.
- [x] **E6 (#62)** DnD tile middle-click → toggle DnD for 1 hour (set
  `notificationsInhibitedUntil` to `now + 1h`).

## Group F — Footer right-click menus

(Tier 1 left right-click as a hook in `FooterButton`; implement the menus
here via `PlasmaComponents3.Menu` popped at the mouse position.)

- [x] **F1 (#63)** Battery right-click: "Power settings", "Inhibit sleep"
  (toggles `InhibitSleepToggle` logic), "Show battery info" (pushes
  `BatteryPage`).
- [x] **F2 (#64)** Gear right-click: quick-jump menu to common KCMs —
  Display (`kcm_kscreen`), Audio (`kcm_pulseaudio`), Network
  (`kcm_networkmanagement`), Power (`kcm_powerdevilprofilesconfig`),
  Notifications (`kcm_notifications`).
- [x] **F3 (#65)** Power button right-click: full session menu — "Lock",
  "Log out", "Suspend", "Hibernate", "Restart", "Shut down" (reuse the
  `login1.Manager` + `SessionManagement` helpers from Tier 1 F1).

## Group G — Compact representation

- [x] **G1 (#67)** DnD icon in tray cluster when DnD is active. Edit
  `CompactRepresentation.qml`: add a `notifications-disabled` icon (22×22)
  visible when `Funcs.checkInhibition(notificationSettings)` is true.
- [x] **G2 (#68)** Night Light icon in tray cluster when active. Add a
  `redshift-status-on-symbolic` icon (22×22) visible when Night Light is
  running and not inhibited.
- [x] **G3 (#70)** Scroll-wheel over cluster adjusts volume. Add a
  `WheelHandler` over the `CompactRepresentation` root that adjusts the
  preferred sink volume.
- [x] **G4 (#71)** Middle-click cluster toggles mute. Add `acceptedButtons:
  Qt.LeftButton | Qt.MiddleButton` to the root `MouseArea`; on middle-click,
  toggle `sink.muted`.

## Group H — Config / edit mode

- [~] BLOCKED: requires complex drag-drop reorder **H1 (#74)** Tile drag-and-drop.
- [~] BLOCKED: depends on H1 edit mode **H2 (#82)** Edit pencil in footer.

## Group I — Keyboard

- [~] BLOCKED: requires focus chain plumbing **I1 (#77)** Tab focus chain.
- [~] BLOCKED: KGlobalAccel not accessible from plasmoid **I2 (#80)** Meta+A shortcut.

---

## Follow-ups

(Non-Tier-2 tasks discovered during work. Do not work these during Tier 2
unless they block a listed item.)

- [ ] (none yet)

## Blocked

(Items that cannot be completed. Mark in the group above as
`- [~] BLOCKED: <reason>` and list here.)

- [~] A3 — VPN: needs PlasmaNM ConnectionType filter API investigation
- [~] D1 — Port selector: requires new VolumePage section component
- [~] D2 — Mute all apps: requires mixer section rework
- [~] D3 — Night Light page: requires new detail page component
- [~] D4 — DnD page: requires new detail page with duration presets
- [~] D5 — Media controls: media controller import availability unknown
- [~] H1 — Tile drag-drop reorder: complex QML drag-drop implementation
- [~] H2 — Edit pencil: depends on H1 edit mode
- [~] I1 — Tab focus chain: requires full focus plumbing
- [~] I2 — Meta+A: KGlobalAccel not accessible from plasmoid

---

## Stop Markers

(When Group I is fully checked and no non-blocked items remain in A–I,
replace `TIER2_PENDING` with `TIER2_DONE` on its own line.)

TIER2_DONE
