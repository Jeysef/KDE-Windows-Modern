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

# ── Install component by name (non-fatal on failure) ────────────────
install_component() {
    local name="$1"
    local script="$SCRIPT_DIR/scripts/install-${name}.sh"
    if [ -x "$script" ]; then
        bash "$script" || {
            err "Component '$name' failed — continuing with remaining components."
            err "If this is a C++ applet (systray/icontasks), install build deps and re-run:"
            err "  ./install.sh $name"
        }
    else
        err "Unknown component: $name (no script at $script)"
        return 1
    fi
}

# ── Post-install: apply theme + layout (called at end of 'all') ─────
post_install() {
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSize" "Tiny"
        kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSizeAuto" "false"
        dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
}

# ── Apply the global theme with layout reset (non-interactive) ──────
apply_theme() {
    local theme="${1:-org.kde.windowsmodern.dark}"
    local tool="plasma-apply-lookandfeel"
    if ! command -v "$tool" &>/dev/null; then
        warn "$tool not found — apply manually in System Settings → Appearance → Global Theme."
        return 0
    fi
    if [ "$UID" -eq 0 ]; then
        warn "Running as root — apply the theme manually from a user session."
        return 0
    fi
    info "Applying $theme with layout reset..."
    "$tool" -a "$theme" --resetLayout
    bash "$SCRIPT_DIR/scripts/set-wallpaper.sh" || true
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
    echo -e "  ${BOLD}7${RESET})  Applets: Start Menu"
    echo -e "  ${BOLD}8${RESET})  Applets: System Tray (C++ — requires compiler)"
    echo -e "  ${BOLD}9${RESET})  Applets: Icon Tasks taskbar (C++ — requires compiler)"
    echo -e "  ${BOLD}a${RESET})  All applets (6–9)"
    echo -e "  ${BOLD}0${RESET})  Quit"
    echo ""
    read -r -p "  Choice [1]: " choice
    choice="${choice:-1}"
    echo ""

    case "$choice" in
        1)  # Install applets FIRST so the layout script can find them.
            install_component themes; install_component icons
            install_component showdesk
            install_component startmenu; install_component systray
            install_component icontasks
            install_component layout
            install_component lookfeel
            post_install ;;
        2)  install_component themes ;;
        3)  install_component icons ;;
        4)  install_component lookfeel ;;
        5)  install_component layout ;;
        6)  install_component showdesk ;;
        7)  install_component startmenu ;;
        8)  install_component systray ;;
        9)  install_component icontasks ;;
        a|A) install_component showdesk
            install_component startmenu; install_component systray
            install_component icontasks ;;
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
        echo "  startmenu   Start Menu applet"
        echo "  systray     System Tray (C++ — needs compiler)"
        echo "  icontasks   Icon Tasks taskbar (C++ — needs compiler)"
        echo "  applets     All applets (showdesk, startmenu, systray, icontasks)"
        echo "  all         Everything"
        echo ""
        exit 0
        ;;
    menu|"")
        menu
        ;;
    applets)
        install_component showdesk
        install_component startmenu; install_component systray
        install_component icontasks
        ;;
    all)
        # Install applets FIRST so the layout script can find them when
        # the global theme is applied with --resetLayout.
        install_component themes; install_component icons
        install_component showdesk
        install_component startmenu; install_component systray
        install_component icontasks
        install_component layout
        install_component lookfeel
        post_install
        # Apply the theme non-interactively now that everything is in place.
        if [ -t 0 ]; then
            echo ""
            echo -e "${BOLD}Apply the theme now?${RESET}"
            echo -e "  ${BOLD}1${RESET}) Light  (org.kde.windowsmodern.light)"
            echo -e "  ${BOLD}2${RESET}) Dark   (org.kde.windowsmodern.dark)"
            echo -e "  ${BOLD}3${RESET}) Do not apply"
            echo ""
            read -r -p "Choice [2]: " theme_choice
            theme_choice="${theme_choice:-2}"
            case "$theme_choice" in
                1|light|Light) apply_theme "org.kde.windowsmodern.light" ;;
                2|dark|Dark)   apply_theme "org.kde.windowsmodern.dark" ;;
                3|none|no|n|N) info "Theme not applied. Apply later in System Settings." ;;
                *) err "Invalid choice — skipping theme apply." ;;
            esac
        else
            apply_theme "org.kde.windowsmodern.dark"
        fi
        ;;
    *)
        install_component "$1"
        ;;
esac

echo ""
info "Done."
