#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-digitalclock.sh — Digital Clock applet (pure QML)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.digitalclock"
[ -d "$src" ] || { warn "Digital Clock not found — skipping."; exit 0; }

info "Installing Digital Clock (Windows Modern) applet..."
ensure_dir "$APPLETS_DIR"
rm -rf "$APPLETS_DIR/org.kde.windowsmodern.digitalclock"
cp -r "$src" "$APPLETS_DIR/"
info "Digital Clock (Windows Modern) installed."

# Refresh sycoca so the new applet is discoverable; restart Plasma Shell
# so it shows up in the running session. In batch mode the parent 'all'
# driver does this once at the end.
if is_batch; then
    exit 0
fi

command -v kbuildsycoca6 &>/dev/null && kbuildsycoca6 2>/dev/null || true
if pgrep -x plasmashell >/dev/null 2>&1; then
    restart_plasmashell
else
    warn "Plasma Shell not running — Digital Clock will load on next session."
fi
