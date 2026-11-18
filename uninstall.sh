#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  uninstall.sh — remove all Windows Modern components
#
#  Usage:  ./uninstall.sh              Remove everything
#          ./uninstall.sh <component>   Remove one component
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/install-lib.sh
source "$SCRIPT_DIR/scripts/install-lib.sh"
# shellcheck source=scripts/config-backup.sh
source "$SCRIPT_DIR/scripts/config-backup.sh"

# Steps that needed root and failed (password dialog cancelled, no pkexec):
# a component's "uninstalled" message is only printed when none did.
UNINSTALL_FAILURES=0

# Print a component's success message, or say it is incomplete.
uninstalled_msg() {
    local before="$1" message="$2"
    if [ "$UNINSTALL_FAILURES" -gt "$before" ]; then
        warn "Not fully uninstalled: the steps above that need root failed. Run it again to retry."
    else
        info "$message"
    fi
}

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
                pkexec rm -rf "$path" 2>/dev/null \
                    || { warn "Could not remove system path (pkexec failed): $path"; UNINSTALL_FAILURES=$((UNINSTALL_FAILURES + 1)); }
            elif command -v sudo &>/dev/null; then
                sudo rm -rf "$path" 2>/dev/null \
                    || { warn "Could not remove system path (sudo failed): $path"; UNINSTALL_FAILURES=$((UNINSTALL_FAILURES + 1)); }
            else
                rm -rf "$path" 2>/dev/null \
                    || { warn "Could not remove path: $path"; UNINSTALL_FAILURES=$((UNINSTALL_FAILURES + 1)); }
            fi
        fi
    done
}

# Move a backup made at install time back to its original system location.
# Used for distro-owned files that a Windows Modern fork had to move aside.
restore_backup() {
    local backup="$1" target="$2"
    [ -e "$backup" ] || return 0
    if [ -e "$target" ]; then
        # The package manager already restored the original (e.g. after an
        # update); the backup is redundant.
        rm_path "$backup"
        return 0
    fi
    local mover=""
    if command -v pkexec &>/dev/null; then mover="pkexec"
    elif command -v sudo &>/dev/null; then mover="sudo"
    fi
    if [ -n "$mover" ] && $mover mv -T "$backup" "$target" 2>/dev/null; then
        step "Restored $target"
    else
        warn "Could not restore $target from $backup."
        UNINSTALL_FAILURES=$((UNINSTALL_FAILURES + 1))
        warn "Restore it manually, or reinstall your distro's plasma-desktop package."
    fi
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
        kwriteconfig6 --file kwinrc --group "TabBox" --key "MultiScreenMode" "0"
        kwin_reconfigure
    fi
}

uninstall_component() {
    local name="$1" failures_before="$UNINSTALL_FAILURES"
    info "Uninstalling: $name"
    case "$name" in
        themes)
            # Transparency effects off: put back the blur setting from before.
            if [ -f "$HOME/.local/share/windows-modern/transparency-off" ]; then
                previous="$(sed -n 's/^blurEnabled=//p' "$HOME/.local/share/windows-modern/transparency-off")"
                if [ -n "$previous" ]; then
                    kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled "$previous"
                else
                    kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled --delete
                fi
                rm -f "$HOME/.local/share/windows-modern/transparency-off"
            fi
            if [ -f "$HOME/.local/share/windows-modern/backup/cursor-theme.ours" ]; then
                rm_path "$HOME/.local/share/icons/Win10OS-cursors"
                rm -f "$HOME/.local/share/windows-modern/backup/cursor-theme.ours"
            fi
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
            # The lock screen pointed at that wallpaper (set-wallpaper.sh):
            # back to Plasma's default instead of a missing picture.
            if grep -qi "wallpapers/Windows-modern" "$HOME/.config/kscreenlockerrc" 2>/dev/null; then
                for key in Image PreviewImage; do
                    kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper \
                        --group org.kde.image --group General --key "$key" --delete 2>/dev/null || true
                done
            fi
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
            uninstalled_msg "$failures_before" "System Tray uninstalled. Restart plasmashell to complete."
            ;;
        icontasks)
            # The fork reuses the stock plugin ID. Remove our compiled .so and
            # put the distro's stock KPackage back (dev.sh moved it aside).
            # Never delete /usr/share/plasma/plasmoids/org.kde.plasma.icontasks
            # directly: it belongs to the plasma-desktop package.
            rm_path "$(detect_systray_so_dir)/org.kde.plasma.icontasks.so"
            restore_backup "/var/lib/windows-modern/backup/plasmoids/org.kde.plasma.icontasks" \
                           "/usr/share/plasma/plasmoids/org.kde.plasma.icontasks"
            rm_path "$HOME/.local/share/plasma/plasmoids/org.kde.plasma.icontasks"
            rm_path "$HOME/.local/lib64/qt6/plugins/plasma/applets/org.kde.plasma.icontasks.so"
            rm_path "$HOME/.local/lib/qt6/plugins/plasma/applets/org.kde.plasma.icontasks.so"
            uninstalled_msg "$failures_before" "Icon Tasks uninstalled; stock icons-only task manager restored. Restart plasmashell to complete."
            ;;
        digitalclock)
            rm_path "/usr/share/plasma/plasmoids/org.kde.windowsmodern.digitalclock"
            rm_path "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.digitalclock"
            info "Digital Clock uninstalled. Restart plasmashell to complete."
            ;;
        taskbarbuttons)
            rm_path "/usr/share/plasma/plasmoids/org.kde.windowsmodern.search"
            rm_path "/usr/share/plasma/plasmoids/org.kde.windowsmodern.taskview"
            rm_path "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.search"
            rm_path "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.taskview"
            info "Search and Task View buttons uninstalled. Restart plasmashell to remove any from your panel."
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
            if command -v kbuildsycoca6 &>/dev/null; then kbuildsycoca6 2>/dev/null || true; fi
            rm -rf ~/.cache/qmlcache ~/.cache/QtProject/qmlcache 2>/dev/null || true
            info "Session lock screen uninstalled. Breeze restored for Meta+L."
            # install-sessionlock.sh keeps up to two backups of the overlay it
            # replaced. They are never deleted automatically: the oldest may be
            # a custom overlay that existed before Windows Modern.
            local shells_dir="$HOME/.local/share/plasma/shells"
            if compgen -G "$shells_dir/org.kde.plasma.desktop.bak.*" >/dev/null; then
                step "Previous overlay backups kept in $shells_dir (org.kde.plasma.desktop.bak.*)."
                step "Delete them if you don't need them, or rename one back to restore it."
            fi
            ;;
        alttab)
            rm_path "$TABBOX_DIR/$ALT_TAB_LAYOUT"
            rm_path "/usr/share/kwin/tabbox/$ALT_TAB_LAYOUT"
            # Only reset the switcher if it is still ours; leave a layout the
            # user picked themselves alone.
            if command -v kreadconfig6 &>/dev/null && \
               [ "$(kreadconfig6 --file kwinrc --group TabBox --key LayoutName)" = "$ALT_TAB_LAYOUT" ]; then
                kwriteconfig6 --file kwinrc --group TabBox --key LayoutName --delete
                kwin_reconfigure
            fi
            info "Alt+Tab switcher uninstalled. KWin's default switcher restored."
            ;;
        greeter)
            # Revert any applied PLM patches and remove the user-level theme.
            PLM_DIR="$SRC_DIR/third_party/plasma-login-manager"
            PATCH_DIR="$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark/patches"
            if [ -d "${PLM_DIR}" ]; then
                # shellcheck disable=SC2043  # one patch today; the list may grow
                for p in main-cpp.patch; do
                    if [ -f "${PATCH_DIR}/${p}" ]; then
                        if patch -d "${PLM_DIR}" -p1 -R --dry-run -s -f < "${PATCH_DIR}/${p}" 2>/dev/null; then
                            patch -d "${PLM_DIR}" -p1 -R < "${PATCH_DIR}/${p}" 2>/dev/null || true
                        fi
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
        shortcuts)
            if busctl --user status org.kde.kglobalaccel &>/dev/null; then
                python3 "$SRC_DIR/scripts/windows-shortcuts.py" restore --group shortcuts || true
                stop_plasmashell
                python3 "$SRC_DIR/scripts/windows-shortcuts.py" tray-restore || true
                restart_plasmashell
            else
                warn "No Plasma session — log in and run ./uninstall.sh shortcuts to restore the keys."
            fi
            for pkg in "$SRC_DIR"/plasma/kwinscripts/*/; do
                id="$(basename "$pkg")"
                kwriteconfig6 --file kwinrc --group Plugins --key "${id}Enabled" --delete
                kpackagetool6 --type KWin/Script --remove "$id" &>/dev/null || true
            done
            kwriteconfig6 --file kwinrc --group Plugins --key minimizeallEnabled --delete
            kwin_reconfigure
            rm_path "$HOME/.local/share/applications/windowsmodern-screenshot.desktop"
            info "Windows shortcuts removed; your previous keys are back."
            ;;
        fonts)
            backup_dir="$HOME/.local/share/windows-modern/backup"
            for key in font fixed; do
                [ -f "$backup_dir/kdeglobals.$key" ] || continue
                old="$(cat "$backup_dir/kdeglobals.$key")"
                if [ -n "$old" ]; then
                    kwriteconfig6 --notify --group General --key "$key" "$old"
                else
                    kwriteconfig6 --notify --group General --key "$key" --delete
                fi
                rm -f "$backup_dir/kdeglobals.$key"
            done
            rm_path "$HOME/.config/fontconfig/conf.d/60-windows-modern-segoe.conf"
            rm_path "$HOME/.config/fontconfig/conf.d/20-windows-modern-greyscale.conf"
            rm_path "$HOME/.config/plasma-workspace/env/windows-modern-greyscale-text.sh"
            rm_path "$HOME/.local/share/fonts/selawik"
            fc-cache &>/dev/null || true
            info "Fonts restored. Cascadia Mono stays installed (remove it with your package manager)."
            ;;
        apps)
            backup_dir="$HOME/.local/share/windows-modern/backup"
            if [ -f "$backup_dir/spectaclerc.General" ]; then
                while IFS='=' read -r k v; do
                    if [ -n "$v" ]; then
                        kwriteconfig6 --file spectaclerc --group General --key "$k" "$v"
                    else
                        kwriteconfig6 --file spectaclerc --group General --key "$k" --delete
                    fi
                done < "$backup_dir/spectaclerc.General"
                rm -f "$backup_dir/spectaclerc.General"
            fi
            if [ -f "$backup_dir/mimeapps.list" ]; then
                mv "$backup_dir/mimeapps.list" "$HOME/.config/mimeapps.list"
            elif [ -f "$backup_dir/mimeapps.list.none" ]; then
                rm -f "$HOME/.config/mimeapps.list" "$backup_dir/mimeapps.list.none"
            fi
            ui="$HOME/.local/share/kxmlgui5/dolphin/dolphinui.rc"
            if [ -f "$backup_dir/dolphinui.rc.ours" ]; then
                rm_path "$ui"
                rm -f "$backup_dir/dolphinui.rc.ours"
            fi
            if busctl --user status org.kde.kglobalaccel &>/dev/null; then
                python3 "$SRC_DIR/scripts/windows-shortcuts.py" restore --group apps || true
            fi
            info "App defaults restored. Haruna, KWrite and Mission Center stay installed;"
            info "remove them with your package manager / flatpak if you want."
            ;;
        all)
            for c in shortcuts apps fonts themes icons lookfeel layout showdesk startmenu systray icontasks digitalclock taskbarbuttons sessionlock alttab greeter; do
                uninstall_component "$c"
            done
            reset_kwin_borders
            offer_original_settings
            ;;
        *)
            err "Unknown component: $name"
            echo "Available: themes, icons, lookfeel, layout, showdesk, startmenu, systray, icontasks, digitalclock, taskbarbuttons, sessionlock, alttab, shortcuts, apps, fonts, greeter, greetersystem, all"
            exit 1
            ;;
    esac
}

# After a full uninstall: put back the Plasma settings from before
# Windows Modern, if a snapshot of them exists (asks first).
offer_original_settings() {
    local original
    original="$(wm_backup_original)" || return 0
    if is_interactive; then
        local answer
        read -r -p "Put back your Plasma settings from $original (before Windows Modern was installed)? [Y/n] " answer
        case "$answer" in
            [nN]*) info "Kept. Later: ./uninstall.sh --restore" ;;
            *) restore_backup_snapshot "$original" ;;
        esac
    else
        info "Your Plasma settings from before Windows Modern are saved: ./uninstall.sh --restore"
    fi
}

case "${1:-}" in
    --list-backups)
        list_backups
        exit 0
        ;;
    --restore)
        restore_backup_snapshot "${2:-}"
        exit $?
        ;;
    --help|-h|"")
        echo "Usage: ./uninstall.sh [component]"
        echo "  (no args)  Show help"
        echo "  all        Uninstall everything (then offers your settings from before Windows Modern)"
        echo "  --list-backups   Saved Plasma settings (one is taken whenever install.sh runs)"
        echo "  --restore [ID]   Put saved settings back (default: from before Windows Modern)"
        echo "  themes     Themes (Aurorae, colors, Kvantum, Plasma, wallpapers)"
        echo "  icons      Icon pack"
        echo "  lookfeel   Global themes"
        echo "  layout     Panel layout template"
        echo "  showdesk   Show Desktop applet"
        echo "  startmenu  Start Menu applet"
    echo "  systray    System Tray"
    echo "  icontasks  Icon Tasks taskbar"
    echo "  digitalclock Digital Clock"
    echo "  taskbarbuttons Search and Task View buttons"
    echo "  sessionlock Session lock screen (Meta+L)"
    echo "  alttab     Alt+Tab window switcher"
    echo "  shortcuts  Windows keyboard shortcuts (previous keys restored)"
    echo "  apps       App defaults (video player, Snipping Tool, Ctrl+Shift+Esc)"
    echo "  fonts      Previous UI and monospace fonts back"
    echo "  greeter    Boot greeter (user theme + revert patches)"
    echo "  greetersystem Restore system greeter binary (needs sudo)"
    echo "  all        Uninstall everything"
    exit 0
    ;;
    *)
        uninstall_component "$1"
        ;;
esac
