#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-lookfeel.sh — Global themes (dark & light)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

info "Installing global themes (look-and-feel)..."

step "Dark theme"
ensure_dir "$LOOKFEEL_DIR"
rm -rf "$LOOKFEEL_DIR/org.kde.windowsmodern.dark"
cp -r "$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark" "$LOOKFEEL_DIR/"

step "Light theme"
rm -rf "$LOOKFEEL_DIR/org.kde.windowsmodern.light"
cp -r "$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.light" "$LOOKFEEL_DIR/"

info "Global themes installed."
