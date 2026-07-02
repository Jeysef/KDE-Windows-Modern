#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-startmenu.sh — Start Menu applet (pure QML)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.startmenu"
[ -d "$src" ] || { warn "Start Menu not found — skipping."; exit 0; }

info "Installing Start Menu applet..."
ensure_dir "$APPLETS_DIR"
rm -rf "$APPLETS_DIR/org.kde.windowsmodern.startmenu"
cp -r "$src" "$APPLETS_DIR/"
info "Start Menu installed."
