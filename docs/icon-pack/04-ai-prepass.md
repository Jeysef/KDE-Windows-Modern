# AI Prepass — Theme Fallback Ordering

## Purpose

Before the main icon selection loop, an AI with vision capabilities evaluates each source pack's visual quality and style consistency. The result is a **per-category fallback order** — a ranked list of which packs to prefer for each type of icon.

This is NOT the final icon selection. It's a prepass to establish the fallback order for the main loop (where we'll compare actual icon sprites group by group).

## Prepass Method

For each pack, render a **reference sprite** showing key representative icons from each category. The AI evaluates these and produces a ranked order.

### Step 1: Generate Reference Sprites Per Pack

For each pack, generate one reference sprite per category showing a curated set of high-priority icons:

```
sprites/prepass/
  Eleven_status.png        → all status groups combined into one reference image
  Eleven_actions.png       → all action groups combined
  Eleven_apps.png          → all app category groups combined
  Eleven_devices.png       → device groups
  Eleven_places.png        → places groups
  Eleven_mimes.png         → MIME type groups
  
  Cobalt_status.png
  Cobalt_actions.png
  ...
  
  Windows-Eleven_status.png
  ...
```

Each sprite should show the icons at their canonical size (22px for panel, 48px for apps, etc.) in a grid with labels.

### Step 2: AI Evaluation Prompt Template

The AI receives the sprites side by side for each category:

---

> **Context:** I'm building a Windows 11 style icon theme for KDE Plasma. I have multiple source icon packs and need to rank them by quality for each icon category. The anchor pack is "Eleven" — I default to it unless another pack is clearly superior.
>
> **Category:** `{category}` (e.g., "Status — Panel/Tray Icons at 22px")
>
> **Expected style:** Windows 11 Fluent Design — rounded corners, subtle gradients, minimal flat shading, consistent stroke widths, clear silhouettes at small sizes.
>
> **Evaluation criteria:**
> 1. **Style fidelity** — How closely does this follow Windows 11 Fluent Design aesthetics?
> 2. **Visual clarity** — Are icons recognizable at their intended small size?
> 3. **Internal consistency** — Do the icons within this pack look like they belong together?
> 4. **Completeness** — How many of the expected icons does this pack actually provide (vs. inheriting from fallbacks)?
> 5. **Light/dark viability** — Do the icons have enough contrast to work on both light and dark backgrounds?
>
> **Dark/light variants:** `{note whether the pack has dark/light splits}`
>
> Please rank these packs from best to worst for this category. For each, give a brief 1-2 sentence judgment and a score (1-10).
>
> Format as:
> ```
> Rank | Pack | Score | Judgment
> 1    | ...  | 9/10  | ...
> ```

---

### Step 3: Consolidate Rankings

After running the prepass for all categories, produce a **fallback order table**:

```
## Fallback Order by Category

### Status Icons (Panel/Tray)
1. Eleven (anchor) — best Fluent style, good completeness
2. We10X — slightly different style but very complete
3. Cobalt — base of Eleven, same style, fewer icons
4. Win11 — similar to We10X
5. Windows-Eleven — different styling
6. Fluent — "flat and colorful", deviates from Fluent Design
7. Fluentwin — mixed SVG/PNG quality
8. Windows-Beuty — mostly duplicates Windows-Eleven
9. breeze — KDE default, non-Windows style
10. hicolor — last resort

### Actions Icons (Toolbar/Menu)
1. Eleven (anchor)
2. ...

### App Icons
1. Windows-Eleven — largest app set
2. Eleven
3. ...
```

### Step 4: Dark Mode Strategy

The prepass also determines whether each category needs separate dark variants:

- If a pack's icons are universally visible on both light/dark backgrounds → no dark variant needed
- If a pack's icons disappear or lose contrast on dark backgrounds → dark variant recommended
- If the anchor pack (Eleven) has dark variants → evaluate whether they're needed or if universal icons suffice

This feeds into `05-light-dark-strategy.md`.

## Categories to Evaluate

| Category | Priority | Reference Icons to Include in Sprite |
|----------|----------|--------------------------------------|
| Status (Panel/Tray) | HIGH | audio-volume-muted, battery, network-wireless-signal-excellent, bluetooth-active, dialog-error |
| Actions (Toolbar) | HIGH | edit-copy, document-open, media-playback-start, go-next, zoom-in |
| Actions (System) | HIGH | system-lock-screen, system-log-out, system-shutdown, system-reboot |
| Places (File Manager) | HIGH | folder, folder-open, user-home, user-desktop, user-trash |
| Devices (Hardware) | MEDIUM | computer, drive-harddisk, input-keyboard, printer, audio-card |
| Apps (Generic) | MEDIUM | accessories-calculator, accessories-text-editor, system-file-manager, utilities-terminal |
| MIME Types | MEDIUM | audio-x-generic, video-x-generic, image-x-generic, text-x-generic, application-x-executable, package-x-generic, application-pdf |
| Categories | LOW | applications-games, applications-internet, applications-office, preferences-system |
| Emblems | LOW | emblem-favorite, emblem-readonly, emblem-symbolic-link |
| Emotes | LOW | face-smile, face-sad, face-wink |

## Packs to Evaluate

Only evaluate Windows-11-styled packs:

| Pack | SVGs | Has Dark Variant | Has Light Variant | Universal Design |
|------|------|-------------------|---------------------|-------------------|
| **Eleven** (anchor) | 19,467 | Yes (Eleven-Dark) | Yes (Eleven-Light) | No (needs variants) |
| Cobalt | 16,693 | Yes (Cobalt-dark) | No | No |
| Windows-Eleven | 32,991 | No | No | Yes (or inherits from fallback) |
| Win11 | 23,033 | Yes (Win11-dark) | No | No |
| We10X | 23,330 | Yes (We10X-dark) | No | No |
| Fluent | 25,206 | Yes (Fluent-dark) | Yes (Fluent-light) | No |
| Fluentwin | 5,726 | No | No | Mixed quality |
| Windows-Beuty | 32,602 | No | No | Inherits Windows-Eleven |

Exclude:
- KwinDE (macOS-style)
- monday-icon-theme-main (non-Windows Monday theme)
- windows-modern (our own output, current hand-curated theme)

## Expected Output

The prepass produces:

1. **`fallback-order.md`** — Ranked list of packs per category with scores and reasoning
2. **Per-pack quality notes** — Notable strengths and weaknesses for each pack (e.g., "Fluent has great panel icons but poor app icons", "We10X excels at actions but status icons are too flat")
3. **Dark/light recommendations** — Which categories need dark variants, which can use universal icons
4. **Pack merge strategy** — Guidance for the main selection loop on when to deviate from the anchor

## How This Feeds Into the Main Selection Loop

The main loop (`icons_v2/loop-prompt.md`, to be created later) will:

1. For each icon group (from `03-icon-groups.md`), check if Eleven has all icons in the group
2. If yes → use Eleven (skip comparison unless flagged as problematic in prepass)
3. If no → fall back through the ranked order for that category
4. For high-priority groups (Status and Actions), do a sprite comparison even if Eleven has them — allow override if another pack is clearly superior
5. Record decisions in a progress checklist

The prepass rankings make steps 3-4 efficient: we try packs in order and stop at the first one that has the full group.
