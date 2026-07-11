# Light/Dark Mode Strategy

## The Problem

KDE Plasma supports both light and dark color schemes. Icons need to be visible on both. A white icon disappears on a white panel; a black icon disappears on a dark panel.

## Two Strategies

### Strategy A: Dual Variants (Current)

Maintain separate icon files for light and dark mode, with the system choosing based on the current color scheme. This is what Eleven/Eleven-Dark do: they're separate icon themes that KDE switches between when the user changes color scheme.

**How it works:**
- Light mode theme: icons have dark strokes/fills, visible on light backgrounds
- Dark mode theme: icons have light strokes/fills, visible on dark backgrounds
- KDE's `FollowsColorScheme=true` in `index.theme` triggers the switch

**Pros:**
- Icons always look optimal on whatever background
- Can use pure white or pure black strokes without compromise

**Cons:**
- Double the icon count (or at least double the variants that differ)
- Maintenance burden — two sets to curate
- Some packs only have one variant

### Strategy B: Universal Icons (Recommended)

Use icons that work on both light and dark backgrounds. This is achieved by:
- Medium-toned fills with outline strokes
- Using the user's accent color or system color scheme colors (`currentColor` in SVG)
- Semi-transparent elements that work on any background

**How it works:**
- SVG icons use `currentColor` for key elements, inheriting from the system color scheme
- Alternatively, use `fill="#808080"` (medium gray) outlines so the icon shape is visible on both extremes
- Icons with both dark and light elements (e.g., a dark phone silhouette with a light screen)

**Pros:**
- Single icon set, no duplication
- Simpler maintenance
- Consistent across color scheme changes (no icon swap delay)

**Cons:**
- Some icons naturally need color (e.g., battery with green/yellow/red states) and can't be purely `currentColor`
- Design compromise — icons optimized for neither extreme, just "good enough" for both
- May not look as striking in either mode

### Strategy C: Hybrid (Practical)

Some icon categories use universal icons, others use dual variants:

| Category | Strategy | Reason |
|----------|----------|--------|
| **Status/Panel (tray)** | **Dual variants** | These are critical — battery, WiFi, Bluetooth have color states that can't be universal. Moreover, they're small and need maximum contrast |
| **Actions (toolbar)** | Universal (`currentColor`) | Monochrome toolbar icons naturally inherit color scheme |
| **Symbolic icons** | Universal | Monochrome by definition |
| **Apps** | Mostly universal | App icons have their own branding colors anyway |
| **Devices** | Universal | These are large and have enough internal contrast |
| **Places** | Universal | Folder colors are distinct enough on both |
| **MIME Types** | Universal | These have distinct shapes and colors |
| **Emblems** | Universal | Already designed as overlays |
| **Emotes** | Universal | Always on light chat backgrounds |

## Recommended Approach: Hybrid Strategy C

We'll produce a **single icon theme** (`windows-modern-v2`) that:
1. Uses `currentColor` for monochrome elements (actions, symbolic icons, some status)
2. Has colorful but high-contrast designs for status icons that need color states (battery, network)
3. For status icons from packs with dark variants (Eleven-Dark, etc.): if the pack already provides optimized dark versions, we include them in a `-dark` override set within the theme
4. For status icons from universal packs (Windows-Eleven): use as-is if they have sufficient contrast on both backgrounds

## Implementation Detail

### For `currentColor` icons:
- SVG files should use `fill="currentColor"` instead of hardcoded colors
- KDE tints these to match the system color scheme automatically

### For dual-variant icons:
- The main theme contains the light-mode versions (dark strokes on light bg)
- A `windows-modern-v2-dark` sub-theme contains dark-mode overrides (light strokes on dark bg)
- The dark theme inherits from the main theme, only overriding icons that need dark variants

### Verifying contrast:
The AI can evaluate contrast by showing each icon on both `#eff0f1` (typical Breeze light panel) and `#31363b` (typical Breeze dark panel) backgrounds.

## Decision

**Use Hybrid Strategy C.** This is the practical middle ground:
- Maximum quality for the most visible icons (panel/tray)
- Simplicity for everything else
- Matches what real icon themes (including Eleven) actually do

The exact split will be refined after the AI prepass (`04-ai-prepass.md`) determines which categories have contrast issues on dark backgrounds.
