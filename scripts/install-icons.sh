#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-icons.sh — Windows Modern icon pack
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

THEME_NAME="windows-modern"
SRC_DIR="$SRC_DIR/icons/$THEME_NAME"
THEME_DIR="$ICONS_DIR/$THEME_NAME"

if [ ! -d "$SRC_DIR" ]; then
    warn "Icon pack not found at $SRC_DIR"
    exit 1
fi

info "Installing icon pack ($THEME_NAME)..."
step "Removing old installation"
rm -rf "$THEME_DIR"

step "Copying $THEME_NAME"
ensure_dir "$ICONS_DIR"
cp -r "$SRC_DIR" "$THEME_DIR"

if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f "$THEME_DIR" &>/dev/null || true
fi

info "Icons installed ($THEME_NAME)"

# ── Apply icon theme instantly (same as System Settings) ───────────
# Skipped in batch mode — the parent 'all' driver applies the whole
# look-and-feel (which sets the icon theme via defaults) at the end.
if is_batch; then
    exit 0
fi
if command -v kwriteconfig6 &>/dev/null; then
    step "Applying icon theme ($THEME_NAME)"
    # Plasma 6 stores the theme in kcmicons; kdeglobals is the legacy fallback
    kwriteconfig6 --file kdeglobals --group Icons --key Theme "$THEME_NAME"
    kwriteconfig6 --file kcmicons --group Icons --key Theme "$THEME_NAME"

    if command -v kbuildsycoca6 &>/dev/null; then
        step "Refreshing KDE icon cache"
        kbuildsycoca6 --noincremental &>/dev/null || true
    fi
else
    warn "kwriteconfig6 not found — icon theme installed but not activated."
    warn "Set it manually in System Settings > Appearance > Icons."
fi
