# Windows Modern — Style Specification

This document describes the visual style, color palette, and layout
decisions for the Windows Modern KDE Plasma theme. It serves as a
reference for maintaining consistency across all components.

---

## Design Philosophy

The theme targets an authentic **Windows 11** look on KDE Plasma 6.
Two variants are provided:

- **Dark** (`Windows-modern-dark`) — Win11 dark mode
- **Light** (`Windows-modern-light`) — Win11 light mode

Each variant ships matching assets for the plasma desktop theme,
aurorae window decoration, Kvantum Qt style, color scheme, and
look-and-feel package.

---

## Color Palette

### Dark variant

| Token | Hex | Usage |
|---|---|---|
| Window/panel background | `#202020` | Aurorae window decoration bg |
| Panel background (opaque) | `#1C1C1C` | Taskbar / panel fill when solid |
| Acrylic/popup background | `#2C2C2C` | Tooltips, flyouts, applet popups |
| Surface border (active) | `#3F3F3F` | Window borders, popup borders |
| Surface border (inactive) | `#2A2A2A` | Inactive window borders |
| Text (primary) | `#FFFFFF` | Title bar text, popup text, icons |
| Text (inactive) | `30,30,30 @ 50%` | Inactive title bar text |
| Highlight/accent | `#4CC2FF` | Focus indicators, links (Win11 SystemAccentColorLight2 — lighter shade for dark mode) |
| Button hover bg | `#3F3F3F` | Hover states |
| Button bg | `#2C2C2C` | Button backgrounds |
| Close hover | `#C42B1C` | Close button hover (Win11 red) |
| Close pressed | `#9E1B1B` | Close button pressed (Win11 dark red) |

### Light variant

| Token | Hex | Usage |
|---|---|---|
| Window/panel background | `#F9F9F9` | Aurorae window decoration bg |
| Acrylic/popup background | `#F9F9F9` | Tooltips, flyouts, applet popups |
| View background | `#FFFFFF` | List views, input fields |
| Surface border (active) | `#E5E5E5` | Window borders, popup borders |
| Surface border (inactive) | `#D5D5D5` | Inactive window borders |
| Text (primary) | `#1E1E1E` | Title bar text, popup text, icons |
| Text (inactive) | `153,153,153` | Inactive title bar text |
| Highlight/accent | `#0067C0` | Focus indicators, links (Win11 SystemAccentColorDark1 — darker shade for light mode) |
| Button hover bg | `#E9E9E9` | Hover states |
| Button bg | `#F3F3F3` | Button backgrounds |
| Close hover | `#C42B1C` | Close button hover (Win11 red) |
| Close pressed | `#9E1B1B` | Close button pressed (Win11 dark red) |

> Color values are sourced from the WinUI 3 (microsoft-ui-xaml)
> theme resource dictionaries.

---

## Components

### Plasma Desktop Theme

Location: `plasma/desktoptheme/Windows-modern-{dark,light}/`

Based on the Win11OS-dark plasma theme by yeyushengfan258, with all
`.svgz` files expanded to `.svg` and the following modifications:

#### Panel background (`widgets/panel-background.svg`)

- **Dark fill `#1C1C1C`** when opaque (Win11 taskbar color); dialog
  and popup backgrounds (`background.svg`) remain `#2C2C2C`.
- **No shadow** — all `shadow-*` elements set to `opacity:0`,
  `shadow-hint-*-margin` rects zeroed (width/height = 0).
- **48px panel height** supported (Win11 taskbar height) — the SVG
  hint margins scale cleanly to the taller panel; the original
  30px is also still usable.
- Three variants maintained: `widgets/`, `solid/widgets/`,
  `translucent/widgets/`.
- Light variant uses reduced border opacity (0.08 vs 0.3) for
  visibility on light backgrounds.

#### Panel layout template (`plasma/layout-templates/org.kde.windowsmodern.panel/`)

A Plasma 6 layout-template package that builds a Win11-style taskbar
when selected from **Add Panels** in the desktop context menu, or
applied via `kpackagetool6`. Installed to
`~/.local/share/plasma/layout-templates/` (or `/usr/share/` as root)
by `install.sh`.

The `contents/layout.js` creates:

- Bottom panel, 48px tall (resizable after adding; 30-32px also works
  well), `alignment=center`, `lengthMode=fill`, no auto-hide.
- Panel docked to screen edge (`floating=false`). "Applets Only"
  floating (applets inset, panel docked) cannot be set from a layout
  script — the `floatingApplets` PanelView property is not exposed in
  the Plasma scripting API, and writing it via `ConfigFile` doesn't
  work because plasmashell holds config in memory. Users must toggle
  "Floating → Applets Only" manually in Panel Settings after adding.
- Opaque background (`panel.opacity="opaque"`) — no adaptive
  translucency toggling when windows touch the panel.
- Widgets left→right:
  1. **Left expanding spacer** — `org.kde.plasma.panelspacer`. Pushes
     the Start + tasks group to the horizontal center of the panel,
     matching Win11's centered taskbar.
  2. **Start** — `org.kde.windowsmodern.startmenu` (falls back to
     `org.kde.plasma.kickoff`; icon `start-here`). A custom Windows-logo
     icon is provided, with both a scalable version and a fixed
     `48/apps/start-here.svg` that draws the logo at 30px so it matches
     the app-icon size on a 48px panel.
  3. **Icon-only task manager** — `org.kde.plasma.icontasks` (grouped
     by app, sits immediately to the right of Start in the centered
     group)
  4. **Right expanding spacer** — `org.kde.plasma.panelspacer`. Separates
     the centered Start + tasks group from the system tray on the far
     right.
  5. **System tray** — `org.kde.windowsmodern.systemtray`. The overflow
     chevron (`^`) sits *right* of the tray icons, next to the clock (a
     deliberate choice; Windows 11 puts it on the left).
     The tray always ends with input language, network, volume, battery,
     in that order, as on Windows 11 (`s_windowsTail` in
     `windowstray.h`; checked by `tests/panel/e2e.py tray-order`). Only
     those four, notifications and the camera-in-use indicator show without
     being pinned; every other icon waits behind the chevron until it needs
     attention or is set to "Always shown" (`calculateEffectiveStatus` in
     `systemtraymodel.cpp`).
  6. **Digital clock** — `org.kde.windowsmodern.digitalclock` (with a
      fallback to `org.kde.plasma.digitalclock`). Stacked date below the
      time, no seconds by default, `use24hFormat=1` so it follows the
      user's locale. Time and date use the same, normal UI font size, as on
      Windows; the text shrinks only if the panel is too thin for it. The expanded popup is a dark rounded
      Windows 11 calendar with month navigation, current-day blue circle,
      hover highlights, and optional KDE calendar event dots.
  7. **Show Desktop** — `org.kde.windowsmodern.showdesktop`, a custom
      forked applet (see below). Renders as a 6px-wide bare sliver with
      no icon. Click minimizes all windows; click again restores.

The template does not replace an existing panel automatically; users add it
via right-click desktop → Add Panels → "Windows Modern Panel".

In addition, each look-and-feel package ships the same layout as
`contents/layouts/org.kde.plasma.desktop-layout.js` (the file name
Plasma 6 expects for the default `org.kde.plasma.desktop` shell). When a
user applies the global theme in System Settings → Appearance → Global
Theme and chooses to use the desktop layout from the theme, Plasma
removes any existing panels and creates the Windows Modern Panel
automatically.

#### Show Desktop applet (`plasma/applets/org.kde.windowsmodern.showdesktop/`)

A simplified fork of [Zren's plasma-applet-win7showdesktop](https://github.com/Zren/plasma-applet-win7showdesktop)
(which itself forks KDE's `org.kde.plasma.showdesktop`). Stripped to
the essentials for the Win11 look:

- **Thin sliver** — `Layout.maximumWidth` is driven by the `size`
  config key (default 6px), overriding the upstream 22px floor.
- **No icon** — the `Kirigami.Icon` is only visible in edit mode.
- **Show desktop** — `ShowDesktopController` toggles KWin's show-desktop
  mode (`KWindowSystem.showingDesktop`), the same state as Win+D: click to
  show the desktop, click again to restore the windows.
- **Win11 hover indicator** — invisible by default. On hover, a 1px
  vertical line (50% of panel height, centered) fades in at 50% text
  color alpha. No background fill, no separator line — matches Win11
  exactly.
- **No active indicator** — no overlay when windows are minimized.

Removed from the upstream fork: command controller, mousewheel volume,
peek-on-hover, openSUSE qdbus detection, `Plasma5Support.DataSource`.

Config keys (`contents/config/main.xml`): `size` (int, default 6),
`edgeColor` (string, empty = theme text color @ 50% alpha for the hover
line). Installed to `~/.local/share/plasma/plasmoids/` (or
`/usr/share/plasma/plasmoids/` as root) by `install.sh`.

#### Start Menu applet (`plasma/applets/org.kde.windowsmodern.startmenu/`)

A Win11-style start menu ported from the reference plasmoid
`com.jeysef.windowsmodernstartmenu`. The monolithic 3307-line
`MenuRepresentation.qml` is split into a clean shell (`MenuRepresentation.qml`)
plus independent pages (`PinnedPage.qml`, `AllAppsPage.qml`, `SearchPage.qml`)
and shared grid components (see file tree below).

**Phase 1 (complete):**
- `PlasmaCore.Dialog` with `Floating` location, positioned relative to the
  panel button via `parent.mapToGlobal`.
- Search field with rounded corners (`radius: smallSpacing*3`) and subtle
  border (12% text color alpha), Segoe UI font.
- Left column switches between three states (not a `SwipeView`): Pinned
  (favorites vertical list), All Apps (alphabetical vertical list),
  Search (filter pills + runner results).
- Right column with user avatar and a vertical list of system locations
  (Home, Documents, Pictures, Music, etc.).
- Compound bottom bar with a search field on the left and a split
  "Shut down" button on the right that opens a power-options popup.
- `AToolButton` with rounded corners (`radius: smallSpacing`), gray border,
  subtle hover (rgba 0.3).
- Config UI: icon picker, icon sizes, display position, right-column
  visibility, all-apps sort mode.

**Phase 2 (pending):** pinned folders, all-apps folders, launch-frequency
 tracking, smart context labels, and a `/`-prefix command palette.
 See `docs/STARTMENU_PLAN.md` for the full plan.

**Imports:** Modern Qt6 style (no version numbers except
`org.kde.plasma.private.kicker 0.1` and `org.kde.kitemmodels 1.0`).
`KPlugin.Id`: `org.kde.windowsmodern.startmenu`, License `GPL-3.0-or-later`,
Author `Jeysef`.

#### Digital Clock applet (`plasma/applets/org.kde.windowsmodern.digitalclock/`)

A pure-QML fork of the upstream `org.kde.plasma.digitalclock`, rebranded
as `org.kde.windowsmodern.digitalclock` and redrawn with Windows 11
visuals. It reuses the upstream Plasma clock and calendar backends
(`org.kde.plasma.clock`, `org.kde.plasma.private.digitalclock`,
`org.kde.plasma.workspace.calendar`) so all KDE functionality is
preserved: time/date formatting, time zones, calendar events, week
numbers, and calendar plugins.

Win11 refinements over upstream:

- **Windows-sized compact clock** — every line (time, date, time zone)
  uses the same font size: the system UI font in Automatic mode, the
  chosen size in Manual mode. It never grows with the panel; it shrinks
  only when the lines would not fit (2 px margin). The default date is
  the locale's short date with a four-digit year (`11.11.2026` in
  cs_CZ), via `shortDateFullYear` in `code/dateformat.js`.
- **Theme-aware rounded popup** — the popup fill, border and shadow are
  supplied by the Plasma theme's `dialogs/background.svg`
  (`#2C2C2C`/`#F9F9F9` fill with `#3F3F3F`/`#E5E5E5` border), 8px corner
  radius, sized by `expandedWidth` (default 320px). Text colors come
  from the Win11 palette via `Win11Palette`.
- **Win11 time header** — large seconds-capable time with AM/PM rendered
  smaller and raised, plus a locale-aware "dddd, MMMM d" date line.
- **Win11 calendar grid** — month/year header with custom chevron
  buttons, localized day-of-week header, 6-week grid, current day as a
  solid accent circle (`#4CC2FF` dark / `#0067C0` light), hover/pressed
  rounded rectangles (`#3F3F3F`/`#E9E9E9`), selected day as a subtle
  rounded rectangle (`#2C2C2C`/`#F3F3F3`), and previous/next month days
  dimmed. Days scale slightly when pressed and colors animate.
- **Event dots** — small colored dots under days that have events from
  enabled KDE calendar plugins; hovering a day with events shows a
  tooltip with the event summaries.
- **Dynamic navigation** — mouse wheel over the grid flips months, arrow
  keys move the selection, Page Up/Down flips months, Home jumps to
  today, and clicking a day from the previous/next month jumps to that
  month. Month changes cross-fade.
- **Time zone list** — shown in the popup when multiple time zones are
  configured.

Removed interactions: pin on middle-click, calendar launch,
clipboard time copy, and wheel-to-switch-timezone.

Config keys are the same as upstream plus `expandedWidth` (int). Build and install with
`./install.sh digitalclock`.

#### System Tray applet (`plasma/applets/org.kde.windowsmodern.systemtray/`)

A C++ fork of the upstream Plasma system tray, rebranded as
`org.kde.windowsmodern.systemtray` and restyled with Windows 11 visuals.
It is a full `Plasma::Containment`, so child applets (network, volume,
battery, clipboard, notifications, etc.) appear and disappear
automatically. The QML UI is embedded in the compiled `.so`; a separate
KPackage must not be installed (it causes the dark-rectangle popup bug).
See `docs/SYSTEMTRAY_ARCHITECTURE.md` and
`plasma/applets/org.kde.windowsmodern.systemtray/BUILD.md`.

Tray icons stay separate, Windows 10 style: each opens its own page
(network, volume, battery…). The chevron opens the Quick Settings flyout
(a Windows 11/10 hybrid):
hidden tray icons as a 3-column tile grid, then the toggles and sliders.
The flyout fits its content (no fixed height). The tile grid shows up to
three rows, then scrolls; its edges and 6 px gaps match the toggle grid
exactly (14 px margins at 100% scale).

#### Icon Tasks applet (`plasma/applets/org.kde.windowsmodern.icontasks/`)

A C++ fork of the upstream `org.kde.plasma.taskmanager` (from
plasma-desktop), restyled with Windows 11 tooltip visuals. The C++ backend is preserved
unchanged (jump lists, places, recent docs, app categories, smart
launcher badges, audio stream matching). The QML UI is forked from
upstream with minimal Win11 refinements:

- **Always icons-only** — `iconsOnly` hardcoded to `true`.
- **Hidden subtext in thumbnail mode** — desktop/activity info ("On
  Desktop 2") is hidden when a window thumbnail is visible (Win11
  behavior — it's noise when the preview already shows the window).
- **Subtle close button** — replaces the upstream `PlasmaComponents3.ToolButton`
  with a minimal X icon pinned to the far right of the header row. Background is
  transparent by default and turns Win11 red `#C42B1C` on hover; pressed is
  `#9E1B1B`.
- **Rounded thumbnail corners** — PipeWire thumbnail clipped to 8px
  rounded corners via `OpacityMask` (Win11 thumbnails are rounded).

No font is forced — the global `Kirigami.Theme.defaultFont` is used
throughout, matching the rest of the desktop.

The QML UI is embedded in the compiled `.so`; a separate KPackage must
not be installed. Build and install with `./dev.sh` or
`./install.sh icontasks`. See
`plasma/applets/org.kde.windowsmodern.icontasks/BUILD.md`.

The fork registers under the stock plugin ID `org.kde.plasma.icontasks`
(the source directory is still `org.kde.windowsmodern.icontasks/`). The
panel layout template and look-and-feel layout scripts therefore add
`org.kde.plasma.icontasks`, which loads the fork when it is installed and the
stock icons-only task manager otherwise. Because that ID belongs to a
distro-owned package, `dev.sh` moves the stock KPackage aside to
`/var/lib/windows-modern/backup/` and `uninstall.sh` restores it.

#### Popups / tooltips

The following files were rewritten as clean 9-patch SVGs with
authentic Win11 colors (replacing the original hardcoded light
color schemes that caused unreadable white popups on dark theme):

| File | Purpose | Corners | Margin hints |
|---|---|---|---|
| `widgets/tooltip.svg` | Hover tooltips | 8px radius, 1px Fluent stroke | 8px |
| `dialogs/background.svg` | Dialog/popup backgrounds | 7px | 8px |
| `widgets/background.svg` | Applet/widget backgrounds | 7px | 8px |
| `widgets/translucentbackground.svg` | Translucent applet popups | 7px | 8px |

All four exist in both `widgets/`, `solid/widgets/`, and
`translucent/widgets/` as needed, with consistent colors.

Tooltips use a **subtle 1 px Fluent stroke** baked into the 9-patch
edge/corner tiles (dark: white `#14FFFFFF`, light: black `#14000000`)
to avoid the double-border artifact caused by an SVG `stroke`
against the tooltip window edge. The fill matches the acrylic/popup
spec for the default and translucent variants (`#2C2C2C` dark,
`#F9F9F9` light) while solid fallbacks keep `#323130` dark and use
`#F0F0F0` light. The soft outer drop shadow is 8px deep (matching the
8px corner radius so the shadow curves around the rounded body rather
than forming a square frame) at 0.16 dark / 0.14 light opacity for a
Win11 elevation penumbra.

#### Slider (`widgets/slider.svg` + Kvantum)

System-wide slider styling across Plasma applets and Kvantum (Qt apps).
The system tray flyout uses the default `PlasmaComponents3.Slider`, which
inherits the themed look.

| Element | Dark | Light |
|---|---|---|
| Filled track | `ColorScheme-Highlight` = `#4CC2FF` (luminous cyan) | `ColorScheme-Highlight` = `#0067C0` (royal blue) |
| Unfilled track | `ColorScheme-Text` @ 25% opacity (medium grey) | `ColorScheme-Text` @ 25% opacity (medium-dark grey) |
| Knob outer ring | `ColorScheme-Background` (dark grey) | `ColorScheme-Background` (white) with `#D5D5D5` border |
| Knob inner circle | `ColorScheme-Highlight` (cyan) | `ColorScheme-Highlight` (royal blue) |
| Hover/focus glow | `ColorScheme-Highlight` @ 20-30% opacity | `ColorScheme-Highlight` @ 20-30% opacity |

- **Kvantum** — `slider_width=4`, `slider_handle_width=16`. The
  `slidercursor-*` SVG elements render the two-circle knob (outer ring
  + inner accent). Groove elements use solid fills (`slider-normal-*`
  for unfilled, `slider-toggled-*` for filled).
- **Plasma theme** — `widgets/slider.svg` uses the same two-circle
  knob design. Both groove and knob use `ColorScheme-*` CSS classes
  with `fill="currentColor"` — the filled track and knob inner circle
  use `ColorScheme-Highlight`, the unfilled track uses `ColorScheme-Text`
  at 25% opacity, and the knob outer ring uses `ColorScheme-Background`.
  This makes the slider automatically follow the per-variant accent
  without hardcoded hex values.

#### Switch / toggle (`widgets/switch.svg`)

The on/off switches in Plasma popups (Wi-Fi, Bluetooth, airplane mode…),
styled like Windows 11. Both themes' files are **generated** by
`scripts/gen-switch-svg.py`; edit the script, then run
`tests/theme/check-switch.py`, which renders the real Plasma switch and
fails if anything but accent shows around the on-pill.

| State | Track | Knob |
|---|---|---|
| Off | 36×20 1 px outline, `ColorScheme-Text` at 55 % (dark) / 45 % (light) | 11 px, `ColorScheme-Text` at 79 % / 62 % |
| On | 37×20 solid `ColorScheme-Highlight` pill | 12 px, `ColorScheme-Background` |
| Hover / pressed | unchanged | 12 px accent ring around a 10 px `ColorScheme-Background` dot |

Geometry follows Plasma's `SwitchIndicator.qml`, which draws the on-pill
1 px further right than the off-outline. The on-pill's ends (9 px wide,
10 px tall, so slightly oval and full height) are therefore centred on
the knob, and the off-outline's ends (8.5 × 10) sit just inside them. If the outline is as large as the pill, it shows as
a white (dark) or black (light) rim on the left of every switched-on
switch. Hover and pressed use one element for both states, so the accent
ring merges into the on-pill and only highlights the off knob. There is
no knob shadow.

#### Taskbar (`widgets/tasks.svg`)

Rendered by the upstream `org.kde.plasma.icontasks` applet (the panel
layout template uses it). The SVG supplies the hover/focus background
 visuals:

| State | Dark | Light |
|---|---|---|
| Hover fill | `#0FFFFFFF` (~6% white) | `#09000000` (~3.5% black) |
| Hover border | `#08FFFFFF` (~3% white) | `#08000000` (~3% black) |
| Focus/pressed fill | `#17FFFFFF` (9% white) | `#17000000` (9% black) |
| Corner radius | 4 px | 4 px |
| Border thickness | 1 px | 1 px |

- **Group expander removed** — the `group-expander-*` groups (white
  circle with `+` icon) are emptied. Windows 11 does not show a plus
  indicator on grouped taskbar buttons.
- **Inactive app indicator `#858585`** — the running-indicator strip
  under normal/minimized task buttons uses solid `#858585` at full
  opacity in both dark and light variants. Active/hover indicators
  use the per-variant accent (`#4CC2FF` dark / `#0067C0` light).

> Note: upstream `icontasks` is now a compiled C++ plugin, so exact
> 40×40 px hover-box sizing and a separate mouse-down pressed state can
> only be controlled from the SVG/theme level. The values above are the
> closest match using the Plasma desktop theme.

#### Icons

165 SVG icon files inherited from Win11OS-dark. A few icons
(`caffeine.svg`, `microphone.svg`, `update.svg`) have their own
embedded color schemes; these are intentional and not modified.

### Aurorae Window Decoration

Location: `aurorae/windows-modern-{dark,light}-aurorae/`

#### Layout (`*.rc`)

```
BorderTop=1        BorderBottom=1      BorderLeft=1      BorderRight=1
PaddingTop=0       PaddingBottom=0     PaddingLeft=0     PaddingRight=0
TitleHeight=30     TitleHeightMaximized=30
ButtonWidth=46     ButtonHeight=30     ButtonSpacing=0
TitleEdgeLeft=8    ExplicitButtonSpacer=10
```

- 1px borders on all sides, zero padding — window content goes
  edge-to-edge with only the 1px decoration border.
- Title height 30px (authentic Win11 proportions).
- `BorderSize=Tiny` is auto-set in kwinrc by `install.sh`.

#### Decoration SVG (`decoration.svg`)

Rewritten with minimal 1px border elements:
- Edge elements (top/bottom/left/right) are 1x1px.
- Corner elements are 2x2px (1px border + 1px fill overlap).
- Active border: `#3F3F3F` (dark) / `#E5E5E5` (light).
- Inactive border: `#2A2A2A` (dark) / `#D5D5D5` (light).
- Background via `currentColor` / `ColorScheme-Background`.

#### Button SVGs

- 46x30px buttons, icon centered in a 22x22 area.
- Normal state: transparent background (0.003 opacity hit rect).
- Hover state: close = `#C42B1C` red, others = subtle overlay.
- Pressed state: `#000000` at 0.1 opacity.
- Icons: `#FFFFFF` (dark theme) / `#1E1E1E` (light theme).
- Deactivated: icon at 0.1 opacity.

### Kvantum Qt Style

Location: `Kvantum/Windows-modern/`

SVG-based Qt widget theme. The directory contains the base light theme
(`Windows-modern.kvconfig` / `.svg`) and its dark variant
(`Windows-modernDark.kvconfig` / `.svg`). KDE switches between them
automatically by using the `kvantum` and `kvantum-dark` widget styles.
Based on the **Fluent** Kvantum theme by
Vince Liuice (itself derived from KvAdapta by Tsu Jan), with colors
remapped to authentic Win11 values. The Fluent base was chosen over
the previous KvAdapta/Materia base because it already ships Win11
proportions (`check_size=20`, `progressbar_thickness=10`,
`spread_menuitems=true`, `attach_active_tab=true`,
`toolbutton_style=0`, `merge_menubar_with_toolbar=false`) and a
cleaner SVG element set (`flatbutton`, `tbutton`, proper inactive
text colors, fuller frame definitions).

#### List and file selection

Windows 11 Explorer marks selected items with a light accent tint and
keeps the normal text colour. The dark variant does the same: the
`itemview-pressed` / `-toggled` elements are the accent at 32 % / 24 %
over the background (a blue-grey), with white text. The light variant
still uses the solid accent with white text: Dolphin draws a selected
file's name in the palette's highlighted-text colour, which is also the
colour of selected text in editors, so a light tint with dark text needs
a palette-level change first.

#### Compositing model

Both variants use the **translucent model** — `composite=true`,
`translucent_windows=true`, `blurring=true`, `popup_blurring=true`.
Kvantum handles popup shadows (`menu_shadow_depth=5`,
`tooltip_shadow_depth=2`, `shadowless_popup=false`) and acrylic-style
blur behind menus/tooltips. The SVG `menu-shadow-*` and
`tooltip-shadow-*` element trees are intact and render as soft drop
shadows via compositing.

#### `[GeneralColors]` palette

The Fluent neutrals were replaced with authentic Win11 values sourced
from WinUI 3. Win11 uses different accent shades per mode:
`SystemAccentColorLight2` (`#4CC2FF`) in dark mode and
`SystemAccentColorDark1` (`#0067C0`) in light mode — both derived from
the base `SystemAccentColor` (`#0078D4`). The accent is baked into the
SVG indicator elements (checkbox marks, radio dots, progressbar fill,
focus rings).

| Token | Dark | Light |
|---|---|---|
| `window` | `#202020` | `#F9F9F9` |
| `base` / `alt.base` | `#2C2C2C` | `#FFFFFF` / `#F8F8F8` |
| `button` | `#2C2C2C` | `#F3F3F3` |
| `light` (hover) | `#3F3F3F` | `#E9E9E9` |
| `mid.light` | `#3F3F3F` | `#E9E9E9` |
| `dark` | `#1F1F1F` | `#E5E5E5` |
| `highlight` / `link` | `#4CC2FF` | `#0067C0` |
| `inactive.highlight` | `#4CC2FF74` | `#0067C074` |
| `text` | `#FFFFFF` | `#1E1E1E` |
| `disabled.text` | `#5A5A5A` | `#A0A0A0` |

Per-section `text.*.color` values throughout the config follow the
same mapping (dark = `#FFFFFF`, light = `#1E1E1E`), with `#ffffff`
preserved for pressed/toggled states (white-on-accent) and the
per-variant accent (`#4CC2FF` dark / `#0067C0` light) for GroupBox
focus labels.

#### Key `[%General]` behavior

Inherited from Fluent (already Win11-correct):
- `spread_menuitems=true` — menu items span full menu width (Win11).
- `attach_active_tab=true` — active tab attaches to content below.
- `merge_menubar_with_toolbar=false`, `toolbutton_style=0`.
- `progressbar_thickness=10`, `check_size=20` (Win11 proportions).
- `transient_scrollbar=true` (auto-hide scrollbars).
- `animate_states=false` (Fluent disables state animations).
- `left_tabs=true`, `combo_as_lineedit=true`, `combo_menu=true`.
- `x11drag=menubar_and_primary_toolbar`.

#### `[Hacks]`

Inherited from Fluent: `transparent_ktitle_label=true`,
`transparent_dolphin_view=true`, `transparent_pcmanfm_sidepane=true`,
`transparent_pcmanfm_view=true`, `transparent_menutitle=true`,
`transparent_arrow_button=true`, `respect_darkness=true` (both
variants), `force_size_grip=true`, `iconless_pushbutton=false` (both
variants), `single_top_toolbar=true`, `kcapacitybar_as_progressbar=true`.

#### SVG element fills

The Fluent SVG fills were remapped to Win11 neutrals. The accent was
updated to per-variant shades (`#4CC2FF` dark / `#0067C0` light). Key
mappings:

| Fluent color | Win11 target | Role |
|---|---|---|
| `#2B2B2B` | `#2C2C2C` | base/button/control backgrounds |
| `#333333` | `#2C2C2C` (dark) / `#F9F9F9` (light) | menu body, dock, header |
| `#3C3C3C` | `#3F3F3F` | header/dock borders |
| `#dedede` | `#FFFFFF` (dark text/icons) | secondary text, unchecked marks |
| `#000000` | unchanged | bevel/shadow overlays (translucent) |
| `#0078D4` | `#4CC2FF` (dark) / `#0067C0` (light) | accent (checkbox/radio marks, progress, focus) |
| `#202020` | unchanged | window/menubar/titlebar bg (dark) |
| `#f04a50` | `#C42B1C` (close) / text color (others) | mdi caption-button hover glyphs |
| `#0078D4` (pressed) | text color | mdi caption-button pressed glyphs |
| `#b74aff` | unchanged | shadow hint markers (arbitrary) |

Shadow elements (`menu-shadow-*`, `tooltip-shadow-*`) use gradient
fills and `#343031`/`#26272a` shells — left intact as they render
correctly under compositing.

### Color Schemes

Location: `color-schemes/WindowsModern{Dark,Light}.colors`

KDE color scheme files defining system-wide colors for widgets,
selections, tooltips, etc. Rewritten with Win11 values:
`ColorScheme=WindowsModernDark` / `WindowsModernLight` (the previous
`McMojave` / `McMojaveLight` leftovers were removed). Dark uses
`BackgroundNormal=32,32,32` for windows and `44,44,44` for buttons;
light uses `249,249,249` / `243,243,243`. Selection accent is
`76,194,255` (`#4CC2FF`) in dark and `0,103,192` (`#0067C0`) in light —
matching Win11's `SystemAccentColorLight2` and `SystemAccentColorDark1`
respectively.

### Look-and-Feel

Location: `plasma/look-and-feel/org.kde.windowsmodern.{dark,light}/`

The `contents/defaults` file wires everything together:

```
[kwinrc][org.kde.kdecoration2]
library=org.kde.kwin.aurorae
theme=__aurorae__svg__windows-modern-{dark,light}-aurorae

[plasmarc][Theme]
name=Windows-modern-{dark,light}

[kdeglobals][Icons]
Theme=windows-modern

[kdeglobals][General]
ColorScheme=WindowsModern{Dark,Light}

[kwinrc][WindowSwitcher]
LayoutName=org.kde.windowsmodern.alttab
```

Each package also contains
`contents/layouts/org.kde.plasma.desktop-layout.js`, the Plasma 6
desktop layout script for the default `org.kde.plasma.desktop` shell.
When the global theme is applied and the user opts in to the theme's
desktop layout, this script first removes any existing panels and then
creates the Windows Modern Panel (see the Panel layout template section
above) with the Win11-style centered taskbar, start menu, system tray,
clock, and show-desktop sliver.

### Alt+Tab window switcher

Location: `plasma/windowswitcher/org.kde.windowsmodern.alttab/` — a KWin
TabBox layout (`KPackageStructure: KWin/WindowSwitcher`), installed to
`~/.local/share/kwin/tabbox/` and selected via `kwinrc [TabBox] LayoutName`.
`main.qml` only hosts the popup; all visuals live in `SwitcherView.qml`.

| Element | Spec (at 100% scale) |
|---------|----------------------|
| Container | Theme dialog background, 12 px padding, centered on the active screen |
| Preview height | 17% of screen height, clamped to 110–220 px |
| Preview width | Window aspect ratio × height, ratio clamped to 0.75–2.2 |
| Card | 6 px padding, 8 px radius, 4 px gap; rows wrap at 90% screen width and are centered |
| Header | 30 px: 16 px app icon, 8 px gap, title (elided), close button on the right |
| Preview corners | 4 px radius (square on the software renderer, where the shader mask cannot run) |
| Selected | 3 px ring in the text colour (white on dark, near-black on light) + 9% text-colour fill |
| Hover | 6% text-colour fill; close button turns `#C42B1C` on hover |

Keyboard: Tab / Shift+Tab are handled by KWin; Left/Right move by one and
wrap; Up/Down move to the nearest card in the neighbouring row and wrap.
Middle-click closes a window. Colours come from `Kirigami.Theme`, so one
package serves both variants.

### Session Lock Screen (Meta+L)

Location: `plasma/shells/org.kde.windowsmodern.lockscreen/`

A Windows 11-style session lock screen. kscreenlocker resolves the lock
screen from the **current desktop shell package**
(`org.kde.plasma.desktop`), so this is installed as a complete user-level
overlay of that shell: `install-sessionlock.sh` symlinks every system
`contents/` directory back to the system shell **except** `lockscreen`,
which is replaced with our custom Windows Modern QML. The shell package
is always kept complete — an incomplete shell triggers the ugly Qt widget
fallback. On uninstall, the entire user shell directory is removed.

Files under `contents/lockscreen/`:

| File | Purpose |
|---|---|
| `LockScreen.qml` | Root item (kscreenlocker entry point). |
| `LockScreenUi.qml` | Background, clock, status icons, unlock UI, footer. |
| `MainBlock.qml` | Password entry block (avatar, username, MDL2 field). |
| `NoPasswordUnlock.qml` | Direct unlock when no password is set. |
| `MediaControls.qml` | Idle media playback controls (MPRIS). |
| `config.qml` / `config.xml` | Config UI + schema (clock, media controls). |
| `qmldir` | QML module definition. |

Design (Win11 dark palette):

- **Background**: KDE-configured wallpaper via `WallpaperFader` (same as
  Breeze), with a `#000000` @ 0.45 overlay when the unlock UI is visible.
- **Clock**: Centered, upper-middle. Segoe UI DemiBold 96px time, 24px
  date (`#E0E0E0`). Visible only when idle; fades out when unlocking.
- **Status icons**: Bottom-right, icon-only (network, volume, battery).
  Idle only.
- **Power menu**: `#2C2C2C` fill, `#3F3F3F` border, `#33FFFFFF` item hover.
- **Password field**: 1px border, `#A0A0A0` idle / `#4CC2FF` focus (dark
  accent `SystemAccentColorLight2`).
- **Login button**: `go-next`, `#A0A0A0` idle / `#4CC2FF` hover.
- **Animations**: `Kirigami.Units.veryLongDuration * 2` (~800ms),
  `InOutQuad` easing.

### Boot Greeter / Login Screen (Plasma Login Manager)

Location: `plasma/look-and-feel/org.kde.windowsmodern.dark/contents/lockscreen/`
(theme QML) and `third_party/plasma-login-manager/` (patched upstream
submodule, KDE invent `Plasma/6.6` branch).

The boot greeter (display-manager login screen) is a **patched build of
`plasma-login-manager`**. The patch
(`patches/main-cpp.patch`) makes the greeter's `main.cpp` load our
`Main.qml` from the dark look-and-feel's `contents/lockscreen/` instead of
the bundled qrc resource, trying the system path first then the user path.

| File | Purpose |
|---|---|
| `Main.qml` | Root greeter: blurred wallpaper + dark overlay, clock, login stack, user switcher, footer. |
| `Login.qml` | Login block: avatar, username, password field, GreeterState sync. |
| `SessionButton.qml` | Desktop session selector (Wayland/X11). |
| `KeyboardButton.qml` | Keyboard layout switcher. |
| `faces/.face.icon` | Default avatar. |
| `patches/main-cpp.patch` | Patches `main.cpp` to load our `Main.qml`. |

The greeter QML reuses the same Win11 dark palette as the session lock
screen (clock, power menu, password field colors). The wallpaper defaults
to the Windows Modern dark wallpaper installed system-wide
(`/usr/share/wallpapers/Windows-modern/contents/images_dark/2560x1440.png`);
`install-greeter-live.sh` ensures it exists.

Because this replaces the system login manager, it is **opt-in and not
included in `install.sh all`**:

- `./install.sh greeter` (or `scripts/install-greeter.sh`) — builds the
  patched greeter and installs the theme to the user dir for `--test` mode.
- `sudo bash scripts/install-greeter-live.sh` — installs the patched
  binary system-wide (backs up `/usr/libexec/plasma-login-greeter` to
  `.orig`, requires typed `YES`).
- `./scripts/update-plm.sh [branch]` — updates the PLM submodule, reapplies
  patches, rebuilds.

Revert: `sudo bash scripts/uninstall-greeter-system.sh` (restores from
`.orig` or reinstalls the distro package).

### Icons

Location: `icons/windows-modern/` (gitignored — ~145MB)

Curated Windows-11-style icon theme assembled from multiple upstream
 packs (Eleven, Fluent, Cobalt, Windows-Eleven, Win11, We10X, Fluentwin,
 Windows-Beuty), restructured to a clean freedesktop layout:
 `<size>/<context>/` fixed tiers
(8, 16, 22, 24, 32, 48, 64 + @2x where genuine HiDPI art exists),
`scalable/<context>/` (16-256px), and `symbolic/<context>/`
(8-512px monochrome). The original dual-layout duplication
(parallel `<context>/<size>/` trees with conflicting artwork) was
removed along with 23,340 byte-identical @2x copies, cutting the
theme from 583MB / 98k SVGs to 145MB / 25k SVGs (7,313 unique
names). Orphaned `status/weatheralt/` weather icons were migrated
to `scalable/status/`. `index.theme` rewritten with 88 directory
entries and correct `Context=Categories` (was `Applications`)
labeling. Inherits `breeze-dark,hicolor`. The `icon-theme.cache`
is rebuilt at install time via `gtk-update-icon-cache`.

#### Start-here icon

A custom Windows-logo start menu icon is shipped as
`scalable/apps/start-here.svg` and `48/apps/start-here.svg`:

- The **scalable** version is used at most panel heights.
- The **48px fixed** version draws the logo at exactly 30px (matching
  `icontasks` app icons on a 48px panel) instead of scaling the
  full-canvas logo up to the panel height.
- `start-here-kde.svg` and `start-here-kde-plasma.svg` are symlinks to
  `start-here.svg` in both `scalable/apps/` and `48/apps/` so any
  Plasma fallback icon name uses the same glyph.

---

## Install / Uninstall

### Install

Interactive menu (recommended for first install):

```sh
./install.sh
```

Install everything non-interactively:

```sh
./install.sh all
```

Install individual components:

```sh
./install.sh themes      # Aurorae, colors, Kvantum, Plasma themes, wallpapers
./install.sh icons       # Icon pack
./install.sh lookfeel    # Global themes
./install.sh layout      # Panel layout template
./install.sh showdesk    # Show Desktop applet
./install.sh startmenu   # Start Menu applet
./install.sh systray     # System Tray applet (C++ — see below)
./install.sh applets     # All three applets
```

Copies all themes to `~/.local/share/` (user) or `/usr/share/` (root),
then automatically sets `BorderSize=Tiny` in kwinrc and reconfigures
KWin so window decorations have no extra padding.

### System Tray

The System Tray applet is a compiled C++ Plasma::Containment. Install it
with:

```sh
./install.sh systray
```

This builds the `.so`, removes any conflicting KPackage, prunes stale
local copies, and restarts `plasmashell`. Build dependencies are listed
in `plasma/applets/org.kde.windowsmodern.systemtray/BUILD.md`.

### Uninstall

```sh
./uninstall.sh all       # Remove everything
./uninstall.sh themes    # Remove theme components
./uninstall.sh icons     # Remove icon pack
./uninstall.sh systray   # Remove system tray plugin
# ... etc.
```

Removes theme directories and resets `BorderSize` to `Normal`.

---

## Repository Structure

```
windows_modern2/
├── aurorae/
│   ├── windows-modern-dark-aurorae/     # Dark window decoration
│   └── windows-modern-light-aurorae/    # Light window decoration
├── color-schemes/
│   ├── WindowsModernDark.colors
│   └── WindowsModernLight.colors
├── Kvantum/
│   └── Windows-modern/                   # Kvantum Qt style (light + dark variants)
├── icons/
│   └── windows-modern/                   # Curated Win11 icon theme (gitignored)
├── plasma/
│   ├── applets/
│   │   ├── org.kde.windowsmodern.showdesktop/     # Win11 thin-show-desktop sliver
│   │   ├── org.kde.windowsmodern.startmenu/       # Win11 Start Menu
│   │   └── org.kde.windowsmodern.systemtray/      # Win11 system tray
│   ├── desktoptheme/
│   │   ├── Windows-modern-dark/         # Dark plasma theme (165 SVGs)
│   │   └── Windows-modern-light/        # Light plasma theme (165 SVGs)
│   ├── layout-templates/
│   │   └── org.kde.windowsmodern.panel/ # Win11 centered taskbar layout
│   ├── look-and-feel/
│   │   ├── org.kde.windowsmodern.dark/  # Dark global theme (+ boot greeter QML)
│   │   └── org.kde.windowsmodern.light/ # Light global theme
│   └── shells/
│       └── org.kde.windowsmodern.lockscreen/ # Session lock (Meta+L) QML
├── third_party/
│   └── plasma-login-manager/             # Patched PLM submodule (boot greeter)
├── wallpaper/
├── docs/
│   └── STYLE.md                         # This file
├── install.sh
├── uninstall.sh
└── README.md
```

---

## Credits

- Plasma desktop theme based on [Win11OS-kde](https://github.com/yeyushengfan258/Win11OS-kde)
  by yeyushengfan258 (GPL 3.0).
- Win11 color values verified from
  [microsoft-ui-xaml](https://github.com/microsoft/microsoft-ui-xaml)
  theme resources.
- Kvantum theme based on [Fluent-kde](https://github.com/vinceliuice/Fluent-kde)
  by vinceliuice.
- **[mjkim0727](https://github.com/mjkim0727/Eleven-icon-theme)** —
  **Eleven** icon pack.
- **[vinceliuice](https://github.com/vinceliuice/Fluent-icon-theme)** —
  **Fluent** icon pack.
- **[Eisteed](https://github.com/Eisteed/menu-11-next)** —
  **Menu11 - Next** start menu plasmoid, used as a reference for the
  Windows Modern Start Menu (forked from
  [adhec/OnzeMenuKDE](https://github.com/adhec/OnzeMenuKDE)).
- **[Zren / Chris Holland](https://github.com/Zren)** — upstream Show
  Desktop applet (`win7showdesktop`).
- Window decoration, popup SVGs, icon curation, applets, and integration
  by Jeysef.
- Additional icon pack sources are credited in
  [`ATTRIBUTION.md`](ATTRIBUTION.md).

## License

GNU GPL v3
