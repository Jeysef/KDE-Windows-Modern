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
