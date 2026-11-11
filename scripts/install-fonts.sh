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

info "Fonts set up."
