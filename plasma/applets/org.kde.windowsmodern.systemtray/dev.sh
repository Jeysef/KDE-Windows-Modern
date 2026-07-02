#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  Windows Modern System Tray — dev cycle
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
APP_ID="org.kde.windowsmodern.systemtray"
LAYOUT_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
info()  { echo -e "${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "${YELLOW}==>${RESET} $*"; }
err()   { echo -e "${RED}==>${RESET} $*"; }

# ── Build ─────────────────────────────────────────────────────────
info "Building..."
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release > /dev/null
cmake --build "$BUILD_DIR" --parallel "$(nproc)" 2>&1 | tail -3

# ── Stop plasmashell ──────────────────────────────────────────────
info "Stopping plasmashell..."
systemctl --user stop plasma-plasmashell.service 2>/dev/null || true
sleep 1

# ── Fix layout if corrupted ───────────────────────────────────────
if grep -q "plugin=metadata" "$LAYOUT_FILE" 2>/dev/null; then
    info "Fixing corrupted plugin=metadata in layout..."
    sed -i "/\[Containments\]\[.*\]\[Applets\]/,/\[/s/^plugin=metadata$/plugin=${APP_ID}/" "$LAYOUT_FILE"
fi

# ── Install .so only (no KPackage) ───────────────────────────────
info "Installing..."
PLUGIN_SRC="$BUILD_DIR/lib/plasma/applets/${APP_ID}.so"
PLUGIN_DST="/usr/lib64/qt6/plugins/plasma/applets"
KPACKAGE_DIR="/usr/share/plasma/plasmoids/${APP_ID}"

pkexec bash -s <<INSTALLEOF
set -e
mkdir -p "$PLUGIN_DST"
cp "$PLUGIN_SRC" "$PLUGIN_DST/"
rm -rf "$KPACKAGE_DIR"
echo "Installed."
INSTALLEOF

# Also prune local copies
rm -rf "$HOME/.local/share/plasma/plasmoids/${APP_ID}" 2>/dev/null || true
info "Installed."

# ── Start plasmashell ────────────────────────────────────────────
info "Restarting plasmashell..."
systemctl --user start plasma-plasmashell.service
sleep 3

# ── Verify ───────────────────────────────────────────────────────
if [ -x "$SRC_DIR/verify.sh" ]; then
    info "Running health check..."
    bash "$SRC_DIR/verify.sh"
fi
