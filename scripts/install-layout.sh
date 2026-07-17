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

# Refresh sycoca so the template is discoverable in "Add Panel".
command -v kbuildsycoca6 &>/dev/null && kbuildsycoca6 2>/dev/null || true

info "Panel layout installed."

# Layout templates cannot replace the panel by themselves — that requires
# the global theme's --resetLayout (handled by install-lookfeel.sh / 'all').
if is_batch; then
    exit 0
fi

echo ""
info "To use it: right-click the desktop → Add Panel → Windows Modern Panel."
echo -e "  ${BOLD}Tip:${RESET} For the authentic Win11 look, after adding the panel:"
echo -e "  Right-click panel → Show Panel Configuration → Floating → Applets Only"
echo -e "  (Plasma's scripting API can't set this automatically.)"
