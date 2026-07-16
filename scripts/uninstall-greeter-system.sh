#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────────
#  uninstall-greeter-system.sh — Revert PLM boot greeter to distro default
#
#  Fast path: restores from pristine .orig backup (no package manager).
#  Fallback: reinstalls the distro package.
# ───────────────────────────────────────────────────────────────────
set -e

PLM_BINARY="/usr/libexec/plasma-login-greeter"

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root."
    echo "Usage: sudo $0"
    exit 1
fi

echo "Reverting PLM boot greeter to distro default..."

# ── Fast revert from pristine backup ──
if [ -f "${PLM_BINARY}.orig" ]; then
    echo "  Fast revert from ${PLM_BINARY}.orig"
    cp "${PLM_BINARY}.orig" "$PLM_BINARY"
    systemctl restart plasmalogin.service || true
    echo "  Done."
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
systemctl restart plasmalogin.service || true

echo ""
echo "PLM boot greeter reverted to distro default."
