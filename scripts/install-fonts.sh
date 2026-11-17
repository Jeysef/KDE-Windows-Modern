#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-fonts.sh — Windows 11's fonts, or the closest open ones
#
#    UI font        Segoe UI if you have it (it is not ours to ship).
#                   Otherwise Microsoft's open Selawik (OFL, Segoe UI's
#                   metrics) is downloaded, and fontconfig is told to use
#                   it wherever "Segoe UI" is asked for (the lock screen
#                   and clock name it). Your UI font changes only if it
#                   is still a distro default.
#    Monospace      Cascadia Mono (OFL, from your distro), unless you
#                   picked your own fixed-width font.
#    Smoothing      Greyscale text, as Windows 11's UI (no sub-pixel colour
#                   fringes), unless you chose a sub-pixel layout.
#
#  Previous settings are backed up; ./uninstall.sh fonts restores them.
# ───────────────────────────────────────────────────────────────────
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

if [ "$UID" -eq 0 ]; then
    warn "Fonts are set up per user — run this as yourself, not root. Skipping."
    exit 0
fi

BACKUP_DIR="$HOME/.local/share/windows-modern/backup"
FONT_DIR="$HOME/.local/share/fonts/selawik"
ALIAS="$HOME/.config/fontconfig/conf.d/60-windows-modern-segoe.conf"
SELAWIK_URL="https://github.com/microsoft/Selawik/releases/download/1.01/Selawik_Release.zip"
SELAWIK_SHA256="3f62c51e05e3b5a1e6241cf92a371f0be2ea1183aa87b30718bbd40832a8d423"
ensure_dir "$BACKUP_DIR"

has_font() { [ -n "$(fc-list "$1" family)" ]; }

# Set a kdeglobals font key, once backing up the previous value, but only
# when the current family is one of the given distro defaults.
set_font_if_default() {
    local key="$1" value="$2"; shift 2
    local current family d
    current="$(kreadconfig6 --group General --key "$key")"
    family="${current%%,*}"
    [ "$family" = "${value%%,*}" ] && return 0
    for d in "" "$@"; do
        if [ "$family" = "$d" ]; then
            [ -f "$BACKUP_DIR/kdeglobals.$key" ] || echo "$current" > "$BACKUP_DIR/kdeglobals.$key"
            kwriteconfig6 --notify --group General --key "$key" "$value"
            step "Font ($key): ${value%%,*}"
            return 0
        fi
    done
    step "Font ($key): keeping your $family"
}

info "Fonts..."

# ── UI font: Segoe UI, or Selawik standing in for it ──
if has_font "Segoe UI"; then
    step "Segoe UI is installed"
else
    if ! has_font "Selawik"; then
        step "Segoe UI is not installed: fetching Selawik (Microsoft, OFL)"
        tmp="$(mktemp -d)"
        if curl -sfL -o "$tmp/selawik.zip" "$SELAWIK_URL" \
           && echo "$SELAWIK_SHA256  $tmp/selawik.zip" | sha256sum -c --status; then
            ensure_dir "$FONT_DIR"
            python3 -I -c '
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    for name in z.namelist():
        if name.endswith(".ttf") and "/" not in name:
            z.extract(name, sys.argv[2])
' "$tmp/selawik.zip" "$FONT_DIR"
            fc-cache "$FONT_DIR" &>/dev/null || true
        else
            warn "Could not download Selawik (or its checksum did not match); keeping your fonts."
        fi
        rm -rf "$tmp"
    fi
    if has_font "Selawik"; then
        ensure_dir "$(dirname "$ALIAS")"
        cat > "$ALIAS" <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<!-- Windows Modern: Selawik (Segoe UI's metrics, OFL) wherever "Segoe UI"
     is asked for, as long as Segoe UI itself is not installed. -->
<fontconfig>
  <alias binding="same">
    <family>Segoe UI</family>
    <accept><family>Selawik</family></accept>
  </alias>
</fontconfig>
EOF
        fc-cache &>/dev/null || true
        set_font_if_default font "Segoe UI,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1" "Noto Sans" "Cantarell" "DejaVu Sans"
    fi
fi

# ── Monospace: Cascadia Mono ──
if command -v dnf &>/dev/null; then cascadia="cascadia-mono-fonts"
elif command -v apt-get &>/dev/null; then cascadia="fonts-cascadia-code"
elif command -v pacman &>/dev/null; then cascadia="ttf-cascadia-code"
else cascadia=""; fi
[ -n "$cascadia" ] && { install_packages "$cascadia" || warn "Cascadia Mono not installed."; }
fc-cache &>/dev/null || true # a font installed a moment ago may not be listed yet
if has_font "Cascadia Mono"; then
    set_font_if_default fixed "Cascadia Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1" \
        "Noto Sans Mono" "Hack" "DejaVu Sans Mono" "Monospace" "Liberation Mono"
fi

# ── Text smoothing: greyscale, as Windows 11's own UI draws text ──
# Two things give KDE text coloured (sub-pixel) fringes, most visible on dim
# text such as a field's "Search..." placeholder:
#  - Fedora's KDE edition sets rgba=rgb for everything
#    (/etc/fonts/conf.d/10-sub-pixel-rgb-for-kde.conf), and KDE's
#    "Sub-pixel rendering: None" writes nothing to override it;
#  - Qt Quick's distance-field text (Plasma, KWin) does its own RGB
#    smoothing and ignores fontconfig (QSG_DISTANCEFIELD_ANTIALIASING).
# Skipped when you chose a sub-pixel layout in System Settings; KDE's own
# fonts.conf is read after this file, so that choice wins anyway.
SMOOTHING_FC="$HOME/.config/fontconfig/conf.d/20-windows-modern-greyscale.conf"
SMOOTHING_ENV="$HOME/.config/plasma-workspace/env/windows-modern-greyscale-text.sh"
subpixel="$(kreadconfig6 --group General --key XftSubPixel 2>/dev/null || true)"
if [ -z "$subpixel" ] || [ "$subpixel" = "none" ]; then
    ensure_dir "$(dirname "$SMOOTHING_FC")"
    cat > "$SMOOTHING_FC" <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<!-- Windows Modern: greyscale font smoothing, like Windows 11's own UI.
     ./uninstall.sh fonts removes this file. -->
<fontconfig>
  <match target="font">
    <edit name="rgba" mode="assign"><const>none</const></edit>
    <edit name="lcdfilter" mode="assign"><const>lcdnone</const></edit>
  </match>
</fontconfig>
EOF
    ensure_dir "$(dirname "$SMOOTHING_ENV")"
    cat > "$SMOOTHING_ENV" <<'EOF'
# Windows Modern: greyscale text smoothing in Qt Quick (Plasma, KWin), like
# Windows 11's own UI. ./uninstall.sh fonts removes this file.
export QSG_DISTANCEFIELD_ANTIALIASING=gray
EOF
    fc-cache &>/dev/null || true
    step "Text smoothing: greyscale (applies to Plasma after you log out and in)"
else
    step "Text smoothing: keeping your sub-pixel setting ($subpixel)"
fi

info "Fonts set up."
