#!/bin/bash
# ───────────────────────────────────────────────────────────────────
# Windows Modern System Tray — quick dev cycle
#   build → fix-config → install → restart → logs
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

# ── Step 1: Build ──────────────────────────────────────────────
info "Building..."
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release > /dev/null
cmake --build "$BUILD_DIR" --parallel "$(nproc)" 2>&1 | tail -5

# ── Step 2: Stop plasmashell, fix layout config ────────────────
info "Stopping plasmashell to fix layout..."
systemctl --user stop plasma-plasmashell.service 2>/dev/null || true
sleep 1

if grep -q "plugin=metadata" "$LAYOUT_FILE" 2>/dev/null; then
    info "Fixing corrupted plugin=metadata in layout config..."
    sed -i "/\[Containments\]\[.*\]\[Applets\]/,/\[/{s/^plugin=metadata$/plugin=${APP_ID}/}" "$LAYOUT_FILE"
fi

# ── Step 3: Install .so only (no KPackage — prevents duplicate applet) ──
info "Installing..."
PLUGIN_SRC="$BUILD_DIR/lib/plasma/applets/${APP_ID}.so"
PLUGIN_DST="/usr/lib64/qt6/plugins/plasma/applets"
KPACKAGE_DIR="/usr/share/plasma/plasmoids/${APP_ID}"

pkexec bash -s <<INSTALLEOF
set -e
mkdir -p "$PLUGIN_DST"
cp "$PLUGIN_SRC" "$PLUGIN_DST/"
# REMOVE the KPackage if it exists — duplicate registration causes dark rectangle
rm -rf "$KPACKAGE_DIR"
echo "Installed."
INSTALLEOF

info "Files installed."

# ── Step 4: Start plasmashell ───────────────────────────────────
info "Restarting plasmashell..."
systemctl --user start plasma-plasmashell.service
sleep 3

# ── Step 5: Verify layout ───────────────────────────────────────
if grep -q "plugin=${APP_ID}" "$LAYOUT_FILE" 2>/dev/null; then
    info "Layout config OK: plugin=${APP_ID}"
else
    warn "Layout config may be corrupted. Check: $LAYOUT_FILE"
fi

# ── Step 6: Show relevant logs ──────────────────────────────────
info "Recent logs:"
journalctl --user -u plasma-plasmashell.service --since "15 seconds ago" --no-pager 2>&1 \
    | grep -i "${APP_ID}\|systemtray.*error\|metadata.*error\|Error loading\|ReferenceError.*tray\|Cannot read.*tray\|Cannot read.*Expanded\|No visual parent" \
    | head -10 || true
