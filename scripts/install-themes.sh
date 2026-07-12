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

step "Kvantum theme selection"
if [ "$UID" -ne 0 ]; then
    # Kvantum reads ~/.config/Kvantum/kvantum.kvconfig (capital K), not ~/.config/kvantum.kvconfig.
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file Kvantum/kvantum.kvconfig --group General --key theme Windows-modern
    else
        ensure_dir "$HOME/.config/Kvantum"
        KVANTUM_CONFIG="$HOME/.config/Kvantum/kvantum.kvconfig"
        if [ -f "$KVANTUM_CONFIG" ] && grep -q "^theme=" "$KVANTUM_CONFIG"; then
            sed -i 's/^theme=.*/theme=Windows-modern/' "$KVANTUM_CONFIG"
        else
            echo "[General]" > "$KVANTUM_CONFIG"
            echo "theme=Windows-modern" >> "$KVANTUM_CONFIG"
        fi
    fi
    # Remove stray config written by earlier versions of this installer.
    [ -f "$HOME/.config/kvantum.kvconfig" ] && rm -f "$HOME/.config/kvantum.kvconfig"
else
    warn "Installed system-wide: select Windows-modern in Kvantum Manager"
fi

step "Plasma desktop themes"
ensure_dir "$PLASMA_DIR"
rm -rf "$PLASMA_DIR/Windows-modern"*
cp -r "$SRC_DIR/plasma/desktoptheme/"* "$PLASMA_DIR/"

step "Wallpapers"
ensure_dir "$WALLPAPER_DIR"
rm -rf "$WALLPAPER_DIR/Windows-modern"*
cp -r "$SRC_DIR/wallpaper/"* "$WALLPAPER_DIR/"

info "Themes installed."
