#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-lookfeel.sh — Global themes (dark & light)
#
#  When invoked as part of 'install.sh all', the parent script handles
#  theme application. This script only installs the files unless run
#  standalone (interactive).
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

APPLY_TOOL="plasma-apply-lookandfeel"

info "Installing global themes (look-and-feel)..."

step "Dark theme"
ensure_dir "$LOOKFEEL_DIR"
rm -rf "$LOOKFEEL_DIR/org.kde.windowsmodern.dark"
cp -r "$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark" "$LOOKFEEL_DIR/"

step "Light theme"
rm -rf "$LOOKFEEL_DIR/org.kde.windowsmodern.light"
cp -r "$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.light" "$LOOKFEEL_DIR/"

info "Global themes installed."

# ── Apply theme (standalone only — 'all' applies after all components) ─
if [ "$UID" -eq 0 ]; then
    warn "Running as root — skipping automatic theme apply."
    warn "Apply manually from a user session: System Settings → Appearance → Global Theme."
    exit 0
fi

if ! command -v "$APPLY_TOOL" &>/dev/null; then
    warn "$APPLY_TOOL not found — skipping automatic theme apply."
    warn "Apply manually: System Settings → Appearance → Global Theme."
    exit 0
fi

if [ ! -t 0 ]; then
    info "Non-interactive install. Theme files are in place."
    info "To apply: $APPLY_TOOL -a org.kde.windowsmodern.light --resetLayout"
    info "    or:  $APPLY_TOOL -a org.kde.windowsmodern.dark --resetLayout"
    info "Then set the wallpaper:  bash $SRC_DIR/scripts/set-wallpaper.sh"
    exit 0
fi

echo ""
echo -e "${BOLD}Apply theme now?${RESET}"
echo -e "  ${BOLD}1${RESET}) Light  (org.kde.windowsmodern.light)"
echo -e "  ${BOLD}2${RESET}) Dark   (org.kde.windowsmodern.dark)"
echo -e "  ${BOLD}3${RESET}) Do not apply"
echo ""
read -r -p "Choice [1]: " theme_choice
theme_choice="${theme_choice:-1}"

case "$theme_choice" in
    1|light|Light)
        theme="org.kde.windowsmodern.light"
        ;;
    2|dark|Dark)
        theme="org.kde.windowsmodern.dark"
        ;;
    3|none|no|n|N)
        info "Theme not applied. Apply later with System Settings."
        exit 0
        ;;
    *)
        err "Invalid choice."
        exit 1
        ;;
esac

echo ""
echo -e "${BOLD}Replace current desktop layout (panels/widgets) with the Windows Modern layout?${RESET}"
echo -e "  ${BOLD}1${RESET}) Yes — reset layout and create the panel(s)"
echo -e "  ${BOLD}2${RESET}) No  — apply theme only (colors, icons, window decorations)"
echo ""
read -r -p "Choice [1]: " layout_choice
layout_choice="${layout_choice:-1}"

case "$layout_choice" in
    1|yes|y|Y|"")
        info "Applying $theme with layout reset..."
        "$APPLY_TOOL" -a "$theme" --resetLayout
        ;;
    2|no|n|N)
        info "Applying $theme without layout reset..."
        "$APPLY_TOOL" -a "$theme"
        ;;
    *)
        err "Invalid choice."
        exit 1
        ;;
esac

# Set the wallpaper — Plasma's look-and-feel apply does not set it.
step "Wallpaper"
bash "$SRC_DIR/scripts/set-wallpaper.sh" || true

echo ""
info "Done. If panels do not appear, run:"
info "  killall plasmashell && kstart6 plasmashell"
