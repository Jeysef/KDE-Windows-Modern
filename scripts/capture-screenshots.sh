#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  capture-screenshots.sh — guided screenshot capture for the README
#
#  Walks you through each desktop state that showcases the theme,
#  waits for you to set it up, then captures and optimizes the shot.
#
#  Usage:
#    ./scripts/capture-screenshots.sh            # interactive, all shots
#    ./scripts/capture-screenshots.sh --list      # list the shot plan
#    ./scripts/capture-screenshots.sh 3 5         # capture only shots 3 and 5
#
#  Requirements: KDE Plasma 6 on Wayland, spectacle, ImageMagick.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"; RESET="\033[0m"
info()  { echo -e "${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
step()  { echo -e "${CYAN}  >>${RESET} $*"; }
warn()  { echo -e "${YELLOW}==>${RESET} $*"; }
err()   { echo -e "${RED}==>${RESET} $*" >&2; }

# ── Shot plan ──────────────────────────────────────────────────────
# num|filename|title|instructions
SHOTS=(
    "1|View-1.png|Dark desktop overview|Switch to the DARK global theme. Close all windows. Show the panel with taskbar icons and clock. Make sure the wallpaper is visible."
    "2|View-2.png|Light desktop overview|Switch to the LIGHT global theme. Close all windows. Same clean desktop shot showing the light panel and wallpaper."
    "3|View-3.png|Start Menu (dark)|Switch to DARK. Open the Windows Modern Start Menu — Pinned apps tab. This shows the Win11-style start menu and panel together."
    "4|View-4.png|System Tray / Quick Settings (dark)|DARK theme. Click the system tray icon on the panel to open the quick settings flyout (network, Bluetooth, volume, brightness sliders). This showcases the custom C++ system tray."
    "5|View-5.png|Window decorations (dark)|DARK theme. Open 2-3 windows (e.g. Dolphin, System Settings, a text editor) cascaded so the Win11-style title bar caption buttons (minimize/maximize/close) are clearly visible."
    "6|View-6.png|Start Menu — All Apps (light)|LIGHT theme. Open the Start Menu and switch to the All Apps page. Shows the light variant of the menu."
)

list_shots() {
    echo -e "${BOLD}Screenshot capture plan:${RESET}"
    echo ""
    for s in "${SHOTS[@]}"; do
        IFS='|' read -r num file title desc <<< "$s"
        printf "  ${GREEN}%s${RESET}  ${BOLD}%-40s${RESET}  → %s\n" "$num" "$title" "$file"
        printf "     %s\n" "$desc"
        echo ""
    done
}

# Capture one shot: wait for user, then grab the screen.
capture_one() {
    local entry="$1"
    IFS='|' read -r num file title desc <<< "$entry"

    echo ""
    info "Shot ${num}: ${BOLD}${title}${RESET}"
    echo -e "  ${CYAN}Setup:${RESET} ${desc}"
    echo ""
    read -rp "  Press ENTER when ready (or 's' to skip, 'q' to quit)... " ans

    case "${ans,,}" in
        q|quit)  warn "Aborting."; exit 0 ;;
        s|skip)  warn "Skipping shot ${num}."; return 0 ;;
    esac

    local outpath="$SRC_DIR/$file"

    # 3-second countdown so you can hide the terminal / arrange windows.
    step "Capturing in 3..."
    sleep 1; echo -ne "  2...\r"; sleep 1; echo -ne "  1...\r"; sleep 1

    # Capture fullscreen via spectacle (Wayland-safe, non-interactive).
    spectacle -b -n -f -o "$outpath"

    if [[ ! -f "$outpath" ]]; then
        err "Capture failed — no file written."
        return 1
    fi

    # Resize to max 1920px wide, optimize PNG.
    local w
    w="$(identify -format '%w' "$outpath" 2>/dev/null || echo 0)"
    if [[ "$w" -gt 1920 ]] 2>/dev/null; then
        convert "$outpath" -resize 1920x "$outpath"
        step "resized to 1920px wide"
    fi
    step "saved $file  ($(du -h "$outpath" | cut -f1))"
}

# ── Main ───────────────────────────────────────────────────────────

# Pre-flight
if [[ "$XDG_SESSION_TYPE" != "wayland" ]]; then
    warn "Session is not Wayland (detected: ${XDG_SESSION_TYPE:-unknown}). Spectacle should still work."
fi
command -v spectacle >/dev/null || { err "spectacle not found."; exit 1; }
command -v convert >/dev/null || { err "ImageMagick 'convert' not found."; exit 1; }

if [[ "${1:-}" == "--list" ]]; then
    list_shots
    exit 0
fi

# Filter to specific shot numbers if given.
if [[ $# -gt 0 ]] && [[ "$1" != "--all" ]]; then
    info "Capturing selected shots..."
    for want in "$@"; do
        found=""
        for s in "${SHOTS[@]}"; do
            IFS='|' read -r num _ _ _ <<< "$s"
            [[ "$num" == "$want" ]] && found="$s" && break
        done
        [[ -z "$found" ]] && { err "Unknown shot: $want"; exit 1; }
        capture_one "$found"
    done
else
    info "Capturing all ${#SHOTS[@]} screenshots..."
    list_shots
    echo ""
    read -rp "Press ENTER to start (or Ctrl-C to cancel)... "
    for s in "${SHOTS[@]}"; do
        capture_one "$s"
    done
fi

echo ""
info "Done! Captured files:"
for s in "${SHOTS[@]}"; do
    IFS='|' read -r num file _ _ <<< "$s"
    [[ -f "$SRC_DIR/$file" ]] && echo "    $file"
done
echo ""
echo -e "  ${BOLD}Next:${RESET} Review the images, then commit:"
echo -e "  git add View-*.png && git commit -m 'docs: update README screenshots'"
