#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  Shared library — sourced by all install-*.sh scripts
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"

BOLD="\033[1m"; GREEN="\033[32m"; BLUE="\033[34m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"; RESET="\033[0m"
info()  { echo -e "${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "${YELLOW}==>${RESET} $*"; }
err()   { echo -e "${RED}==>${RESET} $*"; }
step()  { echo -e "${CYAN}  >>${RESET} $*"; }

# ── Detect install target ──────────────────────────────────────────

if [ "$UID" -eq 0 ]; then
    AURORAE_DIR="/usr/share/aurorae/themes"
    SCHEMES_DIR="/usr/share/color-schemes"
    PLASMA_DIR="/usr/share/plasma/desktoptheme"
    LAYOUT_DIR="/usr/share/plasma/layout-templates"
    LOOKFEEL_DIR="/usr/share/plasma/look-and-feel"
    KVANTUM_DIR="/usr/share/Kvantum"
    WALLPAPER_DIR="/usr/share/wallpapers"
    ICONS_DIR="/usr/share/icons"
    APPLETS_DIR="/usr/share/plasma/plasmoids"
else
    AURORAE_DIR="$HOME/.local/share/aurorae/themes"
    SCHEMES_DIR="$HOME/.local/share/color-schemes"
    PLASMA_DIR="$HOME/.local/share/plasma/desktoptheme"
    LAYOUT_DIR="$HOME/.local/share/plasma/layout-templates"
    LOOKFEEL_DIR="$HOME/.local/share/plasma/look-and-feel"
    KVANTUM_DIR="$HOME/.config/Kvantum"
    WALLPAPER_DIR="$HOME/.local/share/wallpapers"
    ICONS_DIR="$HOME/.local/share/icons"
    APPLETS_DIR="$HOME/.local/share/plasma/plasmoids"
fi

ensure_dir() {
    mkdir -p "$1" 2>/dev/null || { err "Cannot create $1 — try running as root (sudo)"; exit 1; }
}
