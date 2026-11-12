#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────────
#  uninstall-greeter-system.sh — Revert PLM boot greeter to distro default
#
#  Nothing to do if the greeter is already the distro's own file (a package
#  update replaced ours); a stale backup is then removed.
#  Fast path: restores the .orig backup, if it still runs with the
#  installed libraries. Fallback: reinstalls the distro package.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

PLM_BINARY="/usr/libexec/plasma-login-greeter"

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root."
    echo "Usage: sudo $0"
    exit 1
fi

# ── The greeter's icons (install-greeter-live.sh): our system-wide copy of
#    the icon pack, and the greeter user's icon theme setting ──
SYSTEM_ICONS="/usr/share/icons/windows-modern"
GREETER_HOME="$(getent passwd plasmalogin | cut -d: -f6 || true)"
# Greeter colors (install-greeter-live.sh): put its original kdeglobals back.
GREETER_BACKUP="/var/lib/windows-modern/backup/greeter-kdeglobals"
if [ -n "${GREETER_HOME}" ] && [ -f "$GREETER_BACKUP" ]; then
    cp -p "$GREETER_BACKUP" "${GREETER_HOME}/.config/kdeglobals"
    rm -f "$GREETER_BACKUP"
    echo "  Greeter colors restored"
elif [ -n "${GREETER_HOME}" ] && [ -f "$GREETER_BACKUP.none" ]; then
    rm -f "${GREETER_HOME}/.config/kdeglobals" "$GREETER_BACKUP.none"
    echo "  Greeter colors restored (it had none)"
fi

if [ -f "${SYSTEM_ICONS}/.windows-modern-greeter" ]; then
    rm -rf "${SYSTEM_ICONS}"
    echo "  Removed ${SYSTEM_ICONS}"
fi
if [ -n "${GREETER_HOME}" ] && [ -f "${GREETER_HOME}/.config/kdeglobals" ] \
   && [ "$(runuser -u plasmalogin -- kreadconfig6 --file "${GREETER_HOME}/.config/kdeglobals" --group Icons --key Theme)" = "windows-modern" ]; then
    runuser -u plasmalogin -- kwriteconfig6 --file "${GREETER_HOME}/.config/kdeglobals" --group Icons --key Theme --delete
    echo "  Greeter icon theme reset"
fi

# True when the installed greeter is exactly the distro package's file (a
# package update replaces our patched copy). Unknown package manager: false.
greeter_is_pristine() {
    [ -f "$PLM_BINARY" ] || return 1
    if command -v rpm &>/dev/null && rpm -qf "$PLM_BINARY" &>/dev/null; then
        if grep -q " ${PLM_BINARY}\$" <<< "$(rpm -V "$(rpm -qf "$PLM_BINARY")" 2>/dev/null)"; then
            return 1
        fi
        return 0
    fi
    if command -v dpkg &>/dev/null && dpkg -S "$PLM_BINARY" &>/dev/null; then
        if grep -q " ${PLM_BINARY}\$" <<< "$(dpkg -V "$(dpkg -S "$PLM_BINARY" | cut -d: -f1)" 2>/dev/null)"; then
            return 1
        fi
        return 0
    fi
    return 1
}

# True when every library a binary needs is installed (an old backup can
# point at a libPlasmaQuick that a Plasma update removed).
binary_links() {
    [ -f "$1" ] && ! grep -q "not found" <<< "$(ldd "$1" 2>/dev/null)"
}

echo "Reverting PLM boot greeter to distro default..."

# ── Already the distro's greeter: nothing to revert ──
if greeter_is_pristine; then
    echo "  ${PLM_BINARY} is already the distro package's own file"
    echo "  (a package update replaced the patched greeter)."
    if [ -f "${PLM_BINARY}.orig" ]; then
        rm -f "${PLM_BINARY}.orig"
        echo "  Removed the old backup ${PLM_BINARY}.orig."
    fi
    echo "  Done — nothing else to revert."
    exit 0
fi

# ── Fast revert from pristine backup (only if it still links) ──
if [ -f "${PLM_BINARY}.orig" ] && ! binary_links "${PLM_BINARY}.orig"; then
    echo "  The backup ${PLM_BINARY}.orig needs libraries that are no longer"
    echo "  installed (Plasma was updated since). Not restoring it; reinstalling"
    echo "  the package instead."
    rm -f "${PLM_BINARY}.orig"
fi
if [ -f "${PLM_BINARY}.orig" ]; then
    echo "  Fast revert from ${PLM_BINARY}.orig"
    echo "  (backup taken $(stat -c %y "${PLM_BINARY}.orig" | cut -d. -f1))"
    echo "  Note: if your distro updated plasma-login-manager after that date, the"
    echo "  backup is older than the packaged binary — prefer the package reinstall"
    echo "  shown below once you have rebooted."
    cp "${PLM_BINARY}.orig" "${PLM_BINARY}.new" && mv -f "${PLM_BINARY}.new" "$PLM_BINARY"
    if command -v restorecon &>/dev/null; then restorecon "$PLM_BINARY" 2>/dev/null || true; fi
    # Neither stop nor restart plasmalogin: it is the parent of the running
    # desktop session (stopping it logs the user out), and restarting it
    # spawns a greeter overlay. The restored binary is used from next boot.
    echo "  Done."
    echo ""
    echo "Reboot to finish reverting to the original greeter:"
    echo "  sudo reboot"
    echo ""
    echo "To fully clean up (remove .orig and reinstall package):"
    echo "  rm ${PLM_BINARY}.orig"
    echo "  dnf reinstall plasma-login-manager   # Fedora"
    echo "  pacman -S plasma-login-manager       # Arch"
    exit 0
fi

# ── Full revert via package manager ──
echo "  No .orig backup found. Reinstalling plasma-login-manager..."
if command -v dnf &>/dev/null; then
    dnf reinstall -y plasma-login-manager
elif command -v pacman &>/dev/null; then
    pacman -S --noconfirm plasma-login-manager
elif command -v apt &>/dev/null; then
    apt-get install --reinstall -y plasma-login-manager
else
    echo "  ERROR: No supported package manager found."
    echo "  Reinstall plasma-login-manager with your distro's package manager."
    exit 1
fi
# Neither stop nor restart plasmalogin (see above): the package's binary
# is used from next boot.

echo ""
echo "PLM boot greeter reverted to distro default."
echo "Reboot to finish reverting:"
echo "  sudo reboot"
