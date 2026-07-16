#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────────
#  install-greeter-live.sh — Install PATCHED PLM as your boot greeter
#
#  Replaces the system plasma-login-greeter with our patched build and
#  installs the theme + wallpaper system-wide.
#
#  WARNING: If the patched binary crashes, you may not be able to log in.
#  Keep a TTY open (Ctrl+Alt+F3) before proceeding.
#
#  Revert (fast):   sudo cp /usr/libexec/plasma-login-greeter.orig \
#                       /usr/libexec/plasma-login-greeter && \
#                   sudo systemctl restart plasmalogin
#  Revert (full):   sudo bash scripts/uninstall-greeter-system.sh
# ───────────────────────────────────────────────────────────────────
set -e

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLM_BUILD="${SRC_DIR}/third_party/plasma-login-manager/build-user"
PLM_BINARY="/usr/libexec/plasma-login-greeter"
SYSTEM_LOOKFEEL="/usr/share/plasma/look-and-feel/org.kde.windowsmodern.dark"
USER_LOOKFEEL="${SRC_DIR}/plasma/look-and-feel/org.kde.windowsmodern.dark"
SYSTEM_WALLPAPER="/usr/share/wallpapers/Windows-modern"

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║   Patched PLM Boot Greeter — LIVE System Install                 ║"
echo "║                                                                  ║"
echo "║   ⚠  This REPLACES your system login manager.                   ║"
echo "║                                                                  ║"
echo "║   • /usr/libexec/plasma-login-greeter will be overwritten       ║"
echo "║   • If the patched binary crashes, you may be LOCKED OUT         ║"
echo "║   • Keep another terminal / TTY open (Ctrl+Alt+F3)             ║"
echo "║   • Revert command is shown at the end of this script           ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Build patched PLM (fresh build every time) ──
echo "Step 1 / 5: Building patched PLM..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "${SRC_DIR}/scripts/install-greeter.sh"
echo ""

# ── Step 2: Require root for system install ──
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Step 2 (system install) requires root."
    echo "       Run the complete script with sudo:"
    echo ""
    echo "       sudo bash scripts/install-greeter-live.sh"
    echo ""
    exit 1
fi

# ── Step 3: Typed confirmation ──
read -r -p "Type YES to proceed with system install: " CONFIRM
echo ""
if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted. No system files were changed."
    echo "To test without installing:"
    echo "  ${PLM_BUILD}/bin/plasma-login-greeter --test"
    exit 1
fi

# ── Step 4: Backup pristine binary (once) ──
if [ -f "$PLM_BINARY" ] && [ ! -f "${PLM_BINARY}.orig" ]; then
    echo "Step 2 / 5: Saving pristine backup → ${PLM_BINARY}.orig"
    cp "$PLM_BINARY" "${PLM_BINARY}.orig"
else
    echo "Step 2 / 5: Pristine backup already exists."
fi

# ── Step 5: Install patched binary ──
echo "Step 3 / 5: Installing patched binary..."
cp "${PLM_BUILD}/bin/plasma-login-greeter" "$PLM_BINARY"
chmod 755 "$PLM_BINARY"

# ── Step 6: Install theme system-wide ──
echo "           Installing theme to ${SYSTEM_LOOKFEEL}..."
rm -rf "${SYSTEM_LOOKFEEL}/contents/lockscreen"
mkdir -p "${SYSTEM_LOOKFEEL}/contents"
cp -r "${USER_LOOKFEEL}/contents/lockscreen" "${SYSTEM_LOOKFEEL}/contents/"

# ── Step 7: Ensure the greeter wallpaper is installed system-wide ──
echo "Step 4 / 5: Ensuring greeter wallpaper is installed system-wide..."
if [ ! -d "${SYSTEM_WALLPAPER}" ]; then
    cp -r "${SRC_DIR}/wallpaper/Windows-modern" "${SYSTEM_WALLPAPER}"
    echo "           Wallpaper installed to ${SYSTEM_WALLPAPER}"
else
    echo "           Wallpaper already present at ${SYSTEM_WALLPAPER}"
fi

# ── Step 8: Restart service ──
echo "Step 5 / 5: Restarting plasmalogin.service..."
if systemctl is-active --quiet plasmalogin.service; then
    systemctl restart plasmalogin.service
    echo "           Service restarted."
else
    echo "           Service not running. Next reboot will use patched greeter."
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     INSTALL COMPLETE                            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Your patched PLM is now live. Log out (or reboot) to see it."
echo ""
echo "Quick revert (no package manager needed):"
echo "  sudo cp ${PLM_BINARY}.orig ${PLM_BINARY}"
echo "  sudo systemctl restart plasmalogin"
echo ""
echo "Full revert (restores distro package):"
echo "  sudo bash scripts/uninstall-greeter-system.sh"
echo ""
