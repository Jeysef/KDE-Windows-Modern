#!/bin/bash
# Headless test of scripts/config-backup.sh in a throwaway home folder.
# systemctl and dbus-send are stubbed: a restore must never reach the real
# session (it stops and starts plasmashell).
# shellcheck disable=SC2016,SC2034  # check strings (and the variables they use) are evaluated later
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
T="$(mktemp -d)"
trap 'chmod -R u+w "$T" 2>/dev/null; rm -rf "$T"' EXIT

export HOME="$T/home" XDG_CONFIG_HOME="$T/home/.config" XDG_DATA_HOME="$T/home/.local/share"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$T/bin"
for c in systemctl dbus-send plasmashell; do
    printf '#!/bin/sh\necho "%s $*" >> "%s/calls"\nexit 0\n' "$c" "$T" > "$T/bin/$c"
    chmod +x "$T/bin/$c"
done
export PATH="$T/bin:$PATH"
WM_BACKUPS="$HOME/.local/share/windows-modern/backups"
# shellcheck source=scripts/config-backup.sh
source "$REPO/scripts/config-backup.sh"

FAIL=0
check() { if eval "$2"; then echo "  PASS  $1"; else echo "  FAIL  $1"; FAIL=1; fi; }
count() { wm_backup_ids | wc -l; }

printf '[General]\nColorScheme=BreezeDark\n' > "$XDG_CONFIG_HOME/kdeglobals"
printf '[Desktop]\nfoo=1\n' > "$XDG_CONFIG_HOME/plasmashellrc"
mkdir -p "$XDG_CONFIG_HOME/kdedefaults"; printf 'x\n' > "$XDG_CONFIG_HOME/kdedefaults/kdeglobals"
printf 'keep me\n' > "$XDG_CONFIG_HOME/unrelatedrc"

first="$(snapshot_configs "test first")"
m="$WM_BACKUPS/$first/manifest.json"
check "a snapshot is taken" '[ -f "$m" ]'
check "manifest is valid JSON" 'python3 -m json.tool "$m" >/dev/null'
check "it is the original (before Windows Modern)" '[ "$(wm_backup_original)" = "$first" ]'
check "existing files are listed, missing ones are absent" \
    'grep -q "\"config/kdeglobals\"" "$m" && grep -q "\"config/kdedefaults\"" "$m" && grep -q "absent.*config/mimeapps.list" "$m"'

sleep 1
again="$(snapshot_configs "test unchanged")"
check "an unchanged state adds no snapshot" '[ "$again" = "$first" ] && [ "$(count)" -eq 1 ]'

# Windows Modern applied: colours change, mimeapps.list appears.
printf '[General]\nColorScheme=WindowsModernDark\n' > "$XDG_CONFIG_HOME/kdeglobals"
printf '[Default Applications]\nvideo/mp4=haruna.desktop\n' > "$XDG_CONFIG_HOME/mimeapps.list"
sleep 1
second="$(snapshot_configs "test second")"
check "a changed state adds one" '[ "$second" != "$first" ] && [ "$(count)" -eq 2 ]'
check "it knows Windows Modern was applied" \
    'grep -q "\"windowsModernAlreadyApplied\": true" "$WM_BACKUPS/$second/manifest.json"'

sleep 1
restore_backup_snapshot >/dev/null
check "restore without an id puts back the original" 'grep -q BreezeDark "$XDG_CONFIG_HOME/kdeglobals"'
check "a file that did not exist then is removed" '[ ! -e "$XDG_CONFIG_HOME/mimeapps.list" ]'
check "files outside the list are untouched" '[ "$(cat "$XDG_CONFIG_HOME/unrelatedrc")" = "keep me" ]'
check "restored files are writable" '[ -w "$XDG_CONFIG_HOME/kdeglobals" ]'
check "the state before the restore is kept (unchanged: the last snapshot)" \
    '[ "$(wm_backup_ids | tail -1)" = "$second" ] && [ "$(count)" -eq 2 ]'
check "restore asked (the stubbed) systemd about plasmashell" 'grep -q "systemctl --user is-active" "$T/calls"'

# Change something, restore the original again: now the undo snapshot is new.
printf '[General]\nColorScheme=Mine\n' > "$XDG_CONFIG_HOME/kdeglobals"
sleep 1
restore_backup_snapshot "$first" >/dev/null
check "a restore saves a changed current state first" '[ "$(count)" -eq 3 ]'
undo="$(wm_backup_ids | tail -1)"
sleep 1
restore_backup_snapshot "$undo" >/dev/null
check "restoring the undo snapshot brings the change back" 'grep -q "ColorScheme=Mine" "$XDG_CONFIG_HOME/kdeglobals"'

# A damaged manifest must not reach outside the list.
bad="$WM_BACKUPS/2099-01-01T00-00-00"
mkdir -p "$bad/config"
cat > "$bad/manifest.json" <<'EOF'
{
  "id": "2099-01-01T00-00-00",
  "files": ["config/", "config/../.bashrc"],
  "absent": ["config/", "config/unrelatedrc", "data/"]
}
EOF
printf 'mine\n' > "$HOME/.bashrc"
restore_backup_snapshot "2099-01-01T00-00-00" >/dev/null 2>&1 || true
check "a damaged manifest deletes nothing outside the list" \
    '[ -d "$XDG_CONFIG_HOME" ] && [ -f "$XDG_CONFIG_HOME/unrelatedrc" ] && [ -f "$HOME/.bashrc" ]'
rm -rf "$bad"

for i in 1 2 3 4 5 6 7 8; do
    printf '[General]\nColorScheme=Test%s\n' "$i" > "$XDG_CONFIG_HOME/kdeglobals"
    sleep 1
    snapshot_configs "test $i" >/dev/null
done
check "keeps the first snapshot and the newest five" \
    '[ "$(count)" -eq 6 ] && [ "$(wm_backup_ids | head -1)" = "$first" ]'

# Someone who already had Windows Modern: no "before Windows Modern" snapshot.
chmod -R u+w "$WM_BACKUPS"; rm -rf "$WM_BACKUPS"
printf '[General]\nColorScheme=WindowsModernDark\n' > "$XDG_CONFIG_HOME/kdeglobals"
snapshot_configs "test existing user" >/dev/null
check "an existing user's first snapshot is not offered as 'before'" '! wm_backup_original >/dev/null'

if [ "$FAIL" -eq 0 ]; then echo "ALL PASSED"; else echo "FAILED"; exit 1; fi
