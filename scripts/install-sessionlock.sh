#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-sessionlock.sh — Session lock screen (Meta+L / kscreenlocker)
#
#  kscreenlocker resolves the lock screen from the CURRENT desktop shell
#  package (org.kde.plasma.desktop). To theme Meta+L we create a COMPLETE
#  user-level overlay of that shell: symlink every system directory EXCEPT
#  lockscreen, which we replace with our custom Windows Modern files.
#
#  The shell MUST remain complete. An incomplete shell triggers the ugly
#  Qt widget fallback. On uninstall, delete the ENTIRE user shell dir.
# ───────────────────────────────────────────────────────────────────
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

SHELL_SRC="$SRC_DIR/plasma/shells/org.kde.windowsmodern.lockscreen"
USER_SHELLS="$HOME/.local/share/plasma/shells"
OVERLAY_SHELL="$USER_SHELLS/org.kde.plasma.desktop"
# WM_SYSTEM_SHELL overrides the system shell path for sandboxed tests only.
SYSTEM_SHELL="${WM_SYSTEM_SHELL:-/usr/share/plasma/shells/org.kde.plasma.desktop}"
SYSTEM_LOCKSCREEN="$SYSTEM_SHELL/contents/lockscreen"

info "Installing Windows Modern session lock screen (Meta+L)..."

# ── 1. Sanity-check system shell exists ──
if [ ! -d "$SYSTEM_SHELL" ]; then
    err "System shell not found at $SYSTEM_SHELL"
    err "This theme requires the default Plasma desktop shell package."
    exit 1
fi

[ -d "${SHELL_SRC}/contents/lockscreen" ] || {
    err "Custom lockscreen source not found at ${SHELL_SRC}/contents/lockscreen"
    exit 1
}

# The overlay is built in a hidden staging dir and only renamed into place
# once it is complete, so a failed or interrupted install never leaves an
# incomplete shell behind (which would trigger the Qt widget fallback).
mkdir -p "$USER_SHELLS"
STAGING_SHELL="$USER_SHELLS/.org.kde.plasma.desktop.staging.$$"
cleanup_staging() { rm -rf "$STAGING_SHELL"; }
trap cleanup_staging EXIT

# ── 2. Build user shell in staging: symlinks to system for everything EXCEPT lockscreen ──
step "Creating user shell overlay..."
mkdir -p "$STAGING_SHELL/contents"

# Copy metadata so KPackage sees this as a valid shell package
cp "$SYSTEM_SHELL/metadata.json" "$STAGING_SHELL/"

# Symlink every directory/file under contents EXCEPT lockscreen, which is
# ours, and logout, which is copied: the logout screen
# (ksmserver-logout-greeter) resolves symlinks and refuses files outside the
# package folder ("Path traversal attempt detected"), so with a symlink
# Log out did nothing. A copy can go stale when Plasma updates its logout
# screen: verify-all.sh --installed compares it with the system's, and
# re-running this installer refreshes it.
for item in "$SYSTEM_SHELL/contents/"*; do
    base=$(basename "$item")
    case "$base" in
        lockscreen) continue ;;
        logout) cp -r "$item" "$STAGING_SHELL/contents/$base" ;;
        *) ln -s "$item" "$STAGING_SHELL/contents/$base" ;;
    esac
done

# ── 3. Copy our custom lockscreen files into the overlay ──
step "Copying custom lockscreen files..."
cp -r "${SHELL_SRC}/contents/lockscreen" "$STAGING_SHELL/contents/"

# Also grab any missing standard lockscreen files from the system shell (qmldir, config.xml)
for standard_file in qmldir config.xml; do
    if [ -f "$SYSTEM_LOCKSCREEN/$standard_file" ] && [ ! -f "$STAGING_SHELL/contents/lockscreen/$standard_file" ]; then
        cp "$SYSTEM_LOCKSCREEN/$standard_file" "$STAGING_SHELL/contents/lockscreen/"
    fi
done

# ── 4. Swap: back up the current overlay (if any), move staging into place ──
if [ -d "$OVERLAY_SHELL" ]; then
    BACKUP_NAME="org.kde.plasma.desktop.bak.$(date +%Y%m%d%H%M%S)"
    step "Backing up existing overlay → $BACKUP_NAME"
    mv "$OVERLAY_SHELL" "$USER_SHELLS/$BACKUP_NAME"
fi
mv "$STAGING_SHELL" "$OVERLAY_SHELL"
trap - EXIT

# Keep only the two most recent backups (timestamped names sort chronologically).
mapfile -t backups < <(find "$USER_SHELLS" -maxdepth 1 -name 'org.kde.plasma.desktop.bak.*' -printf '%f\n' | sort)
if [ "${#backups[@]}" -gt 2 ]; then
    for old in "${backups[@]:0:${#backups[@]}-2}"; do
        rm -rf "${USER_SHELLS:?}/$old"
    done
fi

# ── 5. Reset kscreenlockerrc so it doesn't point to a non-existent standalone shell ──
kwriteconfig6 --file kscreenlockerrc --group Greeter --key Theme --delete 2>/dev/null || true

# ── 6. Rebuild cache ──
kbuildsycoca6 2>/dev/null || true

# ── 7. Clear QML caches ──
rm -rf ~/.cache/qmlcache ~/.cache/QtProject/qmlcache 2>/dev/null || true

echo ""
info "Windows Modern session lock screen installed."
echo "  Press ${BOLD}Meta+L${RESET} to test."
echo ""
echo "  Test safely without locking:  /usr/libexec/kscreenlocker_greet --testing"
echo ""
warn "If you see the ugly Qt fallback, run:  ./uninstall.sh sessionlock"
warn "This restores Breeze immediately."
