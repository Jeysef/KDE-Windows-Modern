# Progress — Windows 11 Start Menu Port

## Current Goal

Port the reference plasmoid `com.jeysef.windowsmodernstartmenu` into this theme
as `org.kde.windowsmodern.startmenu`. **Phase 1 only** (foundation).
Full design: `docs/STARTMENU_PLAN.md`. Reference source:
`/home/jeysef/Coding/kde/Windows_modern/plasmoids/startmenu/com.jeysef.windowsmodernstartmenu/`

## Agent Rules

- Do not ask questions unless truly blocked. Make reasonable assumptions.
- Follow conventions in `docs/STARTMENU_PLAN.md` exactly (Id, license, imports).
- Read the reference file for each task before writing the ported version.
- Do NOT copy `MenuRepresentation.qml` wholesale — split into shell + pages.
- Mark completed TODOs with `[x]`. Add follow-up TODOs when discovered.
- After each file, sanity-check it (JSON validity, balanced braces, referenced
  files exist). Run `qmllint6` on QML files if available (plasma-private
  import warnings are non-fatal — only fix real syntax/type errors).
- Do NOT git commit. Only the user commits. Do NOT run destructive commands.
- When ALL Phase 1 TODOs are `[x]`, write the line `STARTMENU_TIER1_DONE`
  on its own line at the end of this file, then stop.

## Active TODO — Phase 1

### Scaffold
- [x] P1.1 Create `plasma/applets/org.kde.windowsmodern.startmenu/` tree
      (contents/config, contents/ui/pages, contents/ui/components,
      contents/ui/code) + write `metadata.json` per conventions.
- [x] P1.2 Write `contents/config/main.xml` (Phase 1 keys only, group General).
- [x] P1.3 Write `contents/ui/main.qml` (PlasmoidItem + Kicker models +
      favorites sync + panelSvg). Rebrand Id, modernize imports.

### Core UI
- [x] P1.4 Write `contents/ui/CompactRepresentation.qml` (start button).
- [x] P1.5 Write `contents/ui/MenuRepresentation.qml` shell (dialog,
      popupPosition, SearchField host, animated SwipeView, Footer host, reset,
      searching state, debounce timer, setModels).
- [x] P1.6 Write `contents/ui/components/SearchField.qml` (animated focus
      ring, key handling — no `/` or `>` prefixes in Phase 1).
- [x] P1.7 Write `contents/ui/components/Footer.qml` (user + power buttons).

### Pages
- [x] P1.8 Write `contents/ui/pages/PinnedPage.qml` (pinned grid + pagination
      + recent apps strip + recent docs grid; NO folders/weather/context).
- [x] P1.9 Write `contents/ui/pages/AllAppsPage.qml` (alphabet slider +
      grid/category view; NO folders).
- [x] P1.10 Write `contents/ui/pages/SearchPage.qml` (filter pills + results
      grid + empty state; NO command palette).
- [x] P1.11 Port `components/ItemGridView.qml`, `ItemGridDelegate.qml`,
      `ItemGridDelegateColumns.qml`, `ItemMultiGridView.qml`,
      `AToolButton.qml`, `ActionMenu.qml`, `code/tools.js` near-verbatim.

### Config UI
- [x] P1.12 Write `contents/config/config.qml` + `contents/ui/ConfigGeneral.qml`
      (Phase 1 controls only).

### Wiring
- [x] P1.13 Append install block to `install.sh`; add startmenu removal line
      to `uninstall.sh` AND fix the missing systemtray removal line.
- [x] P1.14 Replace `org.kde.plasma.kickoff` with
      `org.kde.windowsmodern.startmenu` in all 3 layout.js files (panel
      template + dark/light look-and-feel). Drop `favoritesSystemResources`
      write. Update comments.

### Verify + docs
- [x] P1.15 Verify (JSON/XML validity, qmllint6 if available, file existence);
      update `docs/STYLE.md` (start menu section); update `README.md`
      (applets bullet); write `STARTMENU_TIER1_DONE` at end of this file.

## Completed

- [x] Investigation of reference plasmoid + this theme's conventions.
- [x] Two-phase plan written to `docs/STARTMENU_PLAN.md`.

## Backlog — Phase 2 (do NOT start until Phase 1 marker is written)

- [ ] P2.1 Pinned folders (config + FolderTile + popups + helpers).
- [ ] P2.2 All-apps folders (combo model + expand/collapse + app picker).
- [ ] P2.3 Launch-frequency tracking (recordLaunch/workflowScore/currentBucket).
- [ ] P2.4 Smart context labels (contextLabel bound property).
- [ ] P2.5 Command palette (`/`-prefix calculator + command list).
- [ ] P2.6 Phase 2 config keys + docs update + `STARTMENU_TIER2_DONE`.

## Blocked

- None.

## Stop Markers

(When all P1.1-P1.15 are checked and no non-blocked items remain, replace
`STARTMENU_TIER1_PENDING` with `STARTMENU_TIER1_DONE` on its own line.)

STARTMENU_TIER1_DONE
