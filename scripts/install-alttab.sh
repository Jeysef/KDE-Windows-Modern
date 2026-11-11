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
updating=false
[ -d "$TABBOX_DIR/$ALT_TAB_LAYOUT" ] && updating=true
rm -rf "${TABBOX_DIR:?}/${ALT_TAB_LAYOUT:?}"
cp -r "$src" "$TABBOX_DIR/"
step "Installed to $TABBOX_DIR/$ALT_TAB_LAYOUT"


# Remove leftover copies from tests/windowswitcher/e2e.py that are not in use.
remove_unused_test_copies() {
    local current stale
    current="$(kreadconfig6 --file kwinrc --group TabBox --key LayoutName 2>/dev/null || true)"
    for stale in "$TABBOX_DIR/$ALT_TAB_LAYOUT".e2e*; do
        [ -d "$stale" ] || continue
        [ "$(basename "$stale")" = "$current" ] && continue
        rm -rf "$stale"
    done
}

# In batch mode the 'all' driver selects it once at the end.
if is_batch; then
    remove_unused_test_copies
    exit 0
fi
post_kwin_alt_tab_switcher
remove_unused_test_copies
info "Done. Press Alt+Tab to try it."
if [ "$updating" = true ]; then
    # KWin caches the compiled QML of a switcher it has already shown, keyed
    # by file path, for the rest of the session.
    warn "Updated an existing install: if Alt+Tab still shows the old version, log out and back in."
fi
