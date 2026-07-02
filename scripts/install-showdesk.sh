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
