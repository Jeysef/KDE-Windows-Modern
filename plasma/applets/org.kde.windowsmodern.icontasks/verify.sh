#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  verify.sh — check Icon Tasks is installed and working correctly
#
#  The fork deliberately reuses the stock plugin ID
#  (org.kde.plasma.icontasks). dev.sh moves the distro's stock KPackage
#  to /var/lib/windows-modern/backup/ so it cannot shadow our .so, and
#  uninstall.sh puts it back. Exits 1 if any check fails.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

APP_ID="org.kde.plasma.icontasks"
PLUGIN_DIR=""
if command -v pkg-config &>/dev/null; then
    PLUGIN_DIR=$(pkg-config --variable=plugindir Qt6Core 2>/dev/null || true)
fi
if [ -z "$PLUGIN_DIR" ]; then
    if [ -d /usr/lib64/qt6/plugins ]; then PLUGIN_DIR=/usr/lib64/qt6/plugins
    else PLUGIN_DIR=/usr/lib/qt6/plugins
    fi
fi
SO_PATH="${PLUGIN_DIR}/plasma/applets/${APP_ID}.so"
KPACKAGE_PATH="/usr/share/plasma/plasmoids/${APP_ID}"
KPACKAGE_BACKUP="/var/lib/windows-modern/backup/plasmoids/${APP_ID}"
LOCAL_KPACKAGE="$HOME/.local/share/plasma/plasmoids/${APP_ID}"
LAYOUT_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

RED="\033[31m"; GREEN="\033[32m"; RESET="\033[0m"
FAILED=0
pass() { echo -e "  ${GREEN}✓${RESET} $1"; }
fail() { echo -e "  ${RED}✗${RESET} $1"; FAILED=1; }

echo ""
echo "Icon Tasks — health check"
echo "========================="
echo ""

# 1. .so file
if [ -f "$SO_PATH" ]; then
    pass ".so installed at $SO_PATH"
else
    fail ".so NOT FOUND at $SO_PATH — run ./install.sh icontasks"
fi

# 2. Stray local copies take precedence over the system plugin
STALE=0
for stale in "$HOME/.local/lib64/qt6/plugins/plasma/applets/${APP_ID}.so" \
             "$HOME/.local/lib/qt6/plugins/plasma/applets/${APP_ID}.so" \
             "$HOME/.local/lib64/qt6/plugins/plasma/applets/org.kde.windowsmodern.icontasks.so" \
             "$HOME/.local/lib/qt6/plugins/plasma/applets/org.kde.windowsmodern.icontasks.so" \
             "$LOCAL_KPACKAGE"; do
    if [ -e "$stale" ]; then
        fail "Stale local copy shadows the system plugin: $stale"
        STALE=1
    fi
done
[ "$STALE" -eq 0 ] && pass "No stale local copies"

# 3. Stock KPackage must be moved aside (it shadows the fork's .so)
if [ -f "$SO_PATH" ]; then
    if [ -d "$KPACKAGE_PATH" ]; then
        fail "Stock KPackage present at $KPACKAGE_PATH (a distro update may have restored it)"
        echo "       Re-run ./install.sh icontasks to move it aside again."
    else
        pass "Stock KPackage moved aside"
    fi
    if [ -d "$KPACKAGE_BACKUP" ]; then
        pass "Stock KPackage backup present (restored by ./uninstall.sh icontasks)"
    else
        fail "No backup of the stock KPackage at $KPACKAGE_BACKUP"
        echo "       Uninstalling will need: sudo dnf reinstall plasma-desktop  (or your distro's equivalent)"
    fi
fi

# 4. Layout config
if grep -q "plugin=${APP_ID}" "$LAYOUT_FILE" 2>/dev/null; then
    pass "Panel layout includes ${APP_ID}"
else
    fail "${APP_ID} not in panel layout"
fi
if grep -q "plugin=org.kde.windowsmodern.icontasks" "$LAYOUT_FILE" 2>/dev/null; then
    fail "Layout still references the legacy ID org.kde.windowsmodern.icontasks — run ./dev.sh to migrate"
fi
if grep -q "plugin=metadata" "$LAYOUT_FILE" 2>/dev/null; then
    fail "Corrupted plugin=metadata entry in layout — will cause loading error"
else
    pass "No corrupted plugin=metadata"
fi

# 5. The .so is our fork (the fork registers the FloatingToolTipArea type)
if [ -f "$SO_PATH" ]; then
    if nm -DC "$SO_PATH" 2>/dev/null | grep -c "FloatingToolTipArea" >/dev/null; then
        pass "Plugin is the Windows Modern fork"
    else
        fail "Plugin at $SO_PATH is not the Windows Modern fork"
    fi
fi

# 6. Recent errors (needs a running user session; reports 0 otherwise)
errors=$(journalctl --user -u plasma-plasmashell.service --since "1 minute ago" --no-pager 2>/dev/null \
    | grep -c "error.*${APP_ID}\|Cannot load.*${APP_ID}\|undefined symbol.*${APP_ID}" || true)
if [ "${errors:-0}" -eq 0 ]; then
    pass "No recent loading errors in plasmashell"
else
    fail "$errors recent loading errors in plasmashell"
fi

echo ""
if [ "$FAILED" -ne 0 ]; then
    echo "To fix issues: ./install.sh icontasks  (or: cd plasma/applets/org.kde.windowsmodern.icontasks && ./dev.sh)"
    exit 1
fi
echo "Icon Tasks OK."
