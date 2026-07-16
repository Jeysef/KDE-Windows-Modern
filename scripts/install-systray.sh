#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-systray.sh — System Tray (C++ Plasma::Containment)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

dir="$SRC_DIR/plasma/applets/org.kde.windowsmodern.systemtray"
[ -d "$dir" ] || { warn "System Tray source not found — skipping."; exit 0; }

info "Installing System Tray (C++)..."

if [ -x "$dir/dev.sh" ]; then
    if ! ( cd "$dir" && bash dev.sh ); then
        err "System Tray build failed — missing build dependencies or compiler."
        warn "The panel will use the stock Plasma system tray instead."
        warn "To install build deps and retry, see the README (System Tray section)."
        exit 0
    fi
else
    err "dev.sh not found in $dir"
    exit 0
fi
