#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  update-previews.sh — regenerate global theme previews from screenshots
#
#  Uses View-10 (dark start menu + windows) and View-11 (light start menu +
#  windows) as the source for the global theme previews shown in System
#  Settings, since they showcase the panel, window decorations, start menu,
#  and wallpaper all at once.
#
#  Usage: ./scripts/update-previews.sh
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BOLD="\033[1m"; GREEN="\033[32m"; CYAN="\033[36m"; RED="\033[31m"; RESET="\033[0m"
info() { echo -e "${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
step() { echo -e "${CYAN}  >>${RESET} $*"; }
err()  { echo -e "${RED}==>${RESET} $*" >&2; }

CONVERT="$(command -v magick || command -v convert)"
[[ -z "$CONVERT" ]] && { err "ImageMagick not found."; exit 1; }

DARK_SRC="$SRC_DIR/View-10.png"
LIGHT_SRC="$SRC_DIR/View-11.png"

DARK_DIR="$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark/contents/previews"
LIGHT_DIR="$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.light/contents/previews"

# ── Dark ───────────────────────────────────────────────────────────
if [[ -f "$DARK_SRC" ]]; then
    info "Dark global theme previews (from $DARK_SRC)..."
    "$CONVERT" "$DARK_SRC" -quality 90 -strip "$DARK_DIR/fullscreenpreview.jpg"
    "$CONVERT" "$DARK_SRC" -resize 172x105^ -gravity center -extent 172x105 "$DARK_DIR/preview.png"
    step "fullscreenpreview.jpg + preview.png"
else
    err "Missing $DARK_SRC — run ./scripts/capture-screenshots.sh first."
    exit 1
fi

# ── Light ──────────────────────────────────────────────────────────
if [[ -f "$LIGHT_SRC" ]]; then
    info "Light global theme previews (from $LIGHT_SRC)..."
    "$CONVERT" "$LIGHT_SRC" -quality 90 -strip "$LIGHT_DIR/fullscreenpreview.jpg"
    "$CONVERT" "$LIGHT_SRC" -resize 172x105^ -gravity center -extent 172x105 "$LIGHT_DIR/preview.png"
    "$CONVERT" "$LIGHT_SRC" -resize 172x105^ -gravity center -extent 172x105 "$LIGHT_DIR/splash.png"
    step "fullscreenpreview.jpg + preview.png + splash.png"
else
    err "Missing $LIGHT_SRC — run ./scripts/capture-screenshots.sh first."
    exit 1
fi

echo ""
info "Done. Reinstall to see them in System Settings:"
echo "  ./install.sh lookfeel"
