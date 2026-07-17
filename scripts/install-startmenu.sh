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
# the running session. In batch mode the parent 'all' driver restarts
# once at the end; standalone we restart now (no prompt).
if is_batch; then
    exit 0
fi

if ! pgrep -x plasmashell >/dev/null 2>&1; then
    warn "Plasma Shell not running — Start Menu will load on next session."
    exit 0
fi

if ! is_interactive; then
    info "Non-interactive install — restarting Plasma Shell to apply."
    restart_plasmashell
    exit 0
fi

restart_plasmashell
