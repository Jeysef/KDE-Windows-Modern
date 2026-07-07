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

# Remove one or more paths. User-local paths are deleted directly; system
# paths (/usr/*) require pkexec or sudo because regular users cannot write
# them. Globs must be unquoted on the caller side so the shell expands them.
rm_path() {
    local path
    for path in "$@"; do
        [ -e "$path" ] || continue
        if [[ "$path" == "$HOME"/* ]]; then
            rm -rf "$path" 2>/dev/null || true
        else
            if command -v pkexec &>/dev/null; then
                pkexec rm -rf "$path" 2>/dev/null || warn "Could not remove system path (pkexec failed): $path"
            elif command -v sudo &>/dev/null; then
                sudo rm -rf "$path" 2>/dev/null || warn "Could not remove system path (sudo failed): $path"
            else
                rm -rf "$path" 2>/dev/null || warn "Could not remove path: $path"
            fi
        fi
    done
}

detect_systray_so_dir() {
    local plugin_dir=""
    if command -v pkg-config &>/dev/null; then
        plugin_dir=$(pkg-config --variable=plugindir Qt6Core 2>/dev/null || true)
    fi
    if [ -z "$plugin_dir" ]; then
        if [ -d /usr/lib64/qt6/plugins ]; then
            plugin_dir=/usr/lib64/qt6/plugins
        elif [ -d /usr/lib/qt6/plugins ]; then
            plugin_dir=/usr/lib/qt6/plugins
        else
            plugin_dir=/usr/lib64/qt6/plugins
        fi
    fi
    echo "$plugin_dir/plasma/applets"
}

reset_kwin_borders() {
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSize" "Normal"
        kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "BorderSizeAuto" "true"
        dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    fi
}

uninstall_component() {
    local name="$1"
    info "Uninstalling: $name"
    case "$name" in
        themes)
            # Aurorae packages are lowercase in the current repo
            rm_path "$AURORAE_DIR/windows-modern"*-aurorae
            rm_path "$AURORAE_DIR/Windows-modern"*-aurorae
            rm_path "$AURORAE_DIR/__aurorae__svg__windows-modern"*
            rm_path "$AURORAE_DIR/__aurorae__svg__Windows-modern"*
            rm_path "$SCHEMES_DIR/WindowsModern"*.colors
            rm_path "$KVANTUM_DIR/Windows-modern"*
            rm_path "$KVANTUM_DIR/windows-modern"*
            rm_path "$PLASMA_DIR/Windows-modern"*
            rm_path "$PLASMA_DIR/windows-modern"*
            rm_path "$WALLPAPER_DIR/Windows-modern"*
            rm_path "$WALLPAPER_DIR/windows-modern"*
            reset_kwin_borders
            info "Themes uninstalled."
            ;;
        icons)
            rm_path "$ICONS_DIR/windows-modern"
            info "Icons uninstalled."
            ;;
        lookfeel)
            rm_path "$LOOKFEEL_DIR/org.kde.windowsmodern.dark"
            rm_path "$LOOKFEEL_DIR/org.kde.windowsmodern.light"
            info "Global themes uninstalled."
            ;;
        layout)
            rm_path "$LAYOUT_DIR/org.kde.windowsmodern.panel"
            info "Panel layout uninstalled."
            ;;
        showdesk)
            rm_path "$APPLETS_DIR/org.kde.windowsmodern.showdesktop"
            info "Show Desktop uninstalled."
            ;;
        startmenu)
            rm_path "$APPLETS_DIR/org.kde.windowsmodern.startmenu"
            info "Start Menu uninstalled."
            ;;
        systray|systemtray)
            rm_path "$(detect_systray_so_dir)/org.kde.windowsmodern.systemtray.so"
            rm_path "/usr/share/plasma/plasmoids/org.kde.windowsmodern.systemtray"
            rm_path "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.systemtray"
            # Legacy quicksettings plasmoid that was absorbed into the system tray
            rm_path "/usr/share/plasma/plasmoids/org.kde.windowsmodern.quicksettings"
            rm_path "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.quicksettings"
            info "System Tray uninstalled. Restart plasmashell to complete."
            ;;
        all)
            for c in themes icons lookfeel layout showdesk startmenu systray; do
                uninstall_component "$c"
            done
            reset_kwin_borders
            ;;
        *)
            err "Unknown component: $name"
            echo "Available: themes, icons, lookfeel, layout, showdesk, startmenu, systray, all"
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
        echo "  startmenu  Start Menu applet"
        echo "  systray    System Tray"
        exit 0
        ;;
    *)
        uninstall_component "$1"
        ;;
esac
