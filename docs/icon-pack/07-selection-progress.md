# Selection Progress — Main Loop

Track which pack was selected for each icon group.

## Philosophy
**Eleven IS the theme.** We're filling holes in Eleven, not replacing its icons.
- Use Eleven FIRST
- Only use other packs if Eleven is MISSING entirely
- When filling gaps: Cobalt → Windows-Eleven → We10X/Win11
- Do NOT replace Eleven's icons with Win11's white rounded squares

## Legend
- **[E]** = Eleven has full group, use Eleven
- **[E+FILL]** = Eleven has most, fill gaps with fallback
- **[FILL]** = Eleven missing entirely, use fallback
- **[WIN11]** = Win11 selected (only when Eleven completely missing)
- **[WE10X]** = We10X selected (only when Eleven and Win11 missing)
- **[FW]** = Fluentwin selected (unique coverage)

## Selections

### Status Groups

| Group | Pack Selected | Method | Notes |
|-------|--------------|--------|-------|
| G-status-audio | **Eleven** | `[E]` | 4 icons. Complete in Eleven |
| G-status-battery | **Eleven** | `[E+FILL]` | 9/10 from Eleven. Missing: battery-charging (universal gap) |
| G-status-network-wireless | **Eleven** | `[E+FILL]` | 6/11 from Eleven. Filled: connected, acquiring, hotspot, offline from Win11 |
| G-status-network-wired | **Eleven** | `[E+FILL]` | 1/6 from Eleven. Filled: disconnected, unavailable from Win11; acquiring from Win11 |
| G-status-network-activity | **Win11** | `[FILL]` | 6 icons. All from Win11 (Eleven has none) |
| G-status-bluetooth | **Eleven** | `[E+FILL]` | 3/4 from Eleven. Missing: bluetooth-connected (universal gap) |
| G-status-cellular | **Win11** | `[FILL]` | 5 icons. All from Win11 (Eleven has none) |
| G-status-dialogs | **Eleven** | `[E]` | 5 icons. Complete in Eleven |
| G-status-security | **Eleven+We10X** | `[E+FILL]` | 2/3 from Eleven (medium, low). We10X: security-high |
| G-status-software | **Eleven** | `[E]` | 2 icons. Complete in Eleven |
| G-status-sync | **Win11** | `[FILL]` | 1 icon (sync-synchronizing-symbolic). sync-error missing everywhere |
| G-status-user | **Win11** | `[FILL]` | 4 icons. All from Win11 (Eleven has none) |
| G-status-weather | **Eleven** | `[E+FILL]` | 8/11 from Eleven. Filled: fog, severe-alert, snow from Win11 |
| G-status-mail | **Eleven+Win11+We10X** | `[FILL]` | Win11: unread. We10X: read, replied, attachment. Missing: signed, signed-verified (universal gap) |
| G-status-media | **Win11** | `[FILL]` | 2 icons (symbolic variants). Eleven has none |
| G-status-printer | **Win11** | `[FILL]` | 2 icons (symbolic variants). Eleven has none |
| G-status-task | **Win11** | `[FILL]` | 4 icons (symbolic variants). Eleven has none |
| G-status-misc | **Eleven** | `[E+FILL]` | 3/4 from Eleven. Filled: folder-visiting from We10X |

### Actions Groups

| Group | Pack Selected | Method | Notes |
|-------|--------------|--------|-------|
| G-actions-navigation | **Eleven** | `[E]` | 10 icons. Complete in Eleven |
| G-actions-media | **Eleven** | `[E]` | 9 icons. Complete in Eleven |
| G-actions-document | **Eleven** | `[E+FILL]` | 10/11 from Eleven. Filled: document-page-setup from Win11 (symbolic) |
| G-actions-edit | **Eleven** | `[E]` | 10 icons. Complete in Eleven |
| G-actions-format-text | **Eleven** | `[E]` | 4 icons. Complete in Eleven |
| G-actions-format-justify | **Eleven** | `[E]` | 4 icons. Complete in Eleven |
| G-actions-format-layout | **Eleven** | `[E]` | 4 icons. Complete in Eleven |
| G-actions-insert | **Eleven+Win11** | `[E+FILL]` | 3/4 from Eleven. Filled: insert-object from Win11 (symbolic) |
| G-actions-list | **Eleven** | `[E]` | 2 icons. Complete in Eleven |
| G-actions-mail | **Eleven+Win11** | `[E+FILL]` | 10/11 from Eleven. Filled: mail-send-receive from Win11 |
| G-actions-view | **Eleven** | `[E]` | 5 icons. Complete in Eleven |
| G-actions-window | **Eleven** | `[E]` | 2 icons. Complete in Eleven |
| G-actions-zoom | **Eleven** | `[E]` | 4 icons. Complete in Eleven |
| G-actions-object | **Eleven** | `[E]` | 4 icons. Complete in Eleven |
| G-actions-system | **Eleven** | `[E]` | 6 icons. Complete in Eleven |
| G-actions-misc | **Eleven+Win11** | `[E+FILL]` | 12/13 from Eleven. Filled: help-faq from Win11 |

### Places Groups

| Group | Pack Selected | Method | Notes |
|-------|--------------|--------|-------|
| G-places-core | **Eleven+We10X** | `[E+FILL]` | 4/5 from Eleven. Filled: folder-visiting from We10X |
| G-places-user | **Eleven+Win11** | `[E+FILL]` | 5/6 from Eleven. Filled: user-bookmarks from Win11 |
| G-places-folders | **Eleven** | `[E]` | 7 icons. Complete in Eleven |
| G-places-network | **Eleven+Win11** | `[E+FILL]` | 1/2 from Eleven. Filled: network-server from Win11 |

### Devices Groups

| Group | Pack Selected | Method | Notes |
|-------|--------------|--------|-------|
| G-devices-audio | **Eleven+Win11** | `[E+FILL]` | 1/2 from Eleven. Filled: audio-card, audio-input-microphone from Win11 |
| G-devices-camera | **Eleven+Win11** | `[E+FILL]` | 2/3 from Eleven. Filled: camera-web from Win11 |
| G-devices-storage | **Eleven** | `[E]` | 3 icons. Complete in Eleven |
| G-devices-input | **Eleven+Win11** | `[E+FILL]` | 3/4 from Eleven. Filled: input-gaming from Win11 |
| G-devices-media | **Eleven+Win11** | `[E+FILL]` | 1/4 from Eleven. Filled: media-flash, media-floppy from Win11; media-tape from Win11 (symbolic) |
| G-devices-network | **Eleven+Win11** | `[E+FILL]` | 2/3 from Eleven. Filled: modem from Win11 |
| G-devices-peripheral | **Eleven+Win11** | `[E+FILL]` | 7/8 from Eleven. Filled: pda from Win11 (symbolic) |

### Apps Groups

| Group | Pack Selected | Method | Notes |
|-------|--------------|--------|-------|
| G-apps-generic | **Eleven+Win11** | `[E+FILL]` | 13/15 from Eleven. Filled: accessories-dictionary from Win11, accessories-screenshot from Win11 |
| G-apps-system | **Eleven** | `[E]` | 5 icons. Complete in Eleven |

### Categories Groups

| Group | Pack Selected | Method | Notes |
|-------|--------------|--------|-------|
| G-categories-apps | **Eleven+Win11** | `[E+FILL]` | 8/12 from Eleven. Filled: development, engineering, other, science from Win11 |
| G-categories-prefs | **Eleven+Win11+Fluentwin** | `[E+FILL]` | 5/7 from Eleven. Filled: preferences-desktop from Win11, preferences-desktop-personal from Fluentwin |

### MIME Types Groups

| Group | Pack Selected | Method | Notes |
|-------|--------------|--------|-------|
| G-mimes-standard | **Eleven+Win11** | `[E+FILL]` | 14/15 from Eleven. Filled: text-x-generic-template from Win11 |
| G-mimes-archives | **Eleven** | `[E]` | 9 icons. Complete in Eleven |
| G-mimes-audio | **Eleven+Win11** | `[E+FILL]` | 6/10 from Eleven. Filled: audio-ogg, audio-aac from Win11. Missing: audio-opus, audio-x-matroska (universal gap) |
| G-mimes-video | **Eleven+Win11** | `[E+FILL]` | 6/9 from Eleven. Filled: video-x-flv, video-quicktime, video-x-ogm+ogg from Win11 |
| G-mimes-image | **Eleven+Win11** | `[E+FILL]` | 7/11 from Eleven. Filled: image-webp, image-x-xcf, image-x-psd from Win11. Missing: image-heif (universal gap) |
| G-mimes-text | **Eleven+Win11** | `[E+FILL]` | 8/13 from Eleven. Filled: text-x-log, text-x-readme, text-x-changelog, text-x-source, text-x-csrc, text-x-chdr, text-x-c++src from Win11. Missing: text-yaml (universal gap) |
| G-mimes-office | **Eleven** | `[E]` | 12 icons. Complete in Eleven |
| G-mimes-code | **Eleven+Win11** | `[E+FILL]` | 6/10 from Eleven. Filled: text-x-csrc, text-x-chdr, text-x-c++src, application-x-php from Win11 |
| G-mimes-font | **Eleven** | `[E]` | 4 icons. Complete in Eleven |
| G-mimes-disk | **Eleven** | `[E]` | 4 icons. Complete in Eleven |

### Emblems Groups

| Group | Pack Selected | Method | Notes |
|-------|--------------|--------|-------|
| G-emblems-states | **Eleven+Win11** | `[E+FILL]` | 3/10 from Eleven. Filled: default, favorite, important, readonly, shared, system from Win11. Missing: emblem-synchronized (universal gap) |
| G-emblems-dirs | **Eleven+Win11** | `[E+FILL]` | 1/4 from Eleven (photos). Filled: documents, downloads from Win11. Missing: emblem-mail (universal gap) |

### Emotes Groups

| Group | Pack Selected | Method | Notes |
|-------|--------------|--------|-------|
| G-emotes-faces | **Win11** | `[FILL]` | 21 icons. All from Win11 (Eleven has none) |

### Animations Groups

| Group | Pack Selected | Method | Notes |
|-------|--------------|--------|-------|
| G-animations-process | **Win11** | `[FILL]` | 1 icon (process-idle). process-working missing (universal gap) |

---

## Batch Consistency Reviews

### Review #1 (Groups 1-10): Status + Actions (HIGH priority)

**Pack distribution:**
- G-status-audio: Eleven
- G-status-battery: Eleven (9/10)
- G-status-network-wireless: Eleven (6/11)
- G-status-network-wired: Eleven (1/6)
- G-status-network-activity: Win11
- G-actions-navigation: Eleven
- G-actions-media: Eleven
- G-actions-document: Eleven (10/11)
- G-actions-edit: Eleven
- G-actions-system: Eleven

**Consistency assessment:** CONSISTENT ✓
- All status groups use Eleven as base
- All actions groups use Eleven
- Fills are minimal and match Eleven's style where possible

### Review #2 (Groups 11-20): Places + Remaining Status + Actions

**Pack distribution:**
- G-places-core: Eleven+We10X (fallback)
- G-places-user: Eleven+Win11 (fallback)
- G-mimes-standard: Eleven+Win11 (fallback)
- G-status-network-wired: Eleven+Win11 (fallback)
- G-status-network-activity: Win11 (fill)
- G-status-cellular: Win11 (fill)
- G-status-security: Eleven+We10X (fallback)
- G-status-software: Eleven
- G-status-sync: Win11 (fill)
- G-status-user: Win11 (fill)

**Consistency assessment:** CONSISTENT ✓
- Places groups use Eleven base + fallback for missing
- Remaining status groups use Eleven base where available
- Win11 fills only used when Eleven has NO icons for that group

---

## Universally Missing Icons (no Tier 1 pack has these)

These icons are missing from ALL 8 source packs and cannot be provided:
- `battery-charging.svg` (generic)
- `network-wireless-encrypted`
- `network-wired-connected`
- `bluetooth-connected`
- `sync-error`
- `mail-signed.svg` (non-symbolic)
- `mail-signed-verified.svg` (non-symbolic)
- `audio-opus`, `audio-x-matroska`
- `image-heif`
- `text-yaml`
- `emblem-synchronized`
- `emblem-mail`
- `process-working` (PNG only, no SVG)
- `media-tape` (SVG only, PNG exists)
- `pda` (SVG only, PNG exists)
- `document-page-setup` (SVG only, PNG exists)
- `insert-object` (SVG only, PNG exists)

---

## Total Output: 311 icons across 10 contexts

| Context | Count |
|---------|-------|
| status | 78 |
| actions | 68 |
| mimetypes | 45 |
| devices | 28 |
| places | 20 |
| apps | 20 |
| categories | 19 |
| emblems | 11 |
| emotes | 21 |
| animations | 1 |
| **TOTAL** | **311** |
