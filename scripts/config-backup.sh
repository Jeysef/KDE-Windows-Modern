#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  config-backup.sh — snapshots of the Plasma settings Windows Modern
#  changes, so they can be put back (issue #7). Sourced by install.sh
#  and uninstall.sh.
#
#  ~/.local/share/windows-modern/backups/<YYYY-MM-DDTHH-MM-SS>/
#      manifest.json       when, why, versions, which files existed
#      config/...          copies, relative to ~/.config
#      data/...            copies, relative to ~/.local/share
#
#  install.sh takes one before it changes anything; a snapshot equal to
#  the previous one is dropped. The first one ever is kept for good, plus
#  the newest five. Restoring takes a snapshot of the current state first,
#  so a restore can itself be undone.
# ───────────────────────────────────────────────────────────────────

WM_BACKUPS="${WM_BACKUPS:-$HOME/.local/share/windows-modern/backups}"
WM_BACKUP_KEEP=5

# Everything the installer or plasma-apply-lookandfeel may write.
WM_BACKUP_CONFIG=(
    kdeglobals kdedefaults kwinrc kscreenlockerrc plasmarc plasmashellrc
    plasma-org.kde.plasma.desktop-appletsrc kcminputrc ksplashrc
    kglobalshortcutsrc Kvantum/kvantum.kvconfig gtk-3.0/settings.ini
    gtk-4.0/settings.ini xsettingsd/xsettingsd.conf mimeapps.list
    spectaclerc dolphinrc
)
WM_BACKUP_DATA=(kxmlgui5/dolphin/dolphinui.rc)

_wm_config_home() { echo "${XDG_CONFIG_HOME:-$HOME/.config}"; }
_wm_data_home() { echo "${XDG_DATA_HOME:-$HOME/.local/share}"; }

# The live path for a manifest entry ("config/kwinrc"), only for entries on
# the lists above: a damaged manifest can never point a restore elsewhere.
_wm_target() {
    local f
    for f in "${WM_BACKUP_CONFIG[@]}"; do
        [ "$1" = "config/$f" ] && { echo "$(_wm_config_home)/$f"; return 0; }
    done
    for f in "${WM_BACKUP_DATA[@]}"; do
        [ "$1" = "data/$f" ] && { echo "$(_wm_data_home)/$f"; return 0; }
    done
    return 1
}

# Snapshot ids, oldest first.
wm_backup_ids() {
    [ -d "$WM_BACKUPS" ] || return 0
    find "$WM_BACKUPS" -mindepth 1 -maxdepth 1 -type d -name '20*' -printf '%f\n' | sort
}

# One checksum over a snapshot's copies, to spot an unchanged state.
_wm_backup_digest() {
    (cd "$1" && find config data -type f 2>/dev/null | sort | xargs -r -d '\n' sha256sum | sha256sum | cut -d' ' -f1)
}

_wm_json_string() {
    local s="${1//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '"%s"' "$s"
}

# Were Windows Modern settings already in place? (then this is not a
# "before Windows Modern" snapshot, even if it is the first one)
_wm_already_applied() {
    grep -qs "windowsmodern\|WindowsModern\|Windows-modern" \
        "$(_wm_config_home)/kdeglobals" "$(_wm_config_home)/kdedefaults/kdeglobals" \
        "$(_wm_config_home)/plasma-org.kde.plasma.desktop-appletsrc"
}

# snapshot_configs REASON — prints the snapshot id (or the unchanged one).
snapshot_configs() {
    local reason="${1:-}" id dir prev first=true already=false
    [ "${UID:-$(id -u)}" -eq 0 ] && return 0
    mkdir -p "$WM_BACKUPS" || return 1
    [ -n "$(wm_backup_ids)" ] && first=false
    _wm_already_applied && already=true
    id="$(date +%Y-%m-%dT%H-%M-%S)"
    while [ -e "$WM_BACKUPS/$id" ]; do sleep 1; id="$(date +%Y-%m-%dT%H-%M-%S)"; done
    dir="$WM_BACKUPS/$id"
    mkdir -p "$dir/config" "$dir/data"

    local present=() absent=() f
    for f in "${WM_BACKUP_CONFIG[@]}"; do
        if [ -e "$(_wm_config_home)/$f" ]; then
            (cd "$(_wm_config_home)" && cp -a --parents "$f" "$dir/config/") && present+=("config/$f")
        else
            absent+=("config/$f")
        fi
    done
    for f in "${WM_BACKUP_DATA[@]}"; do
        if [ -e "$(_wm_data_home)/$f" ]; then
            (cd "$(_wm_data_home)" && cp -a --parents "$f" "$dir/data/") && present+=("data/$f")
        else
            absent+=("data/$f")
        fi
    done

    prev="$(wm_backup_ids | grep -vx "$id" | tail -1)" || true   # none yet: grep fails
    if [ -n "$prev" ] && [ "$(_wm_backup_digest "$dir")" = "$(_wm_backup_digest "$WM_BACKUPS/$prev")" ]; then
        rm -rf "$dir"
        echo "$prev"
        return 0
    fi

    local version plasma list_present list_absent
    version="$(git -C "${SRC_DIR:-.}" describe --tags --always 2>/dev/null || echo unknown)"
    plasma="$(plasmashell --version 2>/dev/null | awk '{print $2}')"
    list_present="$(for f in "${present[@]}"; do _wm_json_string "$f"; echo; done | paste -sd, -)"
    list_absent="$(for f in "${absent[@]}"; do _wm_json_string "$f"; echo; done | paste -sd, -)"
    cat > "$dir/manifest.json" <<EOF
{
  "id": $(_wm_json_string "$id"),
  "created": $(_wm_json_string "$(date --iso-8601=seconds)"),
  "reason": $(_wm_json_string "$reason"),
  "windowsModern": $(_wm_json_string "$version"),
  "plasma": $(_wm_json_string "${plasma:-unknown}"),
  "first": $first,
  "windowsModernAlreadyApplied": $already,
  "files": [$list_present],
  "absent": [$list_absent]
}
EOF
    chmod -R a-w "$dir/config" "$dir/data" 2>/dev/null || true
    _wm_prune_backups
    echo "$id"
}

# Keep the first snapshot ever and the newest WM_BACKUP_KEEP.
_wm_prune_backups() {
    local ids=() i
    mapfile -t ids < <(wm_backup_ids)
    [ "${#ids[@]}" -gt $((WM_BACKUP_KEEP + 1)) ] || return 0
    for ((i = 1; i < ${#ids[@]} - WM_BACKUP_KEEP; i++)); do
        chmod -R u+w "$WM_BACKUPS/${ids[$i]}" 2>/dev/null || true
        rm -rf "${WM_BACKUPS:?}/${ids[$i]}"
    done
}

_wm_manifest_value() {   # FILE KEY → true/false/string (no nesting needed)
    sed -n "s/^  \"$2\": \"\{0,1\}\([^\",]*\)\"\{0,1\},\{0,1\}$/\1/p" "$1" | head -1
}

# The snapshot taken before Windows Modern ever changed anything, if any.
wm_backup_original() {
    local first
    first="$(wm_backup_ids | head -1)"
    [ -n "$first" ] || return 1
    [ "$(_wm_manifest_value "$WM_BACKUPS/$first/manifest.json" windowsModernAlreadyApplied)" = "false" ] || return 1
    echo "$first"
}

list_backups() {
    local id m original
    original="$(wm_backup_original || true)"
    if [ -z "$(wm_backup_ids)" ]; then
        echo "No backups yet ($WM_BACKUPS)."
        return 0
    fi
    echo "Backups in $WM_BACKUPS (oldest first):"
    for id in $(wm_backup_ids); do
        m="$WM_BACKUPS/$id/manifest.json"
        printf '  %s  %s%s\n' "$id" "$(_wm_manifest_value "$m" reason)" \
            "$([ "$id" = "$original" ] && echo '  [before Windows Modern]')"
    done
}

# restore_backup_snapshot [ID] — default: the snapshot from before Windows Modern.
restore_backup_snapshot() {
    local id="${1:-}" dir m f undo
    if [ -z "$id" ]; then
        id="$(wm_backup_original)" || { echo "No snapshot from before Windows Modern; pick one: ./uninstall.sh --list-backups" >&2; return 1; }
    fi
    dir="$WM_BACKUPS/$id"; m="$dir/manifest.json"
    [ -f "$m" ] || { echo "No such backup: $id" >&2; return 1; }

    undo="$(snapshot_configs "before restoring $id")"
    echo "Current settings saved as $undo (restore it to undo)."

    # Plasma rewrites its panel files when it quits: stop it first.
    local shell_unit=false
    if systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null; then
        shell_unit=true
        systemctl --user stop plasma-plasmashell.service
    fi

    local target
    while read -r f; do
        target="$(_wm_target "$f")" || continue
        if [ -e "$dir/$f" ]; then
            rm -rf "$target"
            mkdir -p "$(dirname "$target")"
            cp -a "$dir/$f" "$target"
            chmod -R u+w "$target"
        fi
    done < <(sed -n 's/^  "files": \[\(.*\)\],$/\1/p' "$m" | grep -o '"[^"]*"' | tr -d '"')
    # Files that did not exist then are removed (they are in the undo snapshot).
    while read -r f; do
        target="$(_wm_target "$f")" || continue
        rm -rf "$target"
    done < <(sed -n 's/^  "absent": \[\(.*\)\]$/\1/p' "$m" | grep -o '"[^"]*"' | tr -d '"')

    if [ "$shell_unit" = true ]; then
        systemctl --user start plasma-plasmashell.service
    fi
    dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure 2>/dev/null || true
    echo "Restored $id. Log out and back in to finish (shortcuts, fonts, GTK apps)."
}
