#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-shortcuts.sh — Windows keyboard shortcuts and window behaviour
#
#  Win+Up/Down (maximize, restore, minimize, quarter snap), Win+Tab Task
#  View, Win+R Run, Win+M / Win+Home minimize, Win+A Quick Settings,
#  Win+N notifications, Win+PrtSc / Alt+PrtSc screenshots. The previous
#  keys are backed up; ./uninstall.sh shortcuts restores them.
#  Also installs the KWin scripts in plasma/kwinscripts/ (Win+Up/Down;
#  volume/brightness pop-ups above the taskbar).
# ───────────────────────────────────────────────────────────────────
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

if [ "$UID" -eq 0 ]; then
    warn "Shortcuts are per user — run this as yourself, not root. Skipping."
    exit 0
fi
if ! busctl --user status org.kde.kglobalaccel &>/dev/null; then
    warn "No Plasma session (kglobalaccel) — log in to Plasma and run: ./install.sh shortcuts"
    exit 0
fi

info "Installing Windows keyboard shortcuts..."

# 1. Our KWin scripts (Win+Up/Down, OSD position) and KWin's "Minimize all".
for pkg in "$SRC_DIR"/plasma/kwinscripts/*/; do
    id="$(basename "$pkg")"
    step "KWin script: $id"
    kpackagetool6 --type KWin/Script --upgrade "$pkg" &>/dev/null \
        || kpackagetool6 --type KWin/Script --install "$pkg" >/dev/null
    kwriteconfig6 --file kwinrc --group Plugins --key "${id}Enabled" true
done
kwriteconfig6 --file kwinrc --group Plugins --key minimizeallEnabled true
kwin_reconfigure
sleep 2 # the scripts register their shortcut actions

# 2. Launcher for Win+PrtSc (full screen, saved without opening Spectacle).
ensure_dir "$HOME/.local/share/applications"
cp "$SRC_DIR/config/applications/windowsmodern-screenshot.desktop" "$HOME/.local/share/applications/"
if command -v kbuildsycoca6 &>/dev/null; then kbuildsycoca6 &>/dev/null || true; fi

# 3. Global shortcuts.
step "Global shortcuts"
python3 "$SRC_DIR/scripts/windows-shortcuts.py" apply --group shortcuts \
    || warn "Some shortcuts could not be set (see FAILED above)."

# 4. Win+A / Win+N live in the panel's config, which Plasma rewrites on exit.
step "Tray: Win+A Quick Settings, Win+N notifications"
stop_plasmashell
python3 "$SRC_DIR/scripts/windows-shortcuts.py" tray-apply || warn "Tray shortcuts not set."
restart_plasmashell

info "Windows shortcuts installed."
