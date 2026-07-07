#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-themes.sh — Aurorae, color-schemes, Kvantum, Plasma, wallpapers
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

info "Installing themes..."

step "Window decorations (Aurorae)"
ensure_dir "$AURORAE_DIR"
rm -rf "$AURORAE_DIR/Windows-modern"* "$AURORAE_DIR/__aurorae__svg__windows-modern"*
cp -r "$SRC_DIR/aurorae/"* "$AURORAE_DIR/"

step "Color schemes"
ensure_dir "$SCHEMES_DIR"
rm -f "$SCHEMES_DIR/WindowsModern"*.colors
cp -r "$SRC_DIR/color-schemes/"*.colors "$SCHEMES_DIR/"

step "Kvantum themes"
ensure_dir "$KVANTUM_DIR"
rm -rf "$KVANTUM_DIR/Windows-modern"*
cp -r "$SRC_DIR/Kvantum/"* "$KVANTUM_DIR/"

step "Plasma desktop themes"
ensure_dir "$PLASMA_DIR"
rm -rf "$PLASMA_DIR/Windows-modern"*
cp -r "$SRC_DIR/plasma/desktoptheme/"* "$PLASMA_DIR/"

step "Wallpapers"
ensure_dir "$WALLPAPER_DIR"
rm -rf "$WALLPAPER_DIR/Windows-modern"*
cp -r "$SRC_DIR/wallpaper/"* "$WALLPAPER_DIR/"

info "Themes installed."
