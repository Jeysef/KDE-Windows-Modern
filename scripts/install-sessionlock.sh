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
source "$(dirname "$0")/install-lib.sh"

SHELL_SRC="$SRC_DIR/plasma/shells/org.kde.windowsmodern.lockscreen"
USER_SHELLS="$HOME/.local/share/plasma/shells"
OVERLAY_SHELL="$USER_SHELLS/org.kde.plasma.desktop"
SYSTEM_SHELL="/usr/share/plasma/shells/org.kde.plasma.desktop"
SYSTEM_LOCKSCREEN="$SYSTEM_SHELL/contents/lockscreen"

info "Installing Windows Modern session lock screen (Meta+L)..."

# ── 1. Sanity-check system shell exists ──
if [ ! -d "$SYSTEM_SHELL" ]; then
    err "System shell not found at $SYSTEM_SHELL"
    err "This theme requires the default Plasma desktop shell package."
    exit 1
fi

# ── 2. Backup and remove any broken/incomplete user shell override ──
if [ -d "$OVERLAY_SHELL" ]; then
    BACKUP_NAME="org.kde.plasma.desktop.bak.$(date +%Y%m%d%H%M%S)"
    step "Backing up existing overlay → $BACKUP_NAME"
    mv "$OVERLAY_SHELL" "$USER_SHELLS/$BACKUP_NAME"
fi

# ── 3. Re-create user shell with symlinks to system for everything EXCEPT lockscreen ──
step "Creating user shell overlay..."
mkdir -p "$OVERLAY_SHELL/contents"

# Copy metadata so KPackage sees this as a valid shell package
cp "$SYSTEM_SHELL/metadata.json" "$OVERLAY_SHELL/"

# Symlink every directory/file under contents EXCEPT lockscreen
for item in "$SYSTEM_SHELL/contents/"*; do
    base=$(basename "$item")
    if [ "$base" = "lockscreen" ]; then
        continue
    fi
    ln -s "$item" "$OVERLAY_SHELL/contents/$base"
done

# ── 4. Copy our custom lockscreen files into the overlay ──
if [ -d "${SHELL_SRC}/contents/lockscreen" ]; then
    step "Copying custom lockscreen files..."
    cp -r "${SHELL_SRC}/contents/lockscreen" "$OVERLAY_SHELL/contents/"
else
    err "Custom lockscreen source not found at ${SHELL_SRC}/contents/lockscreen"
    exit 1
fi

# Also grab any missing standard lockscreen files from the system shell (qmldir, config.xml)
for standard_file in qmldir config.xml; do
    if [ -f "$SYSTEM_LOCKSCREEN/$standard_file" ] && [ ! -f "$OVERLAY_SHELL/contents/lockscreen/$standard_file" ]; then
        cp "$SYSTEM_LOCKSCREEN/$standard_file" "$OVERLAY_SHELL/contents/lockscreen/"
    fi
done

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
