#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────────
#  install-greeter-live.sh — Install PATCHED PLM as your boot greeter
#
#  Replaces the system plasma-login-greeter with our patched build and
#  installs the theme + wallpaper system-wide.
#
#  Run with sudo from your normal account:
#      sudo bash scripts/install-greeter-live.sh
#  The build runs as the invoking user ($SUDO_USER); only the final copy
#  into /usr runs as root.
#
#  WARNING: If the patched binary crashes, you may not be able to log in.
#  Keep a TTY open (Ctrl+Alt+F3) before proceeding.
#
#  Revert (fast):   sudo cp /usr/libexec/plasma-login-greeter.orig \
#                       /usr/libexec/plasma-login-greeter && \
#                   sudo reboot
#  Revert (full):   sudo bash scripts/uninstall-greeter-system.sh && sudo reboot
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLM_DIR="${SRC_DIR}/third_party/plasma-login-manager"
PLM_BUILD="${PLM_DIR}/build-user"
BUILT_BINARY="${PLM_BUILD}/bin/plasma-login-greeter"
PLM_BINARY="/usr/libexec/plasma-login-greeter"
SYSTEM_LOOKFEEL="/usr/share/plasma/look-and-feel/org.kde.windowsmodern.dark"
REPO_LOOKFEEL="${SRC_DIR}/plasma/look-and-feel/org.kde.windowsmodern.dark"
SYSTEM_WALLPAPER="/usr/share/wallpapers/Windows-modern"

# ── Require root for system install (checked first: no wasted build) ──
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: System install requires root."
    echo "       Run the complete script with sudo from your normal account:"
    echo ""
    echo "       sudo bash scripts/install-greeter-live.sh"
    echo ""
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║   Patched PLM Boot Greeter — LIVE System Install                 ║"
echo "║                                                                  ║"
echo "║   ⚠  This REPLACES your system login manager.                    ║"
echo "║                                                                  ║"
echo "║   • /usr/libexec/plasma-login-greeter will be overwritten        ║"
echo "║   • If the patched binary crashes, you may be LOCKED OUT         ║"
echo "║   • Keep another terminal / TTY open (Ctrl+Alt+F3)               ║"
echo "║   • Revert command is shown at the end of this script            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Build patched PLM as the invoking user ──
# Never build (or write into the user-owned source tree) as root: root-owned
# artifacts break later user runs, and root would execute build steps from a
# user-writable directory. Root only copies the finished artifact.
echo "Step 1 / 4: Building patched PLM..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
    sudo -u "$SUDO_USER" -H bash "${SRC_DIR}/scripts/install-greeter.sh"
elif [ -x "$BUILT_BINARY" ]; then
    echo "  Not invoked via sudo — using the existing build at ${BUILT_BINARY}."
    echo "  (Rebuild it first as your normal user with: ./install.sh greeter)"
else
    echo "ERROR: No patched build found and no invoking user to build as."
    echo "       Build first as your normal user:  ./install.sh greeter"
    echo "       then run:                         sudo bash scripts/install-greeter-live.sh"
    exit 1
fi
echo ""

if [ ! -x "$BUILT_BINARY" ]; then
    echo "ERROR: Build did not produce ${BUILT_BINARY}. No system files were changed."
    exit 1
fi

# ── Typed confirmation ──
read -r -p "Type YES to proceed with system install: " CONFIRM
echo ""
if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted. No system files were changed."
    echo "To test without installing:"
    echo "  ${BUILT_BINARY} --test"
    exit 1
fi

# ── Refuse to drop file capabilities ──
# If the distro ships the greeter with file capabilities, a plain cp would
# silently strip them and the greeter could fail at boot. Replicating them
# automatically is unsafe, so stop and let the user decide.
if command -v getcap &>/dev/null && [ -f "$PLM_BINARY" ] && [ -n "$(getcap "$PLM_BINARY" 2>/dev/null)" ]; then
    echo "ERROR: ${PLM_BINARY} carries file capabilities:"
    getcap "$PLM_BINARY"
    echo "Refusing to overwrite it — the patched copy would lose them."
    echo "Check your distro's plasma-login-manager packaging before continuing."
    exit 1
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

# ── Step 2: Backup pristine binary ──
# Refreshed whenever the installed greeter is the distro's own file, so the
# backup never lags behind a package update.
if [ ! -f "$PLM_BINARY" ]; then
    echo "Step 2 / 4: No system greeter at ${PLM_BINARY} — nothing to back up."
    echo "           (Revert will need your package manager: see uninstall-greeter-system.sh)"
elif [ ! -f "${PLM_BINARY}.orig" ] || greeter_is_pristine; then
    echo "Step 2 / 4: Saving pristine backup → ${PLM_BINARY}.orig"
    cp -p "$PLM_BINARY" "${PLM_BINARY}.orig"
else
    echo "Step 2 / 4: Pristine backup already exists at ${PLM_BINARY}.orig"
fi

# ── Step 3: Leave plasmalogin running ──
# Never stop plasmalogin.service here: it is the parent of the running
# desktop session (plasmalogin-helper --start startplasma-wayland), so
# stopping it logs the user out. It does not need to stop either: the
# greeter binary only runs while the login screen is shown, and the new
# binary goes in by rename (below), which is safe even if it were running.
echo "Step 3 / 4: plasmalogin.service stays running (your session runs under it)."

# ── Step 4: Install patched binary, theme, and wallpaper system-wide ──
echo "Step 4 / 4: Installing patched binary..."
# Copy next to it, then rename over it: atomic, and fine even if the old
# binary is executing. restorecon below gives the new file its label.
cp "$BUILT_BINARY" "${PLM_BINARY}.new"
chown root:root "${PLM_BINARY}.new"
chmod 755 "${PLM_BINARY}.new"
mv -f "${PLM_BINARY}.new" "$PLM_BINARY"
if command -v restorecon &>/dev/null; then restorecon "$PLM_BINARY" 2>/dev/null || true; fi

echo "           Installing theme to ${SYSTEM_LOOKFEEL}..."
rm -rf "${SYSTEM_LOOKFEEL}/contents/lockscreen"
mkdir -p "${SYSTEM_LOOKFEEL}/contents"
cp -r "${REPO_LOOKFEEL}/contents/lockscreen" "${SYSTEM_LOOKFEEL}/contents/"

echo "           Ensuring greeter wallpaper is installed system-wide..."
if [ ! -d "${SYSTEM_WALLPAPER}" ]; then
    cp -r "${SRC_DIR}/wallpaper/Windows-modern" "${SYSTEM_WALLPAPER}"
    echo "           Wallpaper installed to ${SYSTEM_WALLPAPER}"
else
    echo "           Wallpaper already present at ${SYSTEM_WALLPAPER}"
fi

# The greeter runs as the 'plasmalogin' user, who cannot read the icon pack
# in the user's home, so it fell back to Breeze. Install the pack system-wide
# (marked as ours, so uninstall removes only our copy) and set it as the
# greeter's icon theme.
SYSTEM_ICONS="/usr/share/icons/windows-modern"
GREETER_HOME="$(getent passwd plasmalogin | cut -d: -f6 || true)"
# The greeter user's kdeglobals as it was before we changed it (icons and
# colors below), kept once for uninstall.
GREETER_BACKUP="/var/lib/windows-modern/backup/greeter-kdeglobals"
if [ -n "${GREETER_HOME}" ] && [ ! -e "$GREETER_BACKUP" ] && [ ! -e "$GREETER_BACKUP.none" ]; then
    mkdir -p "$(dirname "$GREETER_BACKUP")"
    if [ -f "${GREETER_HOME}/.config/kdeglobals" ]; then
        cp -p "${GREETER_HOME}/.config/kdeglobals" "$GREETER_BACKUP"
    else
        : > "$GREETER_BACKUP.none"
    fi
fi
if [ -d "${SRC_DIR}/icons/windows-modern" ]; then
    if [ ! -d "${SYSTEM_ICONS}" ] || [ -f "${SYSTEM_ICONS}/.windows-modern-greeter" ]; then
        echo "           Installing the icon pack to ${SYSTEM_ICONS}..."
        rm -rf "${SYSTEM_ICONS}"
        cp -r "${SRC_DIR}/icons/windows-modern" "${SYSTEM_ICONS}"
        touch "${SYSTEM_ICONS}/.windows-modern-greeter"
        if command -v restorecon &>/dev/null; then restorecon -R "${SYSTEM_ICONS}" 2>/dev/null || true; fi
    else
        echo "           ${SYSTEM_ICONS} exists and is not ours: left as it is."
    fi
    if [ -n "${GREETER_HOME}" ] && [ -d "${GREETER_HOME}/.config" ]; then
        runuser -u plasmalogin -- kwriteconfig6 --file "${GREETER_HOME}/.config/kdeglobals" \
            --group Icons --key Theme windows-modern
        echo "           Greeter icon theme: windows-modern"
    fi
fi

# The greeter user also has Plasma's default light colors, so the wallpaper
# showed its light picture under a dark desktop. The lock and login screens
# are always dark: give the greeter the Windows Modern Dark colors. Its
# original kdeglobals is kept once for uninstall.
GREETER_KDEGLOBALS="${GREETER_HOME}/.config/kdeglobals"
if [ -n "${GREETER_HOME}" ] && [ -d "${GREETER_HOME}/.config" ]; then
    python3 -I "${SRC_DIR}/scripts/greeter-colors.py" \
        "${SRC_DIR}/color-schemes/WindowsModernDark.colors" "$GREETER_KDEGLOBALS"
    chown plasmalogin:plasmalogin "$GREETER_KDEGLOBALS"
    chmod 600 "$GREETER_KDEGLOBALS"
    if command -v restorecon &>/dev/null; then restorecon "$GREETER_KDEGLOBALS" 2>/dev/null || true; fi
    echo "           Greeter colors: Windows Modern Dark"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     INSTALL COMPLETE                             ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "The patched greeter binary is installed. It will be used on the next boot."
echo ""
echo "DO NOT run 'sudo systemctl start plasmalogin' while logged in — that will"
echo "spawn a greeter overlay on top of your current session."
echo ""
echo "Reboot now to see the new greeter:"
echo "  sudo reboot"
echo ""
if [ -f "${PLM_BINARY}.orig" ]; then
    echo "Quick revert (no package manager needed):"
    echo "  sudo cp ${PLM_BINARY}.orig ${PLM_BINARY}"
    echo "  sudo reboot"
    echo ""
fi
echo "Full revert (restores distro package):"
echo "  sudo bash scripts/uninstall-greeter-system.sh && sudo reboot"
echo ""
