#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-icontasks.sh — Icon Tasks (C++ Plasma applet fork)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

dir="$SRC_DIR/plasma/applets/org.kde.windowsmodern.icontasks"
[ -d "$dir" ] || { warn "Icon Tasks source not found — skipping."; exit 0; }

info "Installing Icon Tasks (C++)..."

if [ -x "$dir/dev.sh" ]; then
    ( cd "$dir" && bash dev.sh )
else
    err "dev.sh not found in $dir"
    exit 1
fi
