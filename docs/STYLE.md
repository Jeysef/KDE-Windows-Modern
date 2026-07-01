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

> Color values are sourced from the WinUI 3 (microsoft-ui-xaml)
> theme resource dictionaries. See `docs/colors.md` for full RGB
> mappings including the plasma `colors` file.

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
  2. **Start** — `org.kde.plasma.kickoff` (icon `start-here`). A custom
     Windows-logo icon is provided, with both a scalable version and a
     fixed `48/apps/start-here.svg` that draws the logo at 30px so it
     matches the app-icon size on a 48px panel.
  3. **Icon-only task manager** — `org.kde.plasma.icontasks` (grouped
     by app, sits immediately to the right of Start in the centered
     group)
  4. **Right expanding spacer** — `org.kde.plasma.panelspacer`. Separates
     the centered Start + tasks group from the system tray on the far
     right.
  5. **System tray** — `org.kde.plasma.systemtray`
  6. **Quick Settings** — `org.kde.windowsmodern.quicksettings`, the
     custom Win11-style flyout (see below). Renders as a compact
     network/volume/battery cluster in the panel; click opens the
     Quick Settings flyout with toggle tiles and sliders.
  7. **Digital clock** — `org.kde.plasma.digitalclock` pinned to
     Segoe UI Regular 10pt, no date, no seconds, 12h format. The fixed
     font size keeps the clock readable without dominating tall panels.
  8. **Show Desktop** — `org.kde.windowsmodern.showdesktop`, a custom
     forked applet (see below). Renders as an 6px-wide bare sliver with
     a 1px separator line on its left edge, no icon. Click minimizes all
     windows; click again restores.

The template does not replace an existing panel automatically; users add it
via right-click desktop → Add Panels → "Windows Modern Panel".

In addition, each look-and-feel package ships the same layout as
`contents/layouts/org.kde.plasma.desktop-layout.js` (the file name
Plasma 6 expects for the default `org.kde.plasma.desktop` shell). When a
user applies the global theme in System Settings → Appearance → Global
Theme and chooses to use the desktop layout from the theme, Plasma
removes any existing panels and creates the Windows Modern Panel
automatically.

#### Quick Settings applet (`plasma/applets/org.kde.windowsmodern.quicksettings/`)

A custom Win11 Quick Settings flyout, built from scratch by combining
the best patterns from the installed **Plasma Control Hub** (zayronxio)
and **KDE Control Station** (Eliver Lara) plasmoids. Both are GPL-3.0+
and were used as API reference only; the code is original.

- **Compact representation** — a Win11-style system tray cluster showing
  network, volume and battery icons in a row. Click opens the flyout.
- **Full representation** — a 360px-wide flyout with:
  - A 3-column grid of toggle tiles with 2:1 aspect ratio and a single
    text label below each button. Tiles: Wi-Fi, Bluetooth (split tiles
    with a chevron arrow opening a detail page), Airplane, Battery Saver,
    Night Light. Active tiles use the per-variant accent fill
    (`Kirigami.Theme.highlightColor` = `#4CC2FF` dark / `#0067C0` light)
    with white icons; inactive tiles use a subtle 4% text-color
    background. 4px corner radius, matching Win11.
  - Brightness and volume sliders using the system-default
    `PlasmaComponents3.Slider` (themed via `widgets/slider.svg` and
    Kvantum — see below). Volume slider has a right-facing chevron that
    opens the audio KCM.
  - Footer with battery percentage/icon, an edit pencil (opens search
    settings) and a settings gear (opens System Settings), separated
    from the content by a subtle background tint rather than a hard line.
- **Page navigation** — a `StackView` pushes Network and Bluetooth
  detail pages (Wi-Fi network list, paired device list) when the
  split-tile chevrons are clicked. Detail pages use a shared
  `lib/DetailPage.qml` template with a back arrow, title, toggle switch
  (`lib/Switch.qml`), and a scrollable list view.
- **Library components** — `lib/Tile.qml` (plain toggle), `lib/SplitTile.qml`
  (toggle + chevron), `lib/Slider.qml` (icon + `PlasmaComponents3.Slider`
  + optional chevron), `lib/DetailPage.qml` (page template), `lib/Switch.qml`
  (toggle switch).
- **APIs used** — `org.kde.plasma.networkmanagement` (Wi-Fi/airplane),
  `org.kde.bluezqt` (Bluetooth), `org.kde.plasma.private.volume`
  (volume), `org.kde.plasma.private.brightnesscontrolplugin`
  (brightness + `NightLightInhibitor`), `org.kde.plasma.private.battery`
  (battery), `org.kde.plasma.workspace.dbus` (Night Light DBus state),
  `org.kde.plasma.private.batterymonitor` (`PowerProfilesControl` for
  battery saver).

Config keys (`contents/config/main.xml`): `scale` (80-150%), `showVolume`,
`showBrightness`, `showBattery`, `showNightLight`, `showBatterySaver`,
`showAirplane`, `darkTheme` (default `WindowsModernDark`), `lightTheme`
(default `WindowsModernLight`). Installed to
`~/.local/share/plasma/plasmoids/` (or `/usr/share/plasma/plasmoids/` as
root) by `install.sh`.

#### Show Desktop applet (`plasma/applets/org.kde.windowsmodern.showdesktop/`)

A simplified fork of [Zren's plasma-applet-win7showdesktop](https://github.com/Zren/plasma-applet-win7showdesktop)
(which itself forks KDE's `org.kde.plasma.showdesktop`). Stripped to
the essentials for the Win11 look:

- **Thin sliver** — `Layout.maximumWidth` is driven by the `size`
  config key (default 6px), overriding the upstream 22px floor.
- **No icon** — the `Kirigami.Icon` is only visible in edit mode.
- **Minimize-all** — uses `MinimizeAllController` (toggle minimize on
  all windows) rather than peek.
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

**Phase 1 (current):**
- `PlasmaCore.Dialog` with `Floating` location, positioned relative to the
  panel button via `parent.mapToGlobal`.
- Search field with rounded corners (`radius: smallSpacing*3`) and subtle
  border (12% text color alpha), Segoe UI font.
- `SwipeView` with 3 pages: Pinned (favorites grid + recent strip),
  All Apps (alphabetical grid), Search (filter pills + runner results).
- Footer with user tile + `PlasmaComponents3.ToolButton` action buttons
  (Home, Settings, Lock, Sleep, Restart, Shutdown).
- `AToolButton` with rounded corners (`radius: smallSpacing`), gray border,
  subtle hover (rgba 0.3).
- Config UI: icon picker, icon sizes, grid dimensions, display position,
  recent toggles, all-apps view/sort mode.

**Imports:** Modern Qt6 style (no version numbers except
`org.kde.plasma.private.kicker 0.1` and `org.kde.kitemmodels 1.0`).
`KPlugin.Id`: `org.kde.windowsmodern.startmenu`, License `GPL-3.0-or-later`,
Author `Jeysef`.

#### Popups / tooltips

The following files were rewritten as clean 9-patch SVGs with
authentic Win11 colors (replacing the original hardcoded light
color schemes that caused unreadable white popups on dark theme):

| File | Purpose | Corners | Margin hints |
|---|---|---|---|
| `widgets/tooltip.svg` | Hover tooltips | 4px radius, 1px Fluent stroke | 8px |
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
`#F0F0F0` light. The soft outer drop shadow is reduced to 0.12 dark /
0.10 light opacity for a diffuse Win11 elevation penumbra.

#### Slider (`widgets/slider.svg` + Kvantum)

System-wide slider styling across Plasma applets, Kvantum (Qt apps),
and the Quick Settings flyout. The plasmoid uses the default
`PlasmaComponents3.Slider`, which inherits the themed look.

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

Renders the on/off toggle switches used in Plasma applet popups
(e.g. network, Bluetooth, do-not-disturb). The original asset made
the off-state track and thumb the same color as the popup
background, so the switch was invisible against popups.

| Element | Class | Notes |
|---|---|---|
| Off track fill | none (transparent) | Pill outline only |
| Off track border | `ColorScheme-Text` | 1 px stroked outline, `stroke-linecap=round` for seamless joints |
| On track fill | `ColorScheme-Highlight` | Solid accent from the color scheme |
| On track border | none | Filled pill, no visible stroke |
| Knob (both states) | `ColorScheme-Text` | Same color as text — visible on both transparent off-track and accent on-track |
| Knob border | none | Flat, borderless |
| Focus/hover ring | `ColorScheme-Highlight` | 12 px accent ring around the 10 px knob |

- Both states share the same outer track size (38 × 16 px hint) and knob.
- The off track is a **transparent pill outline** stroked in
  `ColorScheme-Text` — no fill, so the popup background shows through.
  `stroke-linecap=round` ensures the 9-patch arc/line joints are seamless.
- The on track is a **solid accent pill** with no border.
- The knob uses `ColorScheme-Text` so it is always visible: white in
  dark mode (on blue track) and dark in light mode (hole effect on
  blue track).
- The knob is 10 px inside a 16 px handle bounding box, giving 3 px
  transparent padding on all sides so it never touches the track edge.

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

Location: `Kvantum/Windows-modern-{dark,light}/`

SVG-based Qt widget theme. Based on the **Fluent** Kvantum theme by
Vince Liuice (itself derived from KvAdapta by Tsu Jan), with colors
remapped to authentic Win11 values. The Fluent base was chosen over
the previous KvAdapta/Materia base because it already ships Win11
proportions (`check_size=20`, `progressbar_thickness=10`,
`spread_menuitems=true`, `attach_active_tab=true`,
`toolbutton_style=0`, `merge_menubar_with_toolbar=false`) and a
cleaner SVG element set (`flatbutton`, `tbutton`, proper inactive
text colors, fuller frame definitions).

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

Location: `plasma/look-and-feel/com.github.yeyushengfan258.Windows-modern-{dark,light}/`

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
```

Each package also contains
`contents/layouts/org.kde.plasma.desktop-layout.js`, the Plasma 6
desktop layout script for the default `org.kde.plasma.desktop` shell.
When the global theme is applied and the user opts in to the theme's
desktop layout, this script first removes any existing panels and then
creates the Windows Modern Panel (see the Panel layout template section
above) with the Win11-style centered taskbar, start menu, system tray,
quick settings, clock, and show-desktop sliver.

### Icons

Location: `icons/windows-modern/` (gitignored — ~145MB)

Win11 icon theme by yeyushengfan258 (based on Yaru), restructured
to a clean freedesktop layout: `<size>/<context>/` fixed tiers
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

```sh
./install.sh
```

Copies all themes to `~/.local/share/` (user) or `/usr/share/` (root),
then automatically sets `BorderSize=Tiny` in kwinrc and reconfigures
KWin so window decorations have no extra padding.

### Uninstall

```sh
./uninstall.sh
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
│   ├── Windows-modern-dark/
│   └── Windows-modern-light/
├── icons/
│   └── windows-modern/                   # Win11 icon theme (gitignored)
├── plasma/
│   ├── applets/
│   │   ├── org.kde.windowsmodern.quicksettings/  # Win11 Quick Settings flyout
│   │   ├── org.kde.windowsmodern.showdesktop/     # Win11 thin-show-desktop sliver
│   │   ├── org.kde.windowsmodern.startmenu/       # Win11 Start Menu
│   │   └── org.kde.windowsmodern.systemtray/      # Win11 system tray
│   │   └── org.kde.windowsmodern.showdesktop/    # Forked show-desktop sliver
│   ├── desktoptheme/
│   │   ├── Windows-modern-dark/         # Dark plasma theme (165 SVGs)
│   │   └── Windows-modern-light/        # Light plasma theme (165 SVGs)
│   ├── layout-templates/
│   │   └── org.kde.windowsmodern.panel/ # Win11 centered taskbar layout
│   └── look-and-feel/
│       ├── com.github.yeyushengfan258.Windows-modern-dark/
│       └── com.github.yeyushengfan258.Windows-modern-light/
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
- Window decoration, popup SVGs, and integration by Jeysef.

## License

GNU GPL v3
