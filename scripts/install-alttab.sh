#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-alttab.sh — Windows 11-style Alt+Tab (KWin window switcher)
#
#  Installs the KWin TabBox layout and selects it. Pure QML: no build,
#  no restart; KWin picks it up on reconfigure.
# ───────────────────────────────────────────────────────────────────
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

src="$SRC_DIR/plasma/windowswitcher/$ALT_TAB_LAYOUT"
[ -d "$src" ] || { err "Window switcher source not found at $src"; exit 1; }

info "Installing Windows Modern Alt+Tab switcher..."
ensure_dir "$TABBOX_DIR"
rm -rf "${TABBOX_DIR:?}/${ALT_TAB_LAYOUT:?}"
cp -r "$src" "$TABBOX_DIR/"
step "Installed to $TABBOX_DIR/$ALT_TAB_LAYOUT"

# In batch mode the 'all' driver selects it once at the end.
if is_batch; then
    exit 0
fi
post_kwin_alt_tab_switcher
info "Done. Press Alt+Tab to try it."
