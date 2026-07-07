#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-systray.sh — System Tray (C++ Plasma::Containment)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

dir="$SRC_DIR/plasma/applets/org.kde.windowsmodern.systemtray"
[ -d "$dir" ] || { warn "System Tray source not found — skipping."; exit 0; }

info "Installing System Tray (C++)..."

if [ -x "$dir/dev.sh" ]; then
    ( cd "$dir" && bash dev.sh )
else
    err "dev.sh not found in $dir"
    exit 1
fi
