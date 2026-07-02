#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-icons.sh — Windows Modern icon pack
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

if [ ! -d "$SRC_DIR/icons/windows-modern" ]; then
    warn "Icon pack not found at icons/windows-modern — skipping."
    exit 0
fi

info "Installing icon pack..."
step "Copying icons"
ensure_dir "$ICONS_DIR"
rm -rf "$ICONS_DIR/windows-modern"
cp -r "$SRC_DIR/icons/windows-modern" "$ICONS_DIR/"

if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f "$ICONS_DIR/windows-modern" &>/dev/null || true
fi

info "Icons installed."
