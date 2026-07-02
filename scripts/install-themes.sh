#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-themes.sh — Aurorae, color-schemes, Kvantum, Plasma, wallpapers
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

info "Installing themes..."

step "Window decorations (Aurorae)"
ensure_dir "$AURORAE_DIR"
cp -r "$SRC_DIR/aurorae/"* "$AURORAE_DIR/"

step "Color schemes"
ensure_dir "$SCHEMES_DIR"
cp -r "$SRC_DIR/color-schemes/"*.colors "$SCHEMES_DIR/"

step "Kvantum themes"
ensure_dir "$KVANTUM_DIR"
cp -r "$SRC_DIR/Kvantum/"* "$KVANTUM_DIR/"

step "Plasma desktop themes"
ensure_dir "$PLASMA_DIR"
cp -r "$SRC_DIR/plasma/desktoptheme/"* "$PLASMA_DIR/"

step "Wallpapers"
ensure_dir "$WALLPAPER_DIR"
cp -r "$SRC_DIR/wallpaper/"* "$WALLPAPER_DIR/"

if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file Kvantum/kvantum.kvconfig --group General --key theme Windows-modern-light
fi

info "Themes installed."
