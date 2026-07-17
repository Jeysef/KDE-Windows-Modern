#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-showdesk.sh — Show Desktop applet (pure QML)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.showdesktop"
[ -d "$src" ] || { warn "Show Desktop not found — skipping."; exit 0; }

info "Installing Show Desktop applet..."
ensure_dir "$APPLETS_DIR"
rm -rf "$APPLETS_DIR/org.kde.windowsmodern.showdesktop"
cp -r "$src" "$APPLETS_DIR/"
info "Show Desktop installed."

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
    warn "Plasma Shell not running — Show Desktop will load on next session."
fi
