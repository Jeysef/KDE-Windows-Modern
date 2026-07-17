#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-lookfeel.sh — Global themes (dark & light)
#
#  Standalone: asks Light/Dark, then applies the chosen theme with a
#  layout reset (so panels/widgets are rebuilt) + wallpaper + Kvantum.
#  In batch mode (WM_BATCH=1): installs files only — the parent 'all'
#  driver performs the single apply at the end.
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

# ── Batch: files only — parent applies at the end ──────────────────
if is_batch; then
    exit 0
fi

# ── Standalone: ask Light/Dark and apply ───────────────────────────
if [ "$UID" -eq 0 ]; then
    warn "Running as root — apply the theme manually from a user session."
    warn "  System Settings → Appearance → Global Theme."
    exit 0
fi

if ! command -v plasma-apply-lookandfeel &>/dev/null; then
    warn "plasma-apply-lookandfeel not found — apply manually in System Settings."
    exit 0
fi

if ! is_interactive; then
    info "Non-interactive install. Theme files are in place."
    info "To apply:  plasma-apply-lookandfeel -a org.kde.windowsmodern.dark --resetLayout"
    info "       or:  plasma-apply-lookandfeel -a org.kde.windowsmodern.light --resetLayout"
    info "Then set the wallpaper:  bash $SRC_DIR/scripts/set-wallpaper.sh"
    exit 0
fi

variant="$(ask_theme_variant)"
theme="$(lookfeel_id "$variant")"

apply_lookandfeel "$theme" reset
apply_kvantum_engine "$variant"

echo ""
info "Done. If panels do not appear, run:"
info "  killall plasmashell && kstart6 plasmashell"
