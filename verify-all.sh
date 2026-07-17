#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  verify-all.sh — check all Windows Modern components are healthy
# ───────────────────────────────────────────────────────────────────
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

GREEN="\033[32m"; RED="\033[31m"; YELLOW="\033[33m"; BOLD="\033[1m"; RESET="\033[0m"
pass() { echo -e "  ${GREEN}✓${RESET} $1"; }
fail() { echo -e "  ${RED}✗${RESET} $1"; }
warn() { echo -e "  ${YELLOW}~${RESET} $1"; }

echo ""
echo -e "${BOLD}Windows Modern — Project Health Check${RESET}"
echo "======================================"
echo ""

# Themes
echo " Themes:"
[ -d "$SCRIPT_DIR/aurorae/windows-modern-dark-aurorae" ] && pass "Aurorae dark" || fail "Aurorae dark missing"
[ -f "$SCRIPT_DIR/color-schemes/WindowsModernDark.colors" ] && pass "Color scheme dark" || fail "Color scheme dark missing"
[ -d "$SCRIPT_DIR/Kvantum/Windows-modern" ] && pass "Kvantum theme" || fail "Kvantum theme missing"
[ -d "$SCRIPT_DIR/plasma/desktoptheme/Windows-modern-dark" ] && pass "Plasma theme dark" || fail "Plasma theme dark missing"

# Look-and-feel
echo ""
echo " Global themes:"
[ -d "$SCRIPT_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark" ] && pass "Dark theme" || fail "Dark theme missing"
[ -d "$SCRIPT_DIR/plasma/look-and-feel/org.kde.windowsmodern.light" ] && pass "Light theme" || fail "Light theme missing"

# Layout
echo ""
echo " Layout:"
[ -d "$SCRIPT_DIR/plasma/layout-templates/org.kde.windowsmodern.panel" ] && pass "Panel layout" || fail "Panel layout missing"

# Applets
echo ""
echo " Applets:"
for applet in showdesktop startmenu digitalclock; do
    d="$SCRIPT_DIR/plasma/applets/org.kde.windowsmodern.$applet"
    [ -d "$d" ] && [ -f "$d/metadata.json" ] && pass "$applet" || fail "$applet missing"
done

# System tray
echo ""
echo " System Tray:"
if [ -x "$SCRIPT_DIR/plasma/applets/org.kde.windowsmodern.systemtray/verify.sh" ]; then
    bash "$SCRIPT_DIR/plasma/applets/org.kde.windowsmodern.systemtray/verify.sh"
else
    fail "System tray verify.sh not found"
fi
