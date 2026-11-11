#!/bin/bash
# This is a library: its colors and *_DIR paths are used by the scripts that
# source it, so "assigned but unused" does not apply.
# shellcheck disable=SC2034
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
    TABBOX_DIR="/usr/share/kwin/tabbox"
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
    TABBOX_DIR="$HOME/.local/share/kwin/tabbox"
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

# Wait up to ~5 s for the plasmashell process to disappear.
_wait_plasmashell_exit() {
    local i
    for i in {1..25}; do
        pgrep -x plasmashell >/dev/null 2>&1 || return 0
        sleep 0.2
    done
    return 1
}

# Return the name of the available KDE launcher (kstart6 or kstart).
_kstart_cmd() {
    if command -v kstart6 &>/dev/null; then
        echo "kstart6"
    elif command -v kstart &>/dev/null; then
        echo "kstart"
    else
        echo ""
    fi
}

# Restart Plasma Shell for the running user session (no-op if not running).
restart_plasmashell() {
    # Only when running inside a graphical session (never from a TTY or root).
    [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] || return 0
    if command -v systemctl &>/dev/null && systemctl --user cat plasma-plasmashell.service &>/dev/null; then
        # restart also *starts* the shell when it is stopped — the C++ applet
        # installers stop it in batch mode and leave the start to us.
        info "Restarting Plasma Shell..."
        systemctl --user restart plasma-plasmashell.service
        return 0
    fi
    if ! pgrep -x plasmashell >/dev/null 2>&1; then
        info "Starting Plasma Shell..."
        local kstart
        kstart="$(_kstart_cmd)"
        if [ -n "$kstart" ]; then $kstart plasmashell >/dev/null 2>&1; else (setsid plasmashell >/dev/null 2>&1 &); fi
        return 0
    fi
    info "Restarting Plasma Shell..."

    # Graceful quit first, fall back to killall.
    if command -v kquitapp6 &>/dev/null; then
        kquitapp6 plasmashell 2>/dev/null || true
    else
        killall plasmashell 2>/dev/null || true
    fi

    if ! _wait_plasmashell_exit; then
        warn "Plasma Shell did not stop gracefully; forcing..."
        killall -9 plasmashell 2>/dev/null || true
        sleep 0.5
    fi

    # Let the session bus release the old plasma-shell name before restarting.
    sleep 0.5

    local kstart
    kstart="$(_kstart_cmd)"
    if [ -n "$kstart" ]; then
        $kstart plasmashell >/dev/null 2>&1
    else
        warn "kstart not found; launching plasmashell directly..."
        plasmashell >/dev/null 2>&1 &
    fi

    # Verify the shell actually came back; retry once if it didn't.
    sleep 1
    if ! pgrep -x plasmashell >/dev/null 2>&1; then
        warn "Plasma Shell did not restart; trying once more..."
        if [ -n "$kstart" ]; then
            $kstart plasmashell >/dev/null 2>&1
        else
            plasmashell >/dev/null 2>&1 &
        fi
        sleep 2
    fi

    if ! pgrep -x plasmashell >/dev/null 2>&1; then
        err "Plasma Shell could not be restarted."
        err "Run manually:  killall plasmashell && kstart plasmashell"
        return 1
    fi

    # Give the layout script time to finish rebuilding panels before we return.
    sleep 1
}

# Stop Plasma Shell (for config it rewrites on exit). restart_plasmashell
# starts it again.
stop_plasmashell() {
    if command -v systemctl &>/dev/null && systemctl --user cat plasma-plasmashell.service &>/dev/null; then
        systemctl --user stop plasma-plasmashell.service
    elif command -v kquitapp6 &>/dev/null; then
        kquitapp6 plasmashell 2>/dev/null || true
    fi
    _wait_plasmashell_exit || killall plasmashell 2>/dev/null || true
}

# Install distro packages that are missing, with one password prompt.
# Usage: install_packages <package>...   (same names on Fedora/Debian/Arch/openSUSE)
install_packages() {
    local missing=() p
    for p in "$@"; do
        if command -v rpm &>/dev/null && rpm -q "$p" &>/dev/null; then continue; fi
        if command -v dpkg-query &>/dev/null && grep -q "ok installed" <<< "$(dpkg-query -W -f='${Status}' "$p" 2>/dev/null)"; then continue; fi
        if command -v pacman &>/dev/null && pacman -Q "$p" &>/dev/null; then continue; fi
        missing+=("$p")
    done
    [ "${#missing[@]}" -eq 0 ] && { step "Already installed: $*"; return 0; }
    local cmd
    if command -v dnf &>/dev/null; then cmd="dnf install -y --skip-unavailable"
    elif command -v apt-get &>/dev/null; then cmd="apt-get install -y"
    elif command -v pacman &>/dev/null; then cmd="pacman -S --needed --noconfirm"
    elif command -v zypper &>/dev/null; then cmd="zypper --non-interactive install"
    else
        warn "No supported package manager; install yourself: ${missing[*]}"
        return 1
    fi
    step "Installing ${missing[*]} (password prompt)..."
    # shellcheck disable=SC2086  # $cmd is a command line on purpose
    pkexec $cmd "${missing[@]}"
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

# Ask the running KWin to reload kwinrc. dbus-send defaults to sending a
# *signal*, which KWin ignores, so --type=method_call is required.
kwin_reconfigure() {
    command -v dbus-send &>/dev/null || return 0
    dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure \
        2>/dev/null || warn "Could not reach KWin — changes apply at next login."
}

# Window animations: KDE's defaults already match Windows 11 (scale on
# open/close, squash into the taskbar on minimize, maximize, slide between
# desktops). Except Show Desktop: KDE slides every window to the screen
# corners (windowaperture); Windows just gets them out of the way. Turned
# off only if the user never set it.
post_kwin_effects() {
    command -v kreadconfig6 &>/dev/null || return 0
    if [ -z "$(kreadconfig6 --file kwinrc --group Plugins --key windowapertureEnabled)" ]; then
        kwriteconfig6 --file kwinrc --group Plugins --key windowapertureEnabled false
        kwin_reconfigure
    fi
}

# KWin tiny borders + reconfigure (the "post_install" borders step).
post_kwin_borders() {
    command -v kwriteconfig6 &>/dev/null || return 0
    step "KWin border size → Tiny"
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSize" "Tiny"
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSizeAuto" "false"
    kwin_reconfigure
}

# KWin per-monitor Alt+Tab: only list windows on the active monitor.
# [TabBox] MultiScreenMode: 0 = all monitors (default), 1 = current only,
# 2 = exclude current.
post_kwin_per_monitor_alt_tab() {
    command -v kwriteconfig6 &>/dev/null || return 0
    step "KWin Alt+Tab → per-monitor"
    kwriteconfig6 --file kwinrc --group "TabBox" --key "MultiScreenMode" "1"
    kwin_reconfigure
}

# KWin Alt+Tab: use the Windows Modern window switcher.
ALT_TAB_LAYOUT="org.kde.windowsmodern.alttab"
post_kwin_alt_tab_switcher() {
    command -v kwriteconfig6 &>/dev/null || return 0
    [ -d "$TABBOX_DIR/$ALT_TAB_LAYOUT" ] || return 0
    step "KWin Alt+Tab → Windows Modern switcher"
    kwriteconfig6 --file kwinrc --group "TabBox" --key "LayoutName" "$ALT_TAB_LAYOUT"
    kwin_reconfigure
}

# Prompt the user for a theme variant. Prints 'light' or 'dark'.
# Non-interactive sessions default to dark (no prompt).
# Prompt text goes to stderr so callers can safely use command substitution
# to capture only the answer (e.g. variant="$(ask_theme_variant)").
ask_theme_variant() {
    if ! is_interactive; then
        echo "dark"
        return
    fi
    echo "" >&2
    echo -e "${BOLD}┌──────────────────────────────────────────────────────┐${RESET}" >&2
    echo -e "${BOLD}│  Choose the Windows Modern theme variant             │${RESET}" >&2
    echo -e "${BOLD}└──────────────────────────────────────────────────────┘${RESET}" >&2
    echo "" >&2
    echo -e "  ${BOLD}1${RESET}) Light  (org.kde.windowsmodern.light)" >&2
    echo -e "  ${BOLD}2${RESET}) Dark   (org.kde.windowsmodern.dark)" >&2
    echo "" >&2
    echo -e "  Type ${BOLD}1${RESET} for Light, ${BOLD}2${RESET} for Dark, or press ${BOLD}Enter${RESET} for Dark." >&2
    echo "" >&2
    read -r -p "  Choice [2]: " choice
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
