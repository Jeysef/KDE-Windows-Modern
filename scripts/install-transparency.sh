#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-transparency.sh — Windows' "Transparency effects" switch
#
#    ./install.sh transparency off   solid windows, popups and taskbar
#    ./install.sh transparency on    translucent again (the default)
#    ./install.sh transparency       show the current state
#
#  Off turns off Kvantum's translucent windows (Dolphin and other apps)
#  and KWin's blur effect; without blur, Plasma draws its popups, the
#  Start menu and flyouts with the theme's solid variant. Like Windows'
#  Settings → Personalization → Colors → Transparency effects, it is for
#  looks or for slower machines. The choice is remembered, so reinstalling
#  the theme keeps it; "on" puts back the blur setting you had.
# ───────────────────────────────────────────────────────────────────
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

if [ "$UID" -eq 0 ]; then
    warn "Transparency is set per user — run this as yourself, not root. Skipping."
    exit 0
fi

state="$TRANSPARENCY_OFF_FILE"
mode="${1:-status}"

case "$mode" in
    off)
        if [ -f "$state" ]; then
            info "Transparency effects are already off."
            exit 0
        fi
        ensure_dir "$(dirname "$state")"
        # Remember the blur setting as it was ("" = never set: KWin's default, on).
        echo "blurEnabled=$(kreadconfig6 --file kwinrc --group Plugins --key blurEnabled)" > "$state"
        kvantum_transparency false
        kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false
        kwin_reconfigure
        info "Transparency effects off."
        step "Apps already open stay translucent until you restart them."
        ;;
    on)
        if [ ! -f "$state" ]; then
            info "Transparency effects are already on."
            exit 0
        fi
        previous="$(sed -n 's/^blurEnabled=//p' "$state")"
        if [ -n "$previous" ]; then
            kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled "$previous"
        else
            kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled --delete
        fi
        kvantum_transparency true
        rm -f "$state"
        kwin_reconfigure
        info "Transparency effects on."
        step "Apps already open stay solid until you restart them."
        ;;
    status)
        if [ -f "$state" ]; then
            info "Transparency effects are off.  (./install.sh transparency on)"
        else
            info "Transparency effects are on.  (./install.sh transparency off)"
        fi
        ;;
    *)
        err "Usage: ./install.sh transparency [on|off]"
        exit 1
        ;;
esac
