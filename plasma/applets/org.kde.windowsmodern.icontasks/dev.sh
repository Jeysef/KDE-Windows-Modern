#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  Windows Modern Icon Tasks — dev cycle
#
#  The ONLY command to build and install this C++ applet.
#  Do NOT copy directories to ~/.local/share/plasma/plasmoids/
#  or /usr/share/plasma/plasmoids/ — that causes the dark rectangle.
#
#  Usage:  ./dev.sh
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SRC_DIR/build"
APP_ID="org.kde.plasma.icontasks"
LAYOUT_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
info()  { echo -e "${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "${YELLOW}==>${RESET} $*"; }
err()   { echo -e "${RED}==>${RESET} $*"; }

# ── Detect install paths ───────────────────────────────────────────
detect_paths() {
    if command -v pkg-config &>/dev/null; then
        QT_PLUGIN_DIR=$(pkg-config --variable=plugindir Qt6Core 2>/dev/null || true)
    fi
    if [ -z "${QT_PLUGIN_DIR:-}" ]; then
        if [ -d /usr/lib64/qt6/plugins ]; then
            QT_PLUGIN_DIR=/usr/lib64/qt6/plugins
        elif [ -d /usr/lib/qt6/plugins ]; then
            QT_PLUGIN_DIR=/usr/lib/qt6/plugins
        else
            QT_PLUGIN_DIR=/usr/lib64/qt6/plugins
        fi
    fi
    PLUGIN_DST="$QT_PLUGIN_DIR/plasma/applets"
    KPACKAGE_DIR="/usr/share/plasma/plasmoids/${APP_ID}"
    # The stock KPackage at KPACKAGE_DIR is owned by the distro's
    # plasma-desktop package. It must be moved aside (it would shadow our
    # .so), but kept somewhere restorable. The backup lives OUTSIDE the
    # plasmoids search path: its metadata.json declares the same plugin Id,
    # so a sibling copy would still be picked up by Plasma.
    KPACKAGE_BACKUP="/var/lib/windows-modern/backup/plasmoids/${APP_ID}"
}

# ── Build ─────────────────────────────────────────────────────────
# WM_PREBUILT_SO: a prebuilt plugin (from a release) to install instead
# of building; set by scripts/install-*.sh when one matches this system.
if [ -n "${WM_PREBUILT_SO:-}" ]; then
    info "Using prebuilt plugin (no build needed)."
else
    info "Building..."
    cmake -S "$SRC_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release > /dev/null
    cmake --build "$BUILD_DIR" --parallel "$(nproc)" 2>&1 | tail -3
fi

# ── Install .so only (no KPackage) ───────────────────────────────
# Installed while plasmashell still runs, so a cancelled password prompt
# leaves the session untouched.
info "Installing..."
PLUGIN_SRC="${WM_PREBUILT_SO:-$BUILD_DIR/lib/plasma/applets/${APP_ID}.so}"
detect_paths

[ -f "$PLUGIN_SRC" ] || { err "Build output not found: $PLUGIN_SRC"; exit 1; }

pkexec bash -s <<INSTALLEOF
set -e
mkdir -p "$PLUGIN_DST"
# install = new inode: a running plasmashell keeps its mapping of the
# old file instead of crashing on an in-place overwrite.
install -m 644 "$PLUGIN_SRC" "$PLUGIN_DST/"
command -v restorecon >/dev/null && restorecon "$PLUGIN_DST/$(basename "$PLUGIN_SRC")" || true
if [ -d "$KPACKAGE_DIR" ]; then
    if grep -q '"Windows Modern' "$KPACKAGE_DIR/metadata.json" 2>/dev/null; then
        # A stray KPackage copy of this fork (causes the dark-rectangle bug).
        rm -rf "$KPACKAGE_DIR"
    else
        # The distro's stock package: keep it restorable for uninstall.sh.
        # If a backup already exists (a distro update restored the stock
        # package since our last install), refresh it with the newer copy.
        mkdir -p "$(dirname "$KPACKAGE_BACKUP")"
        rm -rf "$KPACKAGE_BACKUP"
        mv "$KPACKAGE_DIR" "$KPACKAGE_BACKUP"
        echo "Stock KPackage moved aside to $KPACKAGE_BACKUP"
    fi
fi
echo "Installed."
INSTALLEOF

# ── Stop plasmashell (layout repairs need it stopped) ───────────
info "Stopping plasmashell..."
systemctl --user stop plasma-plasmashell.service 2>/dev/null || true
# Never leave the session without a shell if a later step fails. (On
# success the shell is started below, or by the batch driver.)
start_shell_on_failure() {
    local rc=$?
    if [ "$rc" -ne 0 ]; then
        systemctl --user start plasma-plasmashell.service 2>/dev/null || true
    fi
    exit "$rc"
}
trap start_shell_on_failure EXIT
sleep 1

# ── Migrate old plugin-id references in the layout ─────────────────
# Any panel config that still uses the legacy org.kde.windowsmodern.icontasks
# ID must be updated, otherwise plasmashell will write plugin=metadata.
if grep -q "org.kde.windowsmodern.icontasks" "$LAYOUT_FILE" 2>/dev/null; then
    info "Migrating legacy plugin references in layout..."
    sed -i "s/org\.kde\.windowsmodern\.icontasks/org.kde.plasma.icontasks/g" "$LAYOUT_FILE"
fi

# ── Fix layout if corrupted ───────────────────────────────────────
if grep -q "plugin=metadata" "$LAYOUT_FILE" 2>/dev/null; then
    info "Fixing corrupted plugin=metadata in layout..."
    sed -i "/\[Containments\]\[.*\]\[Applets\]/,/\[/s/^plugin=metadata$/plugin=${APP_ID}/" "$LAYOUT_FILE"
fi

# Also prune local copies (stale .so in ~/.local/lib* takes precedence over /usr)
rm -rf "$HOME/.local/share/plasma/plasmoids/${APP_ID}" 2>/dev/null || true
rm -f "$HOME/.local/lib64/qt6/plugins/plasma/applets/${APP_ID}.so" 2>/dev/null || true
rm -f "$HOME/.local/lib/qt6/plugins/plasma/applets/${APP_ID}.so" 2>/dev/null || true

# Remove the old .so under the legacy plugin ID
rm -f "$HOME/.local/lib64/qt6/plugins/plasma/applets/org.kde.windowsmodern.icontasks.so" 2>/dev/null || true
rm -f "$HOME/.local/lib/qt6/plugins/plasma/applets/org.kde.windowsmodern.icontasks.so" 2>/dev/null || true
rm -rf "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.icontasks" 2>/dev/null || true
# Legacy system copies (only prompt for privileges if one actually exists)
if [ -e "$PLUGIN_DST/org.kde.windowsmodern.icontasks.so" ] || [ -e /usr/share/plasma/plasmoids/org.kde.windowsmodern.icontasks ]; then
    pkexec rm -rf "$PLUGIN_DST/org.kde.windowsmodern.icontasks.so" /usr/share/plasma/plasmoids/org.kde.windowsmodern.icontasks 2>/dev/null || true
fi
info "Installed."

# ── Start plasmashell ────────────────────────────────────────────
# In batch mode (WM_BATCH=1) the parent 'all' driver restarts Plasma
# Shell once at the very end — skipping the start here avoids a storm
# of restarts when systray + icontasks install back-to-back.
if [ "${WM_BATCH:-0}" = "1" ]; then
    info "Installed (batch mode — Plasma Shell will restart at end of 'all')."
    exit 0
fi

info "Restarting plasmashell..."
systemctl --user start plasma-plasmashell.service
sleep 3

info "Done. If the taskbar is blank, check System Settings → Add Widgets."
