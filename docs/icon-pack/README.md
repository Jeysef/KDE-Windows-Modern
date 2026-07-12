# icons_v2 — AI-Assisted Icon Theme Consolidation

## Goal

Take 8 Windows-11-style icon packs installed at `~/.local/share/icons/` and produce a single curated, high-quality icon theme by letting an AI with vision capabilities select the best icons group by group.

## Architecture Overview

See `00-architecture.md` for the full pipeline with these key decisions:

- **Output layout**: Modern context-based freedesktop (`actions/`, `status/`, `apps/`, etc.)
- **Deduplication**: One canonical SVG per icon per pack — same design at 10 sizes = 1 evaluation
- **Fallback separation**: AI only compares Windows-11 packs; breeze/hicolor are mechanical only
- **Local copies**: Sources copied to `sources/` for safe dedup + normalization + in-place editing
- **Two sprite formats**: Group sprites for related icons (must match), horizontal strips for individual icons
- **Light/dark**: Hybrid — panel/status get dual variants, everything else universal

## Files

| File | Purpose |
|------|---------|
| `00-architecture.md` | **Pipeline overview, dedup strategy, fallback model, sprite formats, local copies** |
| `01-source-packs.md` | Catalog of all installed packs — structure, stats, directory layout |
| `02-freedesktop-spec.md` | Summary of the freedesktop icon naming specification |
| `03-icon-groups.md` | ~50 semantic groups for sprite-based group comparison (Format A) |
| `04-ai-prepass.md` | AI task: rank source packs per category for fallback ordering |
| `05-light-dark-strategy.md` | Hybrid light/dark mode strategy |

## Pipeline Phases

```
Phase 0: COPY & NORMALIZE
  cp sources → sources_raw/ (full backup)
  cp sources → sources/ (normalized: context-based, deduplicated, materialized)

Phase 1: INVENTORY
  Scan sources/ → which packs have which icons
  Output: 00-inventory.md

Phase 2: AI PREPASS
  AI ranks packs per category via comparison sprites
  Output: 06-fallback-order.md

Phase 3: MAIN SELECTION LOOP
  For each group: AI picks best pack
  For individual icons: AI picks per icon
  Output: 07-selection-progress.md
  
Phase 4: CONSISTENCY REVIEW
  AI reviews batches together, flags outliers

Phase 5: ASSEMBLE
  Copy chosen SVGs → output/windows-modern-v2/
  Generate index.theme

Phase 6: DARK MODE
  Generate dark variants for panel/status icons
```

## Source Packs

| Pack | SVGs | Role |
|------|------|------|
| **Eleven** | 19,467 | **Anchor** — default unless clearly worse |
| Cobalt | 16,693 | Base of Eleven |
| Windows-Eleven | 32,991 | Largest pack |
| Windows-Beuty | 32,602 | Inherits Windows-Eleven |
| Win11 | 23,033 | Large, context-based |
| We10X | 23,330 | Large, context-based |
| Fluent | 25,206 | "Flat and colorful" style |
| Fluentwin | 5,726 | Smaller, mixed SVG/PNG |

(+ dark/light variants: Eleven-Dark, Eleven-Light, Cobalt-dark, Fluent-dark, Fluent-light, We10X-dark, Win11-dark)

## Next Steps

1. **Copy sources** — `cp` icon packs into `sources_raw/` and `sources/`
2. **Normalize** — convert to context-based layout, deduplicate, materialize inheritance
3. **Generate inventory** — `00-inventory.md`
4. **Run AI prepass** — `04-ai-prepass.md`
5. **Create autonomous loop prompt** for the selection phase
6. **Begin autonomous selection loop**
