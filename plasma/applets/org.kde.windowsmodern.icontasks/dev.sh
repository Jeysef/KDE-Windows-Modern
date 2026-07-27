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
# APP_ID is org.kde.plasma.icontasks — the *stock* KDE Icons-only Task Manager
# ID. We need that exact ID because libkicker hardcodes a list of task-manager
# plugin ids to decide whether to offer "Pin to Taskbar" in the Start Menu, and
# a vendor-namespaced id is not in it.
#
# So we install under the user prefix, never /usr. Qt loads a plugin from
# ~/.local/lib*/qt6/plugins in preference to the system copy (see BUILD.md), so
# the themed applet wins at runtime while the distro's own
# org.kde.plasma.icontasks.so stays untouched on disk. That keeps this install
# root-free and makes uninstall a plain file removal: delete our copy and the
# stock applet is simply visible again.
detect_paths() {
    # Match the system's Qt libdir (lib64 vs lib) so the user plugin dir is on
    # the same search path Qt already scans.
    if [ -d /usr/lib64/qt6/plugins ]; then
        USER_QT_LIBDIR="$HOME/.local/lib64"
    else
        USER_QT_LIBDIR="$HOME/.local/lib"
    fi
    PLUGIN_DST="$USER_QT_LIBDIR/qt6/plugins/plasma/applets"
}

# ── Build ─────────────────────────────────────────────────────────
info "Building..."
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release > /dev/null
cmake --build "$BUILD_DIR" --parallel "$(nproc)" 2>&1 | tail -3

# ── Stop plasmashell ──────────────────────────────────────────────
info "Stopping plasmashell..."
systemctl --user stop plasma-plasmashell.service 2>/dev/null || true
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

# ── Install .so only (no KPackage) ───────────────────────────────
info "Installing..."
PLUGIN_SRC="$BUILD_DIR/lib/plasma/applets/${APP_ID}.so"
detect_paths

[ -f "$PLUGIN_SRC" ] || { err "Built plugin missing: $PLUGIN_SRC"; exit 1; }

mkdir -p "$PLUGIN_DST"
cp "$PLUGIN_SRC" "$PLUGIN_DST/"

# No KPackage: the QML and config are embedded in the .so via
# ecm_target_qml_sources, and a KPackage dir at the same plugin id causes the
# dark-rectangle popup bug.
rm -rf "$HOME/.local/share/plasma/plasmoids/${APP_ID}" 2>/dev/null || true

# Remove our own leftovers under the legacy vendor plugin ID. Only ever paths
# this theme created — never the distro's org.kde.plasma.icontasks files.
rm -f "$HOME/.local/lib64/qt6/plugins/plasma/applets/org.kde.windowsmodern.icontasks.so" 2>/dev/null || true
rm -f "$HOME/.local/lib/qt6/plugins/plasma/applets/org.kde.windowsmodern.icontasks.so" 2>/dev/null || true
rm -rf "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.icontasks" 2>/dev/null || true

# An older revision of this script installed to /usr and overwrote the distro's
# stock applet. We cannot restore it (no backup was taken), so warn instead of
# silently leaving a third-party binary in a package-owned path. rpm -Vf exits
# non-zero when the file no longer matches its package.
if command -v rpm &>/dev/null; then
    for stock_so in /usr/lib64/qt6/plugins/plasma/applets/org.kde.plasma.icontasks.so \
                    /usr/lib/qt6/plugins/plasma/applets/org.kde.plasma.icontasks.so; do
        [ -e "$stock_so" ] || continue
        if ! rpm -Vf "$stock_so" &>/dev/null; then
            warn "$stock_so differs from its package."
            warn "An earlier version of this script overwrote the stock KDE applet."
            warn "Restore it with:  sudo dnf reinstall plasma-desktop"
        fi
    done
fi

info "Installed to $PLUGIN_DST (no root required)."

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
