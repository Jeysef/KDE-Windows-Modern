# Architecture Decisions

Key architectural choices for the icon theme consolidation pipeline.

---

## 1. Output Directory Layout: Modern Freedesktop

The output theme uses the **context-based** freedesktop layout (what We10X, Win11, Windows-Eleven use), not the legacy size-based layout (what Eleven/Cobalt use).

```
output/windows-modern-v2/
  index.theme
  actions/              # scalable SVGs, default toolbar size
  actions@2x/           # HiDPI variants (2x scale)
  animations/
  apps/                 # scalable SVGs, default launcher size
  apps@2x/
  categories/
  categories@2x/
  devices/
  devices@2x/
  emblems/
  emotes/
  mimetypes/
  mimetypes@2x/
  places/
  places@2x/
  status/               # panel + dialog status icons
  status@2x/
  symbolic/             # actions/symbolic, status/symbolic, etc.
```

### Why context-based?
- Modern standard (Papirus, Tela, We10X, Win11 all use it)
- Cleaner — one file per icon, no duplicate SVGs at different pixel sizes
- Scalable SVGs handle all sizes via `viewBox`
- Easier for the AI to work with: 1 file = 1 icon decision, not 10 copies of the same icon at different sizes

### Mapping from size-based packs (Eleven, Cobalt):

| Size-based path | Context-based output |
|-----------------|---------------------|
| `22/actions/edit-copy.svg` | `actions/edit-copy.svg` |
| `16/panel/audio-volume-muted.svg` | `status/audio-volume-muted.svg` |
| `48/apps/firefox.svg` | `apps/firefox.svg` |
| `22/status/` + `22/panel/` | Both → `status/` |

Take the largest/highest-quality SVG as the canonical version, since it's scalable.

---

## 2. Deduplication Strategy

### Problem
Each source pack stores the same icon at multiple sizes (16px, 22px, 24px, 32px, 48px, 64px + @2x variants). That's 10+ copies of the same design. The AI should not evaluate the same icon 10 times.

### Solution: Canonical Set Per Pack

For each source pack, extract a **canonical set** — one SVG per unique icon name, at its highest quality available size:

| Icon Context | Preferred Size For Canonical | Rationale |
|-------------|------------------------------|-----------|
| **Panel/Status** | 22px or 24px | This is the actual display size; small icons need pixel perfection |
| **Actions** | 22px or scalable | Toolbar default |
| **Apps** | 48px or 64px or scalable | Launcher default |
| **Devices** | 48px or 64px | Large enough to see detail |
| **Places** | 48px or 64px | File manager default |
| **MIME Types** | 64px or scalable | File manager default |
| **Emblems** | 16px or 22px | Actual display size |
| **Emotes** | 22px or 24px | Chat display size |
| **Categories** | 32px or 48px | Menu display size |
| **Animations** | 22px or 24px | Panel display size |

For packs that have `scalable/` directories, prefer those. For packs that only have fixed sizes, pick the largest one closest to the canonical size.

### Implementation

Script walks each source pack directory, for each unique icon name + context, keeps only the canonical size copy in the local working copy. Everything else gets a symlink (to avoid breaking index.theme references) or is discarded.

---

## 3. Fallback Separation

### Problem
Some packs (Fluentwin, Windows-Beuty) inherit from breeze, gnome, hicolor. At runtime, the system resolves fallbacks through `Inherits=`. But during AI evaluation, we only want to compare Windows-11-styled icons against each other. breeze and hicolor should never appear in comparison sprites — they're a mechanical fallback, not a stylistic choice.

### Solution: Tiered Source Model

```
Tier 1: Windows-11 packs (compared by AI)
  Eleven, Cobalt, Windows-Eleven, Win11, We10X, Fluent, Fluentwin, Windows-Beuty
  (+ their dark/light variants)

Tier 2: System fallbacks (mechanical only, never shown to AI)
  breeze, breeze-dark

Tier 3: Ultimate fallback (spec-compliant, never shown to AI)
  hicolor
```

### How it works in practice

For any given icon group:
1. Check if **Eleven** has the full group → use it
2. If not, check the next ranked Tier 1 pack → use it
3. If NO Tier 1 pack has the icon → mechanically fall back to breeze (no AI involvement)
4. If breeze doesn't have it → last resort hicolor (bad but spec-compliant)

The AI never sees breeze or hicolor icons. They're not Windows-11-styled and would only confuse the aesthetic judgment.

---

## 4. Sprite Formats

Two different sprite layouts for two different comparison scenarios:

### Format A: Group Sprite (for semantically related icons)

Used when comparing groups from `03-icon-groups.md` (e.g., all battery states, all WiFi states).

**Layout:** Grid, one row per source pack

```
┌──────────────────────────────────────────────────────────────┐
│  Eleven battery group                                        │
│  [battery] [battery-low] [battery-caution] [battery-full] [charging] │
├──────────────────────────────────────────────────────────────┤
│  Cobalt battery group                                        │
│  [battery] [battery-low] [battery-caution] [battery-full] [charging] │
├──────────────────────────────────────────────────────────────┤
│  Windows-Eleven battery group                                │
│  ...                                                         │
└──────────────────────────────────────────────────────────────┘
```

**AI prompt for group sprites:**
> This sprite compares the battery status icon group across N source packs. Each row shows all battery state icons from one pack. These appear at 22px in the system tray. Which pack has the best overall group in terms of Windows 11 style, visual clarity at small size, and internal consistency? Rank them. Default to Eleven (row 1) unless another pack is clearly superior.

### Format B: Per-Icon Horizontal Sprite (for individual icons)

Used for standalone icons that don't belong to a group (branded apps, one-off mimetypes, misc actions).

**Layout:** Single horizontal strip showing the same icon concept from all packs

```
┌──────────────────────────────────────────────────────────────┐
│  "firefox" icon comparison                                   │
│  [Eleven] [Cobalt] [W-Eleven] [Win11] [We10X] [Fluent] [Fluentwin] [W-Beuty] │
└──────────────────────────────────────────────────────────────┘
```

**AI prompt for horizontal sprites:**
> This strip shows the "firefox" application icon from 8 source packs (left to right: Eleven, Cobalt, Windows-Eleven, Win11, We10X, Fluent, Fluentwin, Windows-Beuty). These appear at 48px in the application menu. Which single icon is best? Default to Eleven (leftmost) unless another is clearly superior. Rate each as: PICK / OK (acceptable but not best) / SKIP (bad, wrong style, or missing/fallback).

### Key rule for both formats

The AI only sees 8 columns/rows (the Tier 1 Windows packs). breeze and hicolor are NEVER included in comparison sprites. If a pack has no icon for this group/concept, use a placeholder (gray X) so the AI knows it's missing rather than bad.

---

## 5. Local Working Copies

### Why copy?
- Safe: don't modify the system-installed themes
- Clean: deduplicate, normalize, and preprocess without affecting the originals
- Reproducible: everything in one project directory
- Edit-in-place: the selection loop can move/copy chosen SVGs directly into the output theme

### Directory structure for working copies

```
icons_v2/
  sources/                    # local working copies
    Eleven/                   # deduplicated canonical copy
      actions/
        edit-copy.svg         # only one copy per icon name
        ...
      apps/
      status/                 # panel icons merged into status
      ...
    Cobalt/
      ...
    Windows-Eleven/
      ...
    Win11/
      ...
    We10X/
      ...
    Fluent/
      ...
    Fluentwin/
      ...
    Windows-Beuty/
      ...
  
  sources-raw/                # full copies of originals (reference only)
    Eleven/                   # complete original with all sizes
    ...

  output/
    windows-modern-v2/        # the assembled output theme
      index.theme
      actions/
      apps/
      ...
```

### Processing on copy

When copying from `~/.local/share/icons/` to `sources/`, perform:
1. **Directory normalization**: Convert size-based → context-based (e.g., `22/actions/` → `actions/`)
2. **Deduplication**: Keep only canonical size per icon context
3. **SVG normalization**: Ensure valid `viewBox`, add `xmlns`, normalize whitespace
4. **Merge panel + status**: Panel icons (`22/panel/`) are a subset of status — merge them into `status/`

`Sources-raw/` keeps the full unmodified copies as reference in case something goes wrong.

### Pack virtualization

For packs that differ from the source (e.g., "Windows-Beuty inherits Windows-Eleven"), we need to decide how to handle this in the working copy:

- **Windows-Beuty**: Explicitly inherits `Windows-Eleven,breeze-dark`. For our purposes, Windows-Beuty only contributes its own unique icons. All inherited icons come from Windows-Eleven or fallbacks per the tier system.
- **Eleven**: Inherits `Cobalt,breeze,hicolor`. For our working copy, we can either materialize the Cobalt icons into Eleven's directory (so Eleven's copy is self-contained) or treat Eleven+Cobalt as a combined set during evaluation.

**Decision: Materialize inheritance.** For each pack in the working copy, resolve all inherited icons so each `sources/{pack}/` directory is self-contained. This means:
- `sources/Eleven/` = Eleven's own icons + Cobalt's icons (materialized) + any unique icons it has
- But DON'T materialize breeze/hicolor — those stay as mechanical fallbacks

This makes the AI comparison fair — when comparing Eleven vs. We10X, both have their full icon set available without hidden inheritance.

---

## 6. Evaluation Pipeline Summary

```
Phase 0: COPY
  cp ~/.local/share/icons/{Pack}/ → icons_v2/sources-raw/{Pack}/
  cp ~/.local/share/icons/{Pack}/ → icons_v2/sources/{Pack}/
  Normalize: size-based → context-based
  Deduplicate: keep canonical size only
  Materialize: resolve inherited icons within Tier 1

Phase 1: INVENTORY
  Scan sources/{Pack}/ → 00-inventory.md
  Every icon name × which packs have it
  Identify gaps (icons present in NO Tier 1 pack → must use breeze/hicolor)

Phase 2: AI PREPASS
  For each category in 04-ai-prepass.md:
    Generate comparison sprites (Format A: group sprites)
    AI ranks packs per category
    Output → 06-fallback-order.md

Phase 3: MAIN SELECTION LOOP
  For each icon group (03-icon-groups.md):
    If Eleven has the full group → pick Eleven (skip comparison unless flagged)
    If Eleven is missing some → fall back through ranked order
    If no Tier 1 pack has it → mark for breeze/hicolor fallback
  For individual icons (non-grouped):
    Generate Format B: horizontal sprites
    AI picks per icon

Phase 4: CONSISTENCY REVIEW
  AI reviews batches of picks together
  Flags inconsistent selections

Phase 5: ASSEMBLE
  Copy chosen SVGs from sources/{Pack}/ → output/windows-modern-v2/
  Generate index.theme
  Handle symlinks (icon aliases like audio-volume → audio-volume-high)

Phase 6: DARK MODE
  Per 05-light-dark-strategy.md:
    Panel/status icons → generate dark variants
    Everything else → ensure currentColor compatibility
```
