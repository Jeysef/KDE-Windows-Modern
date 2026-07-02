#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-systray.sh — System Tray (C++ Plasma::Containment)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

local dir="$SRC_DIR/plasma/applets/org.kde.windowsmodern.systemtray"
[ -d "$dir" ] || { warn "System Tray source not found — skipping."; exit 0; }

info "Installing System Tray (C++)..."

# Prune any stale KPackage copies (prevents the critical dark-rectangle bug)
rm -rf "$APPLETS_DIR/org.kde.windowsmodern.systemtray" 2>/dev/null || true
rm -rf "$HOME/.local/share/plasma/plasmoids/org.kde.windowsmodern.systemtray" 2>/dev/null || true
sudo rm -rf /usr/share/plasma/plasmoids/org.kde.windowsmodern.systemtray 2>/dev/null || true

if [ -x "$dir/dev.sh" ]; then
    ( cd "$dir" && bash dev.sh )
else
    err "dev.sh not found in $dir"
    exit 1
fi
