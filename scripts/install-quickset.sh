#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-quickset.sh — Quick Settings applet (pure QML)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.quicksettings"
[ -d "$src" ] || { warn "Quick Settings not found — skipping."; exit 0; }

info "Installing Quick Settings applet..."
ensure_dir "$APPLETS_DIR"
rm -rf "$APPLETS_DIR/org.kde.windowsmodern.quicksettings"
cp -r "$src" "$APPLETS_DIR/"
info "Quick Settings installed."
