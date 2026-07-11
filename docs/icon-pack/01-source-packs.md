# Source Icon Packs Catalog

All packs live at `~/.local/share/icons/`. System packs (`/usr/share/icons/`) are not Windows-11-styled and serve only as ultimate fallbacks (breeze, hicolor via index.theme inheritance).

## Anchor Pack

**Eleven** is the anchor — we default to its icons unless another pack is clearly superior.

| Pack | SVGs | PNGs | Dir Structure | Inherits | Comment |
|------|------|------|---------------|----------|---------|
| Eleven | 19,467 | 0 | size-based (8,16,22,24,32,48,64 + @2x) | Cobalt,breeze,hicolor | **ANCHOR** |
| Eleven-Dark | 7,950 | 0 | size-based | Cobalt-dark,breeze-dark,hicolor | Dark overrides for Eleven |
| Eleven-Light | 813 | 0 | size-based | Cobalt,breeze,hicolor | Light overrides, very small |

Size-based means: `16/actions/`, `22/panel/`, `48/apps/`, etc. Each size has subdirs per context.

## Primary Source Packs (Windows 11 style)

| Pack | SVGs | PNGs | Dir Structure | Inherits | Comment |
|------|------|------|---------------|----------|---------|
| Cobalt | 16,693 | 0 | size-based | breeze,hicolor | Base for Eleven |
| Cobalt-dark | 8,987 | 0 | size-based | breeze-dark,hicolor | Dark variant |
| Windows-Eleven | 32,991 | 12 | context-based | *(none)* | Largest pack, no inherit |
| Windows-Beuty | 32,602 | 12 | context-based | Windows-Eleven,breeze-dark | Inherits Windows-Eleven |
| Win11 | 23,033 | 6 | context-based | hicolor,breeze | |
| Win11-dark | 12,173 | 0 | context-based | hicolor,breeze | |
| We10X | 23,330 | 6 | context-based | hicolor,breeze | |
| We10X-dark | 12,173 | 0 | context-based | hicolor,breeze | |
| Fluent | 25,206 | 0 | multi-size (16,22,24,32,256 + @2x/@3x) | hicolor | "Flat and colorful" |
| Fluent-dark | 11,982 | 0 | multi-size | hicolor | |
| Fluent-light | 3,075 | 0 | multi-size | hicolor | |
| Fluentwin | 5,726 | 7,090 | dimension-based (16x16,24x24,etc.) | breeze,gnome,Papirus,hicolor | Mixed SVG+PNG |

Context-based means: `actions/`, `apps/`, `status/`, `mimes/` (not `mimetypes/`), etc. + `@2x` variants.

## Non-Windows Packs (excluded from comparison)

| Pack | SVGs | PNGs | Reason |
|------|------|------|--------|
| KwinDE | 5,306 | 6,863 | macOS-style, not Windows 11 |
| monday-icon-theme-main | 80,286 | 2 | Monday icon theme, not Windows-style. No index.theme. |

## System Fallbacks (ultimate fallback only)

| Pack | Used by |
|------|---------|
| breeze | Default KDE theme — high quality but non-Windows style |
| breeze-dark | |
| hicolor | Freedesktop reference — minimal, ugly, last resort |
| Adwaita | GNOME default — non-Windows |
| oxygen | Legacy KDE4 style |
| Bluecurve | Legacy |

## Key Structural Differences

### Eleven/Cobalt (size-based)
```
16/actions/    → 2,308 action icons at 16px
22/panel/      → 140 panel icons at 22px
48/apps/       → 1,133 app icons at 48px
...
symbolic/      → monochrome variants
```

### We10X/Win11/Windows-Eleven/Windows-Beuty (context-based)
```
actions/       → all action icons (size as SVG viewBox)
apps/          → all app icons
status/        → all status icons
mimes/         → all MIME type icons (note: "mimes" not "mimetypes")
places/        → folder/place icons
devices/       → hardware icons
...
@2x variants per context
```

### Fluent (multi-size with @3x)
```
16/actions/     → 16px actions
16@2x/actions/  → HiDPI 16px
16@3x/actions/  → 3x scale 16px
22/actions/
...
256/            → 256px icons
scalable/       → scalable SVGs
symbolic/       → monochrome
```

### Fluentwin (dimension-based, mixed SVG+PNG)
```
16x16/          → PNG + some SVG
24x24/
32x32/
48x48/
128x128/
256x256/
512x512/
scalable/       → SVG only
symbolic/       → monochrome SVG
```

## Dark/Light Variant Strategy

Packs with explicit dark/light splits:
- **Eleven** + Eleven-Dark + Eleven-Light
- **Cobalt** + Cobalt-dark
- **Fluent** + Fluent-dark + Fluent-light
- **We10X** + We10X-dark
- **Win11** + Win11-dark

Packs with single universal design: Windows-Eleven, Windows-Beuty, Fluentwin

For the output theme, we have two strategies — see `05-light-dark-strategy.md`.

## Selection Priority

Default fallback order for icon groups (to be refined by AI prepass — see `04-ai-prepass.md`):

```
1. Eleven           (anchor — pick unless clearly worse)
2. Cobalt           (base of Eleven, may have icons Eleven lacks)
3. Windows-Eleven   (largest pack, context-based)
4. Win11            (well-stocked)
5. We10X            (similar to Win11)
6. Fluent           (different style, "flat and colorful")
7. Fluentwin        (smaller, mixed SVG/PNG)
8. Windows-Beuty    (inherits Windows-Eleven, mostly duplicates)
9. [dark variants]  (used when dark-mode-specific variant needed)
10. breeze           (system fallback, non-Windows style)
11. hicolor          (last resort)
```

This order will be refined by the AI visual prepass per category.
