#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-apps.sh — the everyday apps a Windows user reaches for
#
#    Media Player   Haruna (Qt, follows the theme), default for video
#    Notepad        KWrite (installed; your text-file default is kept)
#    Task Manager   Mission Center (Flathub, per user), on Ctrl+Shift+Esc
#    Snipping Tool  Spectacle: PrtSc / Win+Shift+S select a region; on
#                   release it is copied and saved to Pictures/Screenshots
#    Explorer       Dolphin gets an Up button next to Back/Forward
#    Fonts          Cascadia Mono, Windows 11's monospace font (OFL), as the
#                   fixed-width font unless you picked your own
#
#  Previous defaults are backed up; ./uninstall.sh apps restores them
#  (the apps themselves stay installed).
# ───────────────────────────────────────────────────────────────────
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

if [ "$UID" -eq 0 ]; then
    warn "Apps are set up per user — run this as yourself, not root. Skipping."
    exit 0
fi

BACKUP_DIR="$HOME/.local/share/windows-modern/backup"
ensure_dir "$BACKUP_DIR"

info "Setting up apps..."

# 1. Distro packages (one password prompt if anything is missing).
if command -v dnf &>/dev/null; then cascadia="cascadia-mono-fonts"
elif command -v apt-get &>/dev/null; then cascadia="fonts-cascadia-code"
elif command -v pacman &>/dev/null; then cascadia="ttf-cascadia-code"
else cascadia=""; fi
install_packages haruna kwrite ${cascadia:+"$cascadia"} || warn "Some apps were not installed."

# 2. Mission Center from Flathub, per user (no password).
if command -v flatpak &>/dev/null; then
    step "Mission Center (Flathub)"
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install --user --noninteractive flathub io.missioncenter.MissionCenter \
        || warn "Mission Center could not be installed."
    # Let KDE's service index see the new launcher (for Ctrl+Shift+Esc).
    command -v kbuildsycoca6 &>/dev/null && kbuildsycoca6 &>/dev/null || true
else
    warn "flatpak not found — Mission Center skipped."
fi

# 3. Haruna as the video player (Windows: Media Player).
haruna_desktop="$(ls /usr/share/applications/org.kde.haruna.desktop 2>/dev/null || true)"
if [ -n "$haruna_desktop" ]; then
    step "Haruna is the default video player"
    [ -f "$BACKUP_DIR/mimeapps.list" ] || cp "$HOME/.config/mimeapps.list" "$BACKUP_DIR/mimeapps.list" 2>/dev/null \
        || touch "$BACKUP_DIR/mimeapps.list.none"
    mapfile -t video_types < <(grep -m1 '^MimeType=' "$haruna_desktop" | cut -d= -f2 | tr ';' '\n' | grep '^video/')
    # (xdg-mime looks for "qtpaths", which Fedora calls qtpaths6; it works anyway)
    [ "${#video_types[@]}" -gt 0 ] && xdg-mime default org.kde.haruna.desktop "${video_types[@]}" 2>/dev/null
fi

# 4. Spectacle behaves like the Snipping Tool.
step "Spectacle: capture on release, copy and save"
spectacle_keys=(useReleaseToCapture autoSaveImage clipboardGroup)
if [ ! -f "$BACKUP_DIR/spectaclerc.General" ]; then
    for k in "${spectacle_keys[@]}"; do
        echo "$k=$(kreadconfig6 --file spectaclerc --group General --key "$k")"
    done > "$BACKUP_DIR/spectaclerc.General"
fi
kwriteconfig6 --file spectaclerc --group General --key useReleaseToCapture true
kwriteconfig6 --file spectaclerc --group General --key autoSaveImage true
kwriteconfig6 --file spectaclerc --group General --key clipboardGroup PostScreenshotCopyImage

# 5. Explorer (Dolphin): an Up button next to Back/Forward, only if there is
#    no toolbar layout yet. Dolphin rewrites the file (dropping comments), so
#    a note in the backup folder records that it is ours, for uninstall.
ui="$HOME/.local/share/kxmlgui5/dolphin/dolphinui.rc"
if [ ! -f "$ui" ]; then
    step "Explorer: Up button in the toolbar"
    ensure_dir "$(dirname "$ui")"
    cp "$SRC_DIR/config/kxmlgui5/dolphin/dolphinui.rc" "$ui"
    touch "$BACKUP_DIR/dolphinui.rc.ours"
elif [ -f "$BACKUP_DIR/dolphinui.rc.ours" ]; then
    step "Explorer: toolbar layout already set up (kept as it is)"
else
    step "Explorer: keeping your own toolbar layout"
fi

# 6. Cascadia Mono as the fixed-width font, unless you chose your own.
fixed="$(kreadconfig6 --group General --key fixed)"
fc-cache &>/dev/null || true # a font installed a moment ago may not be listed yet
# (no "| grep -q": with pipefail, grep quitting early fails the pipeline)
if [ -n "$(fc-list "Cascadia Mono" family)" ]; then
    case "${fixed%%,*}" in
        ""|"Noto Sans Mono"|"Hack"|"DejaVu Sans Mono"|"Monospace"|"Liberation Mono")
            step "Monospace font: Cascadia Mono"
            [ -f "$BACKUP_DIR/kdeglobals.fixed" ] || echo "$fixed" > "$BACKUP_DIR/kdeglobals.fixed"
            kwriteconfig6 --notify --group General --key fixed "Cascadia Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
            ;;
        "Cascadia Mono") ;;
        *) step "Monospace font: keeping your ${fixed%%,*}" ;;
    esac
fi

# 7. Ctrl+Shift+Esc opens Mission Center.
if busctl --user status org.kde.kglobalaccel &>/dev/null; then
    step "Ctrl+Shift+Esc: Mission Center"
    python3 "$SRC_DIR/scripts/windows-shortcuts.py" apply --group apps || warn "Ctrl+Shift+Esc not set."
else
    warn "No Plasma session — run ./install.sh apps again after logging in for Ctrl+Shift+Esc."
fi

info "Apps set up."
