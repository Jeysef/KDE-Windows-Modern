# Windows 11 Start Menu — Implementation Plan

Port the reference plasmoid `com.jeysef.windowsmodernstartmenu` (at
`/home/jeysef/Coding/kde/Windows_modern/plasmoids/startmenu/`) into this theme
as **`org.kde.windowsmodern.startmenu`**, in two phases.

- **Phase 1** — clean foundation: layouts, animations, navigation, structure.
  No folders, no launch-tracking, no command palette.
- **Phase 2** — curated feature layer: pinned/all-apps folders, launch-tracking
  context labels, command palette.

**Dropped entirely (both phases):** update checker (phones home), weather card
(network dep), shell runner (security-flavored), quick actions bar.

Reference line counts: main.qml 246, MenuRepresentation.qml 3307,
ItemGridView.qml 516, ItemMultiGridView.qml 299, ItemGridDelegate.qml 269,
ItemGridDelegateColumns.qml 260, Footer.qml 133, ConfigGeneral.qml 425,
CompactRepresentation.qml 69, AToolButton.qml 70, ActionMenu.qml 122,
WeatherCard.qml 119 (DROP), tools.js 181, UpdateChecker.js 147 (DROP).

---

## Target file tree

```
plasma/applets/org.kde.windowsmodern.startmenu/
├── metadata.json
└── contents/
    ├── config/
    │   ├── main.xml
    │   └── config.qml
    └── ui/
        ├── main.qml
        ├── CompactRepresentation.qml
        ├── MenuRepresentation.qml       # shell only
        ├── ConfigGeneral.qml
        ├── pages/
        │   ├── PinnedPage.qml
        │   ├── AllAppsPage.qml
        │   └── SearchPage.qml
        ├── components/
        │   ├── ItemGridView.qml
        │   ├── ItemGridDelegate.qml
        │   ├── ItemGridDelegateColumns.qml
        │   ├── ItemMultiGridView.qml
        │   ├── Footer.qml
        │   ├── AToolButton.qml
        │   ├── ActionMenu.qml
        │   └── SearchField.qml
        └── code/
            └── tools.js
```

**Key structural improvement:** split the monolithic 3307-line
`MenuRepresentation.qml` into a shell + `pages/` + `components/`. The shell
owns dialog positioning, search field hosting, SwipeView, footer, reset,
search-state. Each page is self-contained.

---

## Conventions (from this repo)

- **KPlugin.Id**: `org.kde.windowsmodern.startmenu` (matches siblings).
- **KPackageStructure**: `"Plasma/Applet"`. **Version**: `"1.0"`.
- **License**: `GPL-3.0-or-later`.
- **Author**: `Name: "Jeysef"`, `Email: ""`.
- **Website / BugReportUrl**: `https://github.com/yeyushengfan258/Win11OS-kde`.
- **X-Plasma-API-Minimum-Version**: `6.0`, `EnabledByDefault: true`,
  `FormFactors: ["desktop"]`.
- **X-Plasma-Provides**: `["org.kde.plasma.launchermenu"]` (replaces Kickoff).
- **Imports**: modern Qt6 style, no version numbers —
  `import QtQuick`, `import org.kde.plasma.plasmoid`,
  `import org.kde.plasma.core as PlasmaCore`,
  `import org.kde.plasma.components as PlasmaComponents3`,
  `import org.kde.kirigami as Kirigami`.
  Exceptions that still need versions:
  `import org.kde.plasma.private.kicker 0.1 as Kicker`,
  `import org.kde.kitemmodels 1.0 as KItemModels`.
  `import org.kde.plasma.plasma5support as Plasma5Support` (no version).
- **Config schema**: `contents/config/main.xml` (kcfg, group `General`).
- **Config UI**: `contents/config/config.qml` declares pages;
  `contents/ui/ConfigGeneral.qml` holds controls (per `systemtray`).
- **Font**: `"Segoe UI"` where the reference uses it (clock already does).
- **Install**: `cp -r` into `~/.local/share/plasma/plasmoids/` (no
  `kpackagetool6`). Append guarded block to `install.sh`.
- **Uninstall**: add removal line to `uninstall.sh`.

### Reference files: how to port each

- `metadata.json`, `main.qml`, `CompactRepresentation.qml`, `Footer.qml`,
  `AToolButton.qml`, `ActionMenu.qml`, `code/tools.js` — small; port nearly
  verbatim (rebrand Id/author/license, modernize imports).
- `ItemGridView.qml`, `ItemMultiGridView.qml`, `ItemGridDelegate.qml`,
  `ItemGridDelegateColumns.qml` — port nearly verbatim.
- `MenuRepresentation.qml` (3307 lines) — **do NOT copy wholesale**. Read the
  relevant section for the page/feature being ported, then write a clean
  version in `pages/*` or `components/*`. The shell keeps only: dialog
  positioning (`popupPosition`), search field hosting, SwipeView, footer,
  `reset()`, `searching` state, debounce timer, model wiring (`setModels`).
- `config/main.xml`, `config/config.qml`, `ConfigGeneral.qml` — port keys,
  drop Phase-2/extra keys for Phase 1.

---

## Phase 1 — Foundation

Goal: a working, authentic Win11 start menu skeleton with proper structure,
animations, and keyboard navigation. Usable end-to-end before Phase 2 begins.

### P1.1 — Scaffold + metadata
- Create directory tree (`pages/`, `components/`, `code/` empty).
- Write `metadata.json` per conventions. Id `org.kde.windowsmodern.startmenu`,
  Category `Application Launchers`, Icon `start-here`,
  `X-Plasma-Provides: ["org.kde.plasma.launchermenu"]`.

### P1.2 — Config schema (Phase 1 keys)
`contents/config/main.xml`, group `General`:
- `icon` (String, default `start-here`)
- `useCustomButtonImage` (Bool, false), `customButtonImage` (String, empty)
- `appsIconSize` (Int 0-3, default 1), `docsIconSize` (Int 0-3, default 1)
- `numberColumns` (Int, default 6), `numberRows` (Int, default 4)
- `displayPosition` (Int 0-2, default 0)
- `showRecentApps` (Bool, true), `showRecentDocs` (Bool, true)
- `allAppsViewMode` (Int 0-2, default 0), `allAppsSortMode` (Int 0-4, default 0)
- `favoriteApps` (String, empty), `favoriteSystemActions` (String, empty)
- `favoritesPortedToKAstats` (Bool, false)

### P1.3 — main.qml
`PlasmoidItem` with:
- `Kicker.RootModel { id: rootModel }` — flat, sorted, `showAllApps: true`,
  `showRecentApps: true`, `showRecentDocs` from config, `showPowerSession: false`.
  `Component.onCompleted` inits favorites via
  `favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)`
  and ports legacy favorites.
- Second `Kicker.RootModel { id: categoryRootModel }` — `flat: false`,
  `showAllApps: false` (category view mode).
- `Kicker.RunnerModel { id: runnerModel }` — runner selection via
  `kicker.searchRunnerFilter` ("all"/"apps"/"files"/"settings"/"actions").
  Blacklist `krunner_webshortcuts`/`webshortcuts`. NO `krunner_shell`.
- `Kicker.DragHelper`, `Kicker.ProcessRunner`, `Kicker.WindowSystem`.
- Bi-directional favorites sync via `Connections`.
- `Plasmoid.icon` resolution; "Edit Applications..." contextual action.
- `compactRepresentation`/`fullRepresentation` split (NOT the reference's
  `Qt.createQmlObject` pattern — use proper Component delegates).
- `KSvg.FrameSvgItem { id: panelSvg; imagePath: "widgets/panel-background" }`.

### P1.4 — CompactRepresentation.qml
Panel start button: `Kirigami.Icon` (source = `customButtonImage` or `icon`),
hover state, toggles `MenuRepresentation` dialog visibility, sets
`Plasmoid.status` while open. Handle panel/desktop/vertical. Wire
`plasmoid.activated`.

### P1.5 — MenuRepresentation.qml (shell)
`PlasmaCore.Dialog` with:
- `popupPosition()` for all edges + 3 display positions (0 default, 1 center,
  2 center-bottom) using `panelSvg.margins`.
- `mainItem: FocusScope` hosting `SearchField`, animated `SwipeView` (3 pages),
  `Footer`.
- `searching` state; on change switch page to Search/Pinned and reset
  `searchRunnerFilter` to "all".
- `reset()` clears search, resets page, clears focus.
- `searchDebounce` Timer (120ms) feeds `runnerModel.query`.
- `setModels()` connects `rootModel` rows to grids (row 0 recent apps,
  row 1 recent docs if enabled, row 2/1 all apps); call on
  `rootModel.refreshed` then `rootModel.refresh()`.
- Properties pages bind to: `iconSize`, `docsIconSize`, `cellSizeHeight`,
  `cellSizeWidth`, `widthComputed`.
- **Animations**: page transition slide/fade, search-field focus ring color
  transition, delegate hover/focus fade. Durations 80-180ms.

### P1.6 — components/SearchField.qml
`PC3.TextField`, Segoe UI, placeholder "Search for apps, settings, and
documents", leading `Kirigami.Icon` (`search`). Animated focus ring
(`ColorAnimation` on border.color). Key handling:
- Escape: clear search -> back to Pinned -> close menu.
- Down/Tab: focus active grid, `tryActivate(0,0)`.
- Return: on search page activate first result; else activate focused item.
- NO `>` or `/` prefix handling in Phase 1.

### P1.7 — components/Footer.qml
User avatar/name + power buttons (lock/sleep/reboot/shutdown/logout) via
`Plasma5Support.DataSource { engine: "executable" }`. Port near-verbatim.

### P1.8 — pages/PinnedPage.qml
"Pinned" header + "All apps" `AToolButton`, `ItemGridView` of favorites with
pagination (`pinnedCurrentPage`/`pinnedTotalPages`, "..." page button).
Recent-apps strip + recent-docs grid below (visibility per config). NO pinned
folders strip, NO weather card, NO smart-context label in Phase 1.

### P1.9 — pages/AllAppsPage.qml
Back button + "All apps" header. Alphabet slider (left rail, `#`-`Z`,
drag-to-scroll + big letter overlay). `ItemGridView` (list/1-col grid) or
`ItemMultiGridView` (category) based on `allAppsViewMode`. NO all-apps folders.

### P1.10 — pages/SearchPage.qml
Filter pills (All/Apps/Files/Settings/Actions) driving `searchRunnerFilter`.
`ItemMultiGridView` of runner results (3 columns). Empty-state messaging.
NO command palette, NO shell runner in Phase 1.

### P1.11 — Grid components
Port near-verbatim from reference:
- `ItemGridView.qml` — drag/drop, key nav signals
  (`keyNavUp/Down/Left/Right`), `tryActivate`, pagination hooks.
- `ItemGridDelegate.qml` — single-column delegate (icon + label).
- `ItemGridDelegateColumns.qml` — multi-column delegate.
- `ItemMultiGridView.qml` — sectioned grid for search/category.
- `AToolButton.qml`, `ActionMenu.qml`, `code/tools.js`.

### P1.12 — Config UI
`contents/config/config.qml` declares a single "General" page ->
`ConfigGeneral.qml`. Controls for Phase 1 keys (icon picker, icon size
dropdowns, columns/rows spinboxes, display position, recent toggles, all-apps
view/sort mode). Drop controls for dropped features.

### P1.13 — Install/uninstall wiring
- Append guarded `cp -r` block to `install.sh` for
  `org.kde.windowsmodern.startmenu`.
- Add removal line to `uninstall.sh`. ALSO fix the pre-existing bug: the
  `systemtray` removal line is missing — add it.

### P1.14 — Layout wiring (replace Kickoff in 3 files)
- `plasma/layout-templates/org.kde.windowsmodern.panel/contents/layout.js`
- `plasma/look-and-feel/com.github.yeyushengfan258.Windows-modern-dark/contents/layouts/org.kde.plasma.desktop-layout.js`
- `plasma/look-and-feel/com.github.yeyushengfan258.Windows-modern-light/contents/layouts/org.kde.plasma.desktop-layout.js`

In each: `panel.addWidget("org.kde.plasma.kickoff")` ->
`panel.addWidget("org.kde.windowsmodern.startmenu")`. Keep
`writeConfig("icon", "start-here")`. Drop `favoritesSystemResources` write
(not a config key for this plasmoid). Update surrounding comments.

### P1.15 — Verify + docs
- Verify: `python3 -m json.tool` on metadata.json; python/xml on main.xml;
  `qmllint6` on QML files if available (plasma-private import warnings are
  non-fatal); confirm all files referenced exist.
- Update `docs/STYLE.md`: add a `#### Start menu applet` section matching the
  existing meticulous format.
- Update `README.md`: add custom applets to the feature bullet list.
- Write `STARTMENU_TIER1_DONE` marker into `startmenu-progress.md` when Phase 1 complete.

### Phase 1 keyboard navigation (must work)
- Escape: clear search -> back to Pinned -> close menu.
- Tab/Shift+Tab: cycle search <-> active grid <-> footer.
- Arrows: within grids; Left/Right across pinned pages.
- PageUp/Down, Home/End: pagination.
- Ctrl+1..9: launch Nth pinned app (badge shown when Ctrl held).
- Return: activate first result on search page, or focused item.

---

## Phase 2 — Curated feature layer

Built on top of Phase 1's structure. Add into existing pages/components.

### P2.1 — Pinned folders
- Config keys: `pinnedFolders` (String JSON, default empty).
- `components/FolderTile.qml` — 2x2 icon mosaic + name, hover/focus ring,
  right-click context menu, drag-to-add `DropArea`.
- Popups: `createFolderOverlay`, `folderRenameOverlay`, `folderContentPopup`,
  app-picker `ListView` with checkboxes.
- Helpers: `loadFolders`/`saveFolders`/`launchFolderApp`/`displayNameForId`/
  `iconForId`.
- Add pinned folders strip to `PinnedPage`.

### P2.2 — All-apps folders
- Config keys: `allAppsFolders` (String JSON with `createdAt`).
- `allAppsComboModel` merge logic (`buildAllAppsCombo`): combine folder rows
  + non-foldered app rows, sorted per `allAppsSortMode`.
- `toggleFolderExpand`: insert/remove indented child rows.
- `lookupAppInfo` reads Kicker roles (`Qt.DisplayRole`, `Qt.DecorationRole`,
  `Qt.UserRole+1` description, `Qt.UserRole+3` favoriteId, `Qt.UserRole+10`
  url).
- Popups: `folderAppPickerPopup` (searchable), rename/delete overlays.
- Integrate into `AllAppsPage` list/grid view (not category view).

### P2.3 — Launch-frequency tracking
- Config key: `appLaunchCounts` (String JSON, `{total, buckets{}}`).
- `recordLaunch(appId)` increments current "day-slot" bucket (day 0-6 x
  slot 0-3). Legacy plain-number migration.
- `workflowScore(appId)` returns 0-10. `currentBucket()`.

### P2.4 — Smart context labels
- `contextLabel` bound property: workflow-aware ("Monday morning picks") ->
  frequency-based ("Your top picks" / "Frequently used") -> time-of-day
  fallback ("Good morning apps", "Late night").
- Drives the recent-apps strip header on `PinnedPage`.

### P2.5 — Command palette
- `/`-prefix on `SearchField`: inline calculator (`/calc` or `=`), fuzzy-matched
  command list (lock/sleep/reboot/shutdown/screenshot/settings/files/terminal/
  logout), copy-to-clipboard on Enter.
- Self-contained in `SearchPage` + a `paletteCommands` array.
- `>`-prefix shell runner stays DROPPED.

### P2.6 — Phase 2 config + docs
- Add Phase 2 keys to `main.xml`: `pinnedFolders`, `allAppsFolders`,
  `appLaunchCounts`.
- Extend `ConfigGeneral.qml` with new toggles.
- Update `docs/STYLE.md` start-menu section with Phase 2 features.
- Write `STARTMENU_TIER2_DONE` marker into `startmenu-progress.md` when Phase 2 complete.

---

## Loop usage

This plan is executed by an OpenCode Loop job. Working state lives in
`startmenu-progress.md` (root); the per-turn prompt is `startmenu-loop-prompt.md` (root).

Start Phase 1 loop:

```text
/loop 0s --name startmenu-tier1 --ask-never --safe --no-overlap --batch 5 \
  --compact-every 15 --checkpoint-only --max-runtime 4h \
  --stop-file STOP_LOOP_SM --progress-file startmenu-progress.md \
  --until STARTMENU_TIER1_DONE --prompt-file startmenu-loop-prompt.md
```

When Phase 1 is done (marker written), start Phase 2 by moving the Phase 2
backlog items in `startmenu-progress.md` into a new "Active TODO — Phase 2"
section (with `STARTMENU_TIER2_PENDING` marker at the end) and running the same
command with `--name startmenu-tier2 --until STARTMENU_TIER2_DONE`.

Controls: `STOP_LOOP_SM` file in repo root halts; `/loop-status`,
`/loop-pause startmenu-tier1`, `/loop-resume startmenu-tier1`,
`/loop-stop startmenu-tier1`.
