#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  Windows Modern — unified installer
#
#  Usage:  ./install.sh              Interactive menu (default = Everything)
#          ./install.sh all          Install everything (asks Light/Dark)
#          ./install.sh all --dark   ...non-interactive, Dark
#          ./install.sh all --light  ...non-interactive, Light
#          ./install.sh <component>  Install one component (applies immediately)
#          ./install.sh --help       Show usage
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

# ── Install everything (menu 1 + CLI 'all') ─────────────────────────
# Phase A: atomic pieces (themes, icons, applets, sessionlock)
# Phase B: compose (layout template, look-and-feel files)
# Phase C: apply once (borders, theme+layout reset, Kvantum engine, restart)
install_everything() {
    local variant="${1:-}"

    # Resolve variant: flag > interactive prompt > dark default
    if [ -z "$variant" ]; then
        variant="$(ask_theme_variant)"
    fi
    local theme; theme="$(lookfeel_id "$variant")"

    echo ""
    info "Installing everything (${variant})..."

    # Batch mode: children install files only — we apply once at the end.
    export WM_BATCH=1

    # ── Phase A: atomic pieces ──
    info "[1/3] Installing themes, icons, and applets..."
    install_component themes
    install_component icons
    install_component showdesk
    install_component startmenu
    install_component systray
    install_component icontasks
    install_component digitalclock
    install_component sessionlock

    # ── Phase B: compose (layout references applets; lookfeel references everything) ──
    info "[2/3] Composing layout and global themes..."
    install_component layout
    install_component lookfeel

    unset WM_BATCH

    # ── Phase C: apply once ──
    info "[3/3] Applying theme (${variant})..."
    post_kwin_borders
    apply_lookandfeel "$theme" reset
    apply_kvantum_engine "$variant"
    restart_plasmashell

    echo ""
    info "Done! For the authentic Win11 look, enable floating:"
    echo -e "  ${BOLD}Right-click the panel → Show Panel Configuration →${RESET}"
    echo -e "  ${BOLD}Floating → Applets Only${RESET}"
    echo -e "  (Plasma's scripting API can't set this automatically.)"
    echo ""
    info "Press ${BOLD}Meta+L${RESET} to test the lock screen."
}

# ── Install all applets as a batch (menu 6) ─────────────────────────
install_all_applets() {
    export WM_BATCH=1
    info "Installing all applets..."
    install_component showdesk
    install_component startmenu
    install_component systray
    install_component icontasks
    install_component digitalclock
    unset WM_BATCH
    restart_plasmashell
}

# ── Interactive menu (grouped + sequential) ───────────────────────
menu() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║    Windows Modern — Unified Installer    ║${RESET}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}Appearance${RESET}"
    echo -e "    ${BOLD}1${RESET})  Everything (themes + icons + applets + layout)"
    echo -e "    ${BOLD}2${RESET})  Themes (Aurorae, colors, Kvantum, Plasma, wallpapers)"
    echo -e "    ${BOLD}3${RESET})  Icon pack"
    echo -e "    ${BOLD}4${RESET})  Global themes (look-and-feel)"
    echo -e "    ${BOLD}5${RESET})  Panel layout template"
    echo ""
    echo -e "  ${BOLD}Applets${RESET}"
    echo -e "    ${BOLD}6${RESET})  All applets"
    echo -e "    ${BOLD}7${RESET})  Show Desktop"
    echo -e "    ${BOLD}8${RESET})  Start Menu"
    echo -e "    ${BOLD}9${RESET})  System Tray (C++ — requires compiler)"
    echo -e "    ${BOLD}10${RESET}) Icon Tasks taskbar (C++ — requires compiler)"
    echo -e "    ${BOLD}11${RESET}) Digital Clock (QML)"
    echo ""
    echo -e "  ${BOLD}Session${RESET}"
    echo -e "    ${BOLD}12${RESET}) Session lock screen (Meta+L)"
    echo -e "    ${BOLD}13${RESET}) Boot greeter / login screen (PLM — C++ build + system install)"
    echo ""
    echo -e "    ${BOLD}0${RESET})  Quit"
    echo ""
    read -r -p "  Choice [1]: " choice
    choice="${choice:-1}"
    echo ""

    case "$choice" in
        1)  install_everything ;;
        2)  install_component themes ;;
        3)  install_component icons ;;
        4)  install_component lookfeel ;;
        5)  install_component layout ;;
        6)  install_all_applets ;;
        7)  install_component showdesk ;;
        8)  install_component startmenu ;;
        9)  install_component systray ;;
        10) install_component icontasks ;;
        11) install_component digitalclock ;;
        12) install_component sessionlock ;;
        13) echo "Boot greeter install requires root for the system-wide step."
            echo "Building patched PLM first (user)..."
            install_component greeter
            echo ""
            echo "Now installing system-wide (needs sudo)..."
            sudo bash "$SCRIPT_DIR/scripts/install-greeter-live.sh" || err "System greeter install failed or was cancelled." ;;
        0)  echo "Nothing installed."; exit 0 ;;
        *)  err "Invalid choice."; exit 1 ;;
    esac
}

# ── Parse CLI args ───────────────────────────────────────────────
# Extract --light/--dark flags from anywhere in the args.
variant_from_flag=""
args=()
for arg in "$@"; do
    case "$arg" in
        --light) variant_from_flag="light" ;;
        --dark)  variant_from_flag="dark" ;;
        *)       args+=("$arg") ;;
    esac
done
set -- "${args[@]}"

case "${1:-menu}" in
    --help|-h)
        echo "Usage: ./install.sh [component|all] [--light|--dark]"
        echo ""
        echo "  (no args)        Interactive menu (default = Everything)"
        echo "  all              Install everything (asks Light/Dark if interactive)"
        echo "  all --dark       Install everything non-interactively (Dark)"
        echo "  all --light      Install everything non-interactively (Light)"
        echo ""
        echo "  Components (install + apply immediately):"
        echo "    themes         Aurorae, colors, Kvantum, Plasma themes, wallpapers"
        echo "    icons          Windows Modern icon pack"
        echo "    lookfeel       Global themes (asks Light/Dark)"
        echo "    layout         Panel layout template"
        echo "    showdesk       Show Desktop applet"
        echo "    startmenu      Start Menu applet"
        echo "    systray        System Tray (C++ — needs compiler)"
        echo "    icontasks      Icon Tasks taskbar (C++ — needs compiler)"
        echo "    digitalclock   Digital Clock (QML)"
        echo "    applets        All five applets"
        echo "    sessionlock    Session lock screen (Meta+L)"
        echo "    greeter        Boot greeter / login screen (PLM build, user test)"
        echo ""
        echo "  Note: 'all' includes the session lock screen. The boot greeter is"
        echo "  opt-in (it replaces the system login manager) — use 'greeter'."
        echo ""
        exit 0
        ;;
    menu|"")
        menu
        ;;
    applets)
        install_all_applets
        ;;
    all)
        install_everything "$variant_from_flag"
        ;;
    greeter)
        echo "Boot greeter install requires root for the system-wide step."
        echo "Building patched PLM first (user)..."
        install_component greeter
        echo ""
        echo "Now installing system-wide (needs sudo)..."
        sudo bash "$SCRIPT_DIR/scripts/install-greeter-live.sh" || err "System greeter install failed or was cancelled."
        ;;
    *)
        install_component "$1"
        ;;
esac

echo ""
info "Done."
