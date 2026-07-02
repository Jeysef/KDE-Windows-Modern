#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  Windows Modern — unified installer
#
#  Usage:  ./install.sh              Interactive menu
#          ./install.sh <component>   Install one component
#          ./install.sh --help        Show usage
#
#  Components are installed by scripts/install-<name>.sh
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/scripts/install-lib.sh"

# ── Install component by name ──────────────────────────────────────
install_component() {
    local name="$1"
    local script="$SCRIPT_DIR/scripts/install-${name}.sh"
    if [ -x "$script" ]; then
        bash "$script"
    else
        err "Unknown component: $name (no script at $script)"
        return 1
    fi
}

# ── Post-install ───────────────────────────────────────────────────
post_install() {
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSize" "Tiny"
        kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSizeAuto" "false"
        dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
}

# ── Interactive menu ───────────────────────────────────────────────
menu() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║    Windows Modern — Unified Installer    ║${RESET}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}1${RESET})  Everything (themes + icons + applets + layout)"
    echo -e "  ${BOLD}2${RESET})  Themes (Aurorae, colors, Kvantum, Plasma, wallpapers)"
    echo -e "  ${BOLD}3${RESET})  Icon pack"
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

    case "$choice" in
        1)  install_component themes; install_component icons; install_component lookfeel
            install_component layout
            install_component showdesk; install_component quickset
            install_component startmenu; install_component systray
            post_install ;;
        2)  install_component themes ;;
        3)  install_component icons ;;
        4)  install_component lookfeel ;;
        5)  install_component layout ;;
        6)  install_component showdesk ;;
        7)  install_component quickset ;;
        8)  install_component startmenu ;;
        9)  install_component systray ;;
        10) install_component showdesk; install_component quickset
            install_component startmenu; install_component systray ;;
        0)  echo "Nothing installed."; exit 0 ;;
        *)  err "Invalid choice."; exit 1 ;;
    esac
}

# ── Main ───────────────────────────────────────────────────────────
case "${1:-menu}" in
    --help|-h)
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
        echo "  systray     System Tray (C++ — needs compiler)"
        echo "  applets     All applets (showdesk, quickset, startmenu, systray)"
        echo "  all         Everything"
        echo ""
        exit 0
        ;;
    menu|"")
        menu
        ;;
    applets)
        install_component showdesk; install_component quickset
        install_component startmenu; install_component systray
        ;;
    all)
        install_component themes; install_component icons; install_component lookfeel
        install_component layout
        install_component showdesk; install_component quickset
        install_component startmenu; install_component systray
        post_install
        ;;
    *)
        install_component "$1"
        ;;
esac

echo ""
info "Done."
