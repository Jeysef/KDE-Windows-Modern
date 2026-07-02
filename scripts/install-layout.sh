#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-layout.sh — Panel layout template
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

src="$SRC_DIR/plasma/layout-templates/org.kde.windowsmodern.panel"

if [ ! -d "$src" ]; then
    warn "Panel layout not found — skipping."
    exit 0
fi

info "Installing panel layout template..."
ensure_dir "$LAYOUT_DIR"
rm -rf "$LAYOUT_DIR/org.kde.windowsmodern.panel"
cp -r "$src" "$LAYOUT_DIR/"
info "Panel layout installed."
