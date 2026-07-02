#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  uninstall.sh — remove all Windows Modern components
#
#  Usage:  ./uninstall.sh              Remove everything
#          ./uninstall.sh <component>   Remove one component
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/scripts/install-lib.sh"

ELEVATE=""
if [ "$UID" -ne 0 ]; then
    if command -v sudo &>/dev/null; then
        ELEVATE="sudo"
    fi
fi

uninstall_component() {
    local name="$1"
    info "Uninstalling: $name"
    case "$name" in
        themes)
            $ELEVATE rm -rf "$AURORAE_DIR/Windows-modern"* "$AURORAE_DIR/__aurorae__svg__windows-modern"* 2>/dev/null || true
            $ELEVATE rm -f "$SCHEMES_DIR/WindowsModern"*.colors 2>/dev/null || true
            $ELEVATE rm -rf "$KVANTUM_DIR/Windows-modern"* 2>/dev/null || true
            $ELEVATE rm -rf "$PLASMA_DIR/Windows-modern"* 2>/dev/null || true
            $ELEVATE rm -rf "$WALLPAPER_DIR/Windows-modern"* 2>/dev/null || true
            info "Themes uninstalled."
            ;;
        icons)
            $ELEVATE rm -rf "$ICONS_DIR/windows-modern" 2>/dev/null || true
            info "Icons uninstalled."
            ;;
        lookfeel)
            $ELEVATE rm -rf "$LOOKFEEL_DIR/org.kde.windowsmodern.dark" \
                             "$LOOKFEEL_DIR/org.kde.windowsmodern.light" 2>/dev/null || true
            info "Global themes uninstalled."
            ;;
        layout)
            $ELEVATE rm -rf "$LAYOUT_DIR/org.kde.windowsmodern.panel" 2>/dev/null || true
            info "Panel layout uninstalled."
            ;;
        showdesk)
            $ELEVATE rm -rf "$APPLETS_DIR/org.kde.windowsmodern.showdesktop" 2>/dev/null || true
            info "Show Desktop uninstalled."
            ;;
        quickset)
            $ELEVATE rm -rf "$APPLETS_DIR/org.kde.windowsmodern.quicksettings" 2>/dev/null || true
            info "Quick Settings uninstalled."
            ;;
        startmenu)
            $ELEVATE rm -rf "$APPLETS_DIR/org.kde.windowsmodern.startmenu" 2>/dev/null || true
            info "Start Menu uninstalled."
            ;;
        systray|systemtray)
            $ELEVATE rm -f "/usr/lib64/qt6/plugins/plasma/applets/org.kde.windowsmodern.systemtray.so" 2>/dev/null || true
            $ELEVATE rm -rf "/usr/share/plasma/plasmoids/org.kde.windowsmodern.systemtray" 2>/dev/null || true
            rm -rf "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.systemtray" 2>/dev/null || true
            info "System Tray uninstalled. Restart plasmashell to complete."
            ;;
        all)
            for c in themes icons lookfeel layout showdesk quickset startmenu systray; do
                uninstall_component "$c"
            done
            ;;
        *)
            err "Unknown component: $name"
            echo "Available: themes, icons, lookfeel, layout, showdesk, quickset, startmenu, systray, all"
            exit 1
            ;;
    esac
}

case "${1:-}" in
    --help|-h|"")
        echo "Usage: ./uninstall.sh [component]"
        echo "  (no args)  Show help"
        echo "  all        Uninstall everything"
        echo "  themes     Themes (Aurorae, colors, Kvantum, Plasma, wallpapers)"
        echo "  icons      Icon pack"
        echo "  lookfeel   Global themes"
        echo "  layout     Panel layout template"
        echo "  showdesk   Show Desktop applet"
        echo "  quickset   Quick Settings applet"
        echo "  startmenu  Start Menu applet"
        echo "  systray    System Tray"
        exit 0
        ;;
    *)
        uninstall_component "$1"
        ;;
esac
