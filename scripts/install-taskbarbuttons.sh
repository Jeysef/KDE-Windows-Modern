#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-taskbarbuttons.sh — optional Search and Task View taskbar
#  buttons (pure QML)
#
#  Installs both applets so they show up in "Add Widgets". It never puts
#  them on a panel: the default Windows Modern panel has neither button.
# ───────────────────────────────────────────────────────────────────
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

TASKBAR_BUTTONS=(org.kde.windowsmodern.search org.kde.windowsmodern.taskview)

info "Installing the Search and Task View taskbar buttons..."
ensure_dir "$APPLETS_DIR"
for id in "${TASKBAR_BUTTONS[@]}"; do
    src="$SRC_DIR/plasma/applets/$id"
    [ -d "$src" ] || { warn "$id not found — skipping."; continue; }
    rm -rf "${APPLETS_DIR:?}/$id"
    cp -r "$src" "$APPLETS_DIR/"
    step "$id"
done
info "Taskbar buttons installed. Add them from the panel's \"Add Widgets\" (search for \"Windows Modern\")."

if is_batch; then
    exit 0
fi

if command -v kbuildsycoca6 &>/dev/null; then kbuildsycoca6 2>/dev/null || true; fi

# Plasma lists new widgets without a restart. Only a button already on a
# panel runs the old QML until Plasma Shell restarts.
appletsrc="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
in_use=0
for id in "${TASKBAR_BUTTONS[@]}"; do
    if [ -f "$appletsrc" ] && grep -qx "plugin=$id" "$appletsrc"; then in_use=1; fi
done
if [ "$in_use" -eq 1 ] && pgrep -x plasmashell >/dev/null 2>&1; then
    restart_plasmashell
fi
