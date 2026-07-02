#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  Windows Modern — unified interactive installer
#
#  Usage:  ./install.sh
#
#  This is the single entrypoint. It presents a menu and runs the
#  appropriate install logic for each component. Individual scripts
#  (dev.sh, etc.) can still be run directly when only one component
#  changed.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

BOLD="\033[1m"; GREEN="\033[32m"; BLUE="\033[34m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"; RESET="\033[0m"
info()  { echo -e "${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "${YELLOW}==>${RESET} $*"; }
err()   { echo -e "${RED}==>${RESET} $*"; }
step()  { echo -e "${CYAN}  >>${RESET} $*"; }

# ───────────────────────────────────────────────────────────────────
# Detect install target
# ───────────────────────────────────────────────────────────────────
ROOT_UID=0
if [ "$UID" -eq "$ROOT_UID" ]; then
    IS_ROOT=1
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
    IS_ROOT=0
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

ensure_dir() { mkdir -p "$1" 2>/dev/null || { err "Cannot create $1 — try running as root (sudo)"; exit 1; }; }

for d in "$AURORAE_DIR" "$SCHEMES_DIR" "$PLASMA_DIR" "$LOOKFEEL_DIR" "$KVANTUM_DIR" "$WALLPAPER_DIR" "$ICONS_DIR" "$LAYOUT_DIR" "$APPLETS_DIR"; do
    ensure_dir "$d"
done

# ───────────────────────────────────────────────────────────────────
# Install functions — each component is independent
# ───────────────────────────────────────────────────────────────────

install_themes() {
    info "Installing themes..."
    step "Window decorations (Aurorae)"
    cp -r "$SRC_DIR/aurorae/"* "$AURORAE_DIR/"
    step "Color schemes"
    cp -r "$SRC_DIR/color-schemes/"*.colors "$SCHEMES_DIR/"
    step "Kvantum themes"
    cp -r "$SRC_DIR/Kvantum/"* "$KVANTUM_DIR/"
    step "Plasma desktop themes"
    cp -r "$SRC_DIR/plasma/desktoptheme/"* "$PLASMA_DIR/"
    step "Wallpapers"
    cp -r "$SRC_DIR/wallpaper/"* "$WALLPAPER_DIR/"

    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file Kvantum/kvantum.kvconfig --group General --key theme Windows-modern-light
    fi
    info "Themes installed."
}

install_icons() {
    if [ ! -d "$SRC_DIR/icons/windows-modern" ]; then
        warn "Icon pack not found at icons/windows-modern — skipping."
        return
    fi
    info "Installing icon pack..."
    rm -rf "$ICONS_DIR/windows-modern"
    cp -r "$SRC_DIR/icons/windows-modern" "$ICONS_DIR/"
    if command -v gtk-update-icon-cache &>/dev/null; then
        gtk-update-icon-cache -f "$ICONS_DIR/windows-modern" &>/dev/null || true
    fi
    info "Icons installed."
}

install_lookfeel() {
    info "Installing global themes (look-and-feel)..."
    step "Dark theme"
    rm -rf "$LOOKFEEL_DIR/org.kde.windowsmodern.dark"
    cp -r "$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark" "$LOOKFEEL_DIR/"
    step "Light theme"
    rm -rf "$LOOKFEEL_DIR/org.kde.windowsmodern.light"
    cp -r "$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.light" "$LOOKFEEL_DIR/"
    info "Global themes installed."
}

install_panel_layout() {
    info "Installing panel layout template..."
    local src="$SRC_DIR/plasma/layout-templates/org.kde.windowsmodern.panel"
    if [ ! -d "$src" ]; then
        warn "Panel layout not found — skipping."
        return
    fi
    rm -rf "$LAYOUT_DIR/org.kde.windowsmodern.panel"
    cp -r "$src" "$LAYOUT_DIR/"
    info "Panel layout installed."
}

install_showdesktop() {
    info "Installing Show Desktop applet..."
    local src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.showdesktop"
    [ -d "$src" ] || { warn "Not found — skipping."; return; }
    rm -rf "$APPLETS_DIR/org.kde.windowsmodern.showdesktop"
    cp -r "$src" "$APPLETS_DIR/"
    info "Show Desktop installed."
}

install_quicksettings() {
    info "Installing Quick Settings applet..."
    local src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.quicksettings"
    [ -d "$src" ] || { warn "Not found — skipping."; return; }
    rm -rf "$APPLETS_DIR/org.kde.windowsmodern.quicksettings"
    cp -r "$src" "$APPLETS_DIR/"
    info "Quick Settings installed."
}

install_startmenu() {
    info "Installing Start Menu applet..."
    local src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.startmenu"
    [ -d "$src" ] || { warn "Not found — skipping."; return; }
    rm -rf "$APPLETS_DIR/org.kde.windowsmodern.startmenu"
    cp -r "$src" "$APPLETS_DIR/"
    info "Start Menu installed."
}

install_systemtray() {
    info "Installing System Tray (C++ applet)..."
    local dir="$SRC_DIR/plasma/applets/org.kde.windowsmodern.systemtray"
    [ -d "$dir" ] || { warn "System tray source not found — skipping."; return; }

    # Prune any stale KPackage copies first (the critical dark-rectangle bug)
    rm -rf "$APPLETS_DIR/org.kde.windowsmodern.systemtray" 2>/dev/null || true
    rm -rf "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.systemtray" 2>/dev/null || true
    sudo rm -rf /usr/share/plasma/plasmoids/org.kde.windowsmodern.systemtray 2>/dev/null || true

    # Run the system tray's own dev script
    if [ -x "$dir/dev.sh" ]; then
        ( cd "$dir" && bash dev.sh )
    else
        err "dev.sh not found in $dir — cannot install system tray."
        return 1
    fi
}

# ───────────────────────────────────────────────────────────────────
# Post-install: KWin decoration
# ───────────────────────────────────────────────────────────────────
post_install() {
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSize" "Tiny"
        kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSizeAuto" "false"
        dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
}

# ───────────────────────────────────────────────────────────────────
# Interactive menu
# ───────────────────────────────────────────────────────────────────
menu() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║    Windows Modern — Unified Installer    ║${RESET}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}1${RESET})  Everything (themes + icons + applets + layout)"
    echo -e "  ${BOLD}2${RESET})  Themes only (Aurorae, colors, Kvantum, Plasma, wallpapers)"
    echo -e "  ${BOLD}3${RESET})  Icons"
    echo -e "  ${BOLD}4${RESET})  Global themes (look-and-feel)"
    echo -e "  ${BOLD}5${RESET})  Panel layout template"
    echo -e "  ${BOLD}6${RESET})  Applets: Show Desktop"
    echo -e "  ${BOLD}7${RESET})  Applets: Quick Settings"
    echo -e "  ${BOLD}8${RESET})  Applets: Start Menu"
    echo -e "  ${BOLD}9${RESET})  Applets: System Tray (C++ — requires compiler)"
    echo -e "  ${BOLD}10${RESET}) All applets (6–9)"
    echo -e "  ${BOLD}0${RESET})  Quit"
    echo ""
    read -r -p "  Choice [1]: " choice
    choice="${choice:-1}"
    echo ""
}

# ───────────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────────
if [ "${1:-}" == "--help" ] || [ "${1:-}" == "-h" ]; then
    echo "Usage: ./install.sh [component]"
    echo ""
    echo "  (no args)   Interactive menu"
    echo "  themes      Aurorae, colors, Kvantum, Plasma themes, wallpapers"
    echo "  icons       Windows Modern icon pack"
    echo "  lookfeel    Global themes (dark/light)"
    echo "  layout      Panel layout template"
    echo "  showdesk    Show Desktop applet"
    echo "  quickset    Quick Settings applet"
    echo "  startmenu   Start Menu applet"
    echo "  systray     System Tray applet (C++ — needs compiler)"
    echo "  applets     All applets (showdesk, quickset, startmenu, systray)"
    echo "  all         Everything"
    echo ""
    exit 0
fi

case "${1:-menu}" in
    menu|"")
        menu
        case "$choice" in
            1)  install_themes; install_icons; install_lookfeel; install_panel_layout
                install_showdesktop; install_quicksettings; install_startmenu; install_systemtray
                post_install ;;
            2)  install_themes ;;
            3)  install_icons ;;
            4)  install_lookfeel ;;
            5)  install_panel_layout ;;
            6)  install_showdesktop ;;
            7)  install_quicksettings ;;
            8)  install_startmenu ;;
            9)  install_systemtray ;;
            10) install_showdesktop; install_quicksettings; install_startmenu; install_systemtray ;;
            0)  echo "Nothing installed."; exit 0 ;;
            *)  err "Invalid choice."; exit 1 ;;
        esac
        ;;
    themes)     install_themes ;;
    icons)      install_icons ;;
    lookfeel)   install_lookfeel ;;
    layout)     install_panel_layout ;;
    showdesk)   install_showdesktop ;;
    quickset)   install_quicksettings ;;
    startmenu)  install_startmenu ;;
    systray)    install_systemtray ;;
    applets)    install_showdesktop; install_quicksettings; install_startmenu; install_systemtray ;;
    all)        install_themes; install_icons; install_lookfeel; install_panel_layout
                install_showdesktop; install_quicksettings; install_startmenu; install_systemtray
                post_install ;;
    *)          err "Unknown component: $1"; echo "Run with --help for usage."; exit 1 ;;
esac

echo ""
info "Done."
