#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-startmenu.sh — Start Menu applet (pure QML)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.startmenu"
[ -d "$src" ] || { warn "Start Menu not found — skipping."; exit 0; }

info "Installing Start Menu applet..."

# Prefer kpackagetool6 so Plasma registers and can hot-reload the package.
if command -v kpackagetool6 &>/dev/null; then
    if kpackagetool6 --list --type Plasma/Applet 2>/dev/null | grep -q "org.kde.windowsmodern.startmenu"; then
        step "Upgrading existing package"
        kpackagetool6 --upgrade "$src" --type Plasma/Applet
    else
        step "Installing new package"
        kpackagetool6 --install "$src" --type Plasma/Applet
    fi
else
    warn "kpackagetool6 not found — falling back to manual copy."
    ensure_dir "$APPLETS_DIR"
    rm -rf "$APPLETS_DIR/org.kde.windowsmodern.startmenu"
    cp -r "$src" "$APPLETS_DIR/"
fi

info "Start Menu installed."

# Plasma Shell must be restarted for the updated applet to be reloaded in
# the running session. Only prompt when running interactively.
if ! pgrep -x plasmashell >/dev/null; then
    warn "Plasma Shell does not appear to be running — skipping reload."
    exit 0
fi

if [ ! -t 0 ]; then
    info "Non-interactive install. To reload the Start Menu, restart Plasma Shell:"
    info "  systemctl --user restart plasma-plasmashell.service"
    exit 0
fi

echo ""
echo -e "${BOLD}Restart Plasma Shell now to apply the updated Start Menu?${RESET}"
echo -e "  ${BOLD}1${RESET}) Yes"
echo -e "  ${BOLD}2${RESET}) No — apply later manually"
echo ""
read -r -p "Choice [1]: " restart_choice
restart_choice="${restart_choice:-1}"

case "$restart_choice" in
    1|yes|y|Y|"")
        if command -v systemctl &>/dev/null && systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null; then
            info "Restarting Plasma Shell..."
            systemctl --user restart plasma-plasmashell.service
        else
            info "Restarting Plasma Shell with killall/kstart6..."
            killall plasmashell 2>/dev/null || true
            kstart6 plasmashell &
        fi
        ;;
    *)
        info "Plasma Shell not restarted. Restart later with:"
        info "  systemctl --user restart plasma-plasmashell.service"
        ;;
esac
