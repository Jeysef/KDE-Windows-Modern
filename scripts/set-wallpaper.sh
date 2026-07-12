#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  set-wallpaper.sh — set the desktop wallpaper to Windows-modern
#
#  Plasma's look-and-feel apply mechanism does not set the wallpaper
#  (the [Wallpaper] entry in defaults is informational only). This
#  script uses plasma-apply-wallpaperimage to set it. The wallpaper
#  package auto-switches between its images/ (light) and images_dark/
#  (dark) variants based on the active color scheme.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

WALLPAPER_ID="Windows-modern"

APPLY_TOOL="plasma-apply-wallpaperimage"

if ! command -v "$APPLY_TOOL" &>/dev/null; then
    echo "$APPLY_TOOL not found — cannot set wallpaper automatically." >&2
    echo "Set it manually: right-click desktop → Configure Desktop → Wallpaper." >&2
    exit 0
fi

# Locate the installed wallpaper package directory.
WALLPAPER_DIR=""
for dir in \
    "$HOME/.local/share/wallpapers/$WALLPAPER_ID" \
    "/usr/share/wallpapers/$WALLPAPER_ID"; do
    if [ -d "$dir" ]; then
        WALLPAPER_DIR="$dir"
        break
    fi
done

if [ -z "$WALLPAPER_DIR" ]; then
    echo "Wallpaper package '$WALLPAPER_ID' not found." >&2
    echo "Install it first: ./install.sh themes" >&2
    exit 1
fi

"$APPLY_TOOL" "$WALLPAPER_DIR"

echo "Wallpaper set to $WALLPAPER_ID (auto-switches light/dark with color scheme)."
