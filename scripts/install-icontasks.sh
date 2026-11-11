#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-icontasks.sh — Icon Tasks (C++ Plasma applet fork)
# ───────────────────────────────────────────────────────────────────
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

dir="$SRC_DIR/plasma/applets/org.kde.windowsmodern.icontasks"
[ -d "$dir" ] || { warn "Icon Tasks source not found — skipping."; exit 0; }

info "Installing Icon Tasks (C++)..."

# A release checkout uses the release's prebuilt plugin when it matches
# this system exactly (no compiler needed); otherwise dev.sh builds it.
prebuilt="$(mktemp -d)/org.kde.plasma.icontasks.so"
if fetch_prebuilt_plugin org.kde.plasma.icontasks "$prebuilt"; then
    export WM_PREBUILT_SO="$prebuilt"
fi

if [ -x "$dir/dev.sh" ]; then
    if ! ( cd "$dir" && bash dev.sh ); then
        err "Icon Tasks build failed — missing build dependencies or compiler."
        warn "The panel will use the stock Plasma task manager instead."
        warn "To install build deps and retry, see the README (System Tray section)."
        exit 0
    fi
else
    err "dev.sh not found in $dir"
    exit 0
fi
