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
            # Stale local .so copies take precedence over the system plugin and
            # can make uninstall+reinstall appear to do nothing.
            rm_path "$HOME/.local/lib64/qt6/plugins/plasma/applets/org.kde.windowsmodern.systemtray.so"
            rm_path "$HOME/.local/lib/qt6/plugins/plasma/applets/org.kde.windowsmodern.systemtray.so"
            # Legacy quicksettings plasmoid that was absorbed into the system tray
            rm_path "/usr/share/plasma/plasmoids/org.kde.windowsmodern.quicksettings"
            rm_path "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.quicksettings"
            info "System Tray uninstalled. Restart plasmashell to complete."
            ;;
        icontasks)
            rm_path "$(detect_systray_so_dir)/org.kde.plasma.icontasks.so"
            rm_path "/usr/share/plasma/plasmoids/org.kde.plasma.icontasks"
            rm_path "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.icontasks"
            rm_path "$HOME/.local/lib64/qt6/plugins/plasma/applets/org.kde.plasma.icontasks.so"
            rm_path "$HOME/.local/lib/qt6/plugins/plasma/applets/org.kde.plasma.icontasks.so"
            info "Icon Tasks uninstalled. Restart plasmashell to complete."
            ;;
        digitalclock)
            rm_path "/usr/share/plasma/plasmoids/org.kde.windowsmodern.digitalclock"
            rm_path "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.digitalclock"
            info "Digital Clock uninstalled. Restart plasmashell to complete."
            ;;
        sessionlock)
            # kscreenlocker uses the current desktop shell's lockscreen. We
            # themed Meta+L by creating a complete user-level overlay of
            # org.kde.plasma.desktop. Remove the ENTIRE overlay — never leave
            # an incomplete shell behind (it triggers the Qt widget fallback).
            rm_path "$HOME/.local/share/plasma/shells/org.kde.plasma.desktop"
            rm_path "$HOME/.local/share/plasma/shells/org.kde.windowsmodern.lockscreen"
            if command -v kwriteconfig6 &>/dev/null; then
                kwriteconfig6 --file kscreenlockerrc --group Greeter --key Theme --delete 2>/dev/null || true
            fi
            command -v kbuildsycoca6 &>/dev/null && kbuildsycoca6 2>/dev/null || true
            rm -rf ~/.cache/qmlcache ~/.cache/QtProject/qmlcache 2>/dev/null || true
            info "Session lock screen uninstalled. Breeze restored for Meta+L."
            ;;
        greeter)
            # Revert any applied PLM patches and remove the user-level theme.
            PLM_DIR="$SRC_DIR/third_party/plasma-login-manager"
            PATCH_DIR="$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark/patches"
            if [ -d "${PLM_DIR}" ]; then
                for p in main-cpp.patch; do
                    if [ -f "${PATCH_DIR}/${p}" ]; then
                        patch -d "${PLM_DIR}" -p1 -R --dry-run -s -f < "${PATCH_DIR}/${p}" 2>/dev/null \
                            && patch -d "${PLM_DIR}" -p1 -R < "${PATCH_DIR}/${p}" 2>/dev/null || true
                    fi
                done
            fi
            rm_path "$HOME/.local/share/plasma/look-and-feel/org.kde.windowsmodern.dark/contents/lockscreen"
            info "Boot greeter (user) uninstalled. Patches reverted, theme removed."
            warn "To restore the SYSTEM greeter binary, run:  sudo bash scripts/uninstall-greeter-system.sh"
            ;;
        greetersystem)
            bash "$SRC_DIR/scripts/uninstall-greeter-system.sh"
            ;;
        all)
            for c in themes icons lookfeel layout showdesk startmenu systray icontasks digitalclock sessionlock greeter; do
                uninstall_component "$c"
            done
            reset_kwin_borders
            ;;
        *)
            err "Unknown component: $name"
            echo "Available: themes, icons, lookfeel, layout, showdesk, startmenu, systray, icontasks, digitalclock, sessionlock, greeter, greetersystem, all"
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
    echo "  icontasks  Icon Tasks taskbar"
    echo "  digitalclock Digital Clock"
    echo "  sessionlock Session lock screen (Meta+L)"
    echo "  greeter    Boot greeter (user theme + revert patches)"
    echo "  greetersystem Restore system greeter binary (needs sudo)"
    echo "  all        Uninstall everything"
    exit 0
    ;;
    *)
        uninstall_component "$1"
        ;;
esac
