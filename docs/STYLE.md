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
| Acrylic/popup background | `#2C2C2C` | Tooltips, flyouts, applet popups, panel |
| Surface border (active) | `#3F3F3F` | Window borders, popup borders |
| Surface border (inactive) | `#2A2A2A` | Inactive window borders |
| Text (primary) | `#FFFFFF` | Title bar text, popup text, icons |
| Text (inactive) | `30,30,30 @ 50%` | Inactive title bar text |
| Highlight/accent | `#60CDFF` | Focus indicators, links |
| Button hover bg | `#4A4A4A` | Hover states |
| Button bg | `#3D3D3D` | Button backgrounds |
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
| Highlight/accent | `#0078D4` | Focus indicators, links |
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

- **No shadow** — all `shadow-*` elements set to `opacity:0`,
  `shadow-hint-*-margin` rects zeroed (width/height = 0).
- **30px panel height** supported — hint margins are 4px top/bottom,
  corner elements ~11px, leaving adequate center space.
- Three variants maintained: `widgets/`, `solid/widgets/`,
  `translucent/widgets/`.
- Light variant uses reduced border opacity (0.08 vs 0.3) for
  visibility on light backgrounds.

#### Popups / tooltips

The following files were rewritten as clean 9-patch SVGs with
authentic Win11 colors (replacing the original hardcoded light
color schemes that caused unreadable white popups on dark theme):

| File | Purpose | Corners | Margin hints |
|---|---|---|---|
| `widgets/tooltip.svg` | Hover tooltips | 4px | 8px |
| `dialogs/background.svg` | Dialog/popup backgrounds | 7px | 8px |
| `widgets/background.svg` | Applet/widget backgrounds | 7px | 8px |
| `widgets/translucentbackground.svg` | Translucent applet popups | 7px | 8px |

All four exist in both `widgets/`, `solid/widgets/`, and
`translucent/widgets/` as needed, with consistent colors.

#### Taskbar (`widgets/tasks.svg`)

- **Group expander removed** — the `group-expander-*` groups (white
  circle with `+` icon) are emptied. Windows 11 does not show a plus
  indicator on grouped taskbar buttons.

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

SVG-based Qt widget theme. Both variants are **fully opaque** —
`composite=false`, `translucent_windows=false`, `blurring=false`,
`popup_blurring=false`. No Kvantum-added menu/tooltip shadows
(`menu_shadow_depth=0`, `tooltip_shadow_depth=0`); rely on the WM/DE
for popup shadows instead.

#### `[GeneralColors]` palette

The Materia-derived blue-grey palette was replaced with authentic
Win11 neutrals sourced from WinUI 3:

| Token | Dark | Light |
|---|---|---|
| `window` | `#202020` | `#F9F9F9` |
| `base` / `alt.base` | `#2C2C2C` | `#FFFFFF` |
| `button` | `#2C2C2C` | `#F3F3F3` |
| `light` (hover) | `#3F3F3F` | `#E9E9E9` |
| `mid.light` | `#3F3F3F` | `#E9E9E9` |
| `dark` | `#1F1F1F` | `#E5E5E5` |
| `highlight` | `#60CDFF` | `#0078D4` |
| `text` | `#FFFFFF` | `#1E1E1E` |
| `disabled.text` | `#5A5A5A` | `#A0A0A0` |
| `link` | `#60CDFF` | `#0078D4` |

#### Key `[%General]` behavior

- `spread_menuitems=true` — menu items span full menu width (Win11).
- `attach_active_tab=true` — active tab attaches to content below.
- `merge_menubar_with_toolbar=false`, `toolbutton_style=0`.
- `progressbar_thickness=10`, `check_size=20` (Win11 proportions).
- `transient_scrollbar=true` in both variants (auto-hide scrollbars).
- `animate_states=true` for smooth hover fades.

#### `[Hacks]`

All `transparent_*` keys set to `false` (solid Dolphin/PCManFM views,
menutitles, arrow buttons) to match the opaque window model.
`respect_darkness=true` (dark only). `force_size_grip=false`.

#### SVG element fills

Core elements rewritten to solid Win11 values (previously translucent
black/grey that resolved to wrong colors once `composite=false`):

| Element | Dark | Light |
|---|---|---|
| `window-normal` | `#202020` | `#F9F9F9` |
| `window-normal-inactive` | `#2C2C2C` | `#ECECEC` |
| `button-normal` | `#2C2C2C` | `#F3F3F3` |
| `button-focused` (hover) | `#3F3F3F` | `#E9E9E9` |
| `menu-normal` | `#2C2C2C` | `#F9F9F9` |
| `tooltip-normal` | `#2C2C2C` | `#F9F9F9` |
| `menubar-normal` | `#202020` | `#F9F9F9` |
| `header-normal` | `#2C2C2C` | `#F3F3F3` |
| `lineedit-normal` / `combo-normal` | `#2C2C2C` | `#FFFFFF` |
| `titlebar-normal` (MDI) | `#202020` | `#F9F9F9` |

### Color Schemes

Location: `color-schemes/Windows-modern{Dark,Light}.colors`

KDE color scheme files defining system-wide colors for widgets,
selections, tooltips, etc. Rewritten with Win11 values:
`ColorScheme=WindowsModernDark` / `WindowsModernLight` (the previous
`McMojave` / `McMojaveLight` leftovers were removed). Dark uses
`BackgroundNormal=32,32,32` for windows and `44,44,44` for buttons;
light uses `249,249,249` / `243,243,243`. Selection accent is
`0,120,212` in both.

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
│   ├── Windows-modernDark.colors
│   └── Windows-modernLight.colors
├── Kvantum/
│   ├── Windows-modern-dark/
│   └── Windows-modern-light/
├── icons/
│   └── windows-modern/                   # Win11 icon theme (gitignored)
├── plasma/
│   ├── desktoptheme/
│   │   ├── Windows-modern-dark/         # Dark plasma theme (165 SVGs)
│   │   └── Windows-modern-light/        # Light plasma theme (165 SVGs)
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
