#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  Shared library — sourced by all install-*.sh scripts
#
#  Provides install paths, logging, and reusable apply/reload helpers.
#  WM_BATCH=1 in the environment tells component scripts to install
#  files only — skip prompts, apply, and plasmashell restarts — because
#  the parent 'all' driver applies everything once at the end.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

# Always resolve to this file's own location so SRC_DIR is correct no
# matter which script sources us (install.sh, uninstall.sh, or a
# component script invoked directly).
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

# ── Reusable helpers ───────────────────────────────────────────────

# True when running on a terminal (safe to prompt).
is_interactive() { [ -t 0 ]; }

# True when the parent 'all' driver is in charge — component scripts
# should then install files only and stay silent.
is_batch() { [ "${WM_BATCH:-0}" = "1" ]; }

# Restart Plasma Shell for the running user session (no-op if not running).
restart_plasmashell() {
    if ! pgrep -x plasmashell >/dev/null 2>&1; then
        return 0
    fi
    if command -v systemctl &>/dev/null && systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null; then
        info "Restarting Plasma Shell..."
        systemctl --user restart plasma-plasmashell.service
    else
        info "Restarting Plasma Shell with killall/kstart6..."
        killall plasmashell 2>/dev/null || true
        kstart6 plasmashell >/dev/null 2>&1 &
    fi
}

# Apply a global theme. Usage: apply_lookandfeel <theme-id> [reset]
# 'reset' adds --resetLayout so the desktop layout is rebuilt from the theme.
apply_lookandfeel() {
    local id="$1"
    local reset_flag=""
    [ "${2:-}" = "reset" ] && reset_flag="--resetLayout"
    if [ "$UID" -eq 0 ]; then
        warn "Running as root — apply the theme manually from a user session."
        return 0
    fi
    if ! command -v plasma-apply-lookandfeel &>/dev/null; then
        warn "plasma-apply-lookandfeel not found — apply manually in System Settings."
        return 0
    fi
    info "Applying $id ${reset_flag:+with layout reset}..."
    plasma-apply-lookandfeel -a "$id" $reset_flag
    bash "$SRC_DIR/scripts/set-wallpaper.sh" || true
}

# Set the Application Style (widgetStyle) so Kvantum actually renders.
# Variant 'dark' uses kvantum-dark, 'light' uses kvantum.
apply_kvantum_engine() {
    local variant="${1:-dark}"
    if [ "$UID" -eq 0 ]; then return 0; fi
    command -v kwriteconfig6 &>/dev/null || return 0
    local style="kvantum"
    [ "$variant" = "dark" ] && style="kvantum-dark"
    step "Setting Application Style → $style"
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "$style"
}

# KWin tiny borders + reconfigure (the "post_install" borders step).
post_kwin_borders() {
    command -v kwriteconfig6 &>/dev/null || return 0
    step "KWin border size → Tiny"
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSize" "Tiny"
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSizeAuto" "false"
    dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
}

# Prompt the user for a theme variant. Prints 'light' or 'dark'.
# Non-interactive sessions default to dark (no prompt).
ask_theme_variant() {
    if ! is_interactive; then
        echo "dark"
        return
    fi
    echo ""
    echo -e "${BOLD}Light or Dark?${RESET}"
    echo -e "  ${BOLD}1${RESET}) Light  (org.kde.windowsmodern.light)"
    echo -e "  ${BOLD}2${RESET}) Dark   (org.kde.windowsmodern.dark)"
    echo ""
    read -r -p "Choice [2]: " choice
    choice="${choice:-2}"
    case "$choice" in
        1|light|Light) echo "light" ;;
        *) echo "dark" ;;
    esac
}

# Map a variant name to the look-and-feel package id.
lookfeel_id() {
    case "$1" in
        light) echo "org.kde.windowsmodern.light" ;;
        *)     echo "org.kde.windowsmodern.dark" ;;
    esac
}
