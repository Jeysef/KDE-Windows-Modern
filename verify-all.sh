#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  verify-all.sh — check Windows Modern is healthy
#
#  Usage:  ./verify-all.sh              Repository checks (release gate)
#          ./verify-all.sh --installed  ...plus checks of the installed
#                                       C++ applets on this machine
#
#  Exits 1 if any check fails. scripts/release.sh refuses to publish
#  unless the repository checks pass.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

CHECK_INSTALLED=0
case "${1:-}" in
    --installed) CHECK_INSTALLED=1 ;;
    -h|--help)   sed -n '3,10p' "$0"; exit 0 ;;
    "")          ;;
    *)           echo "Unknown option: $1 (try --help)" >&2; exit 2 ;;
esac

GREEN="\033[32m"; RED="\033[31m"; YELLOW="\033[33m"; BOLD="\033[1m"; RESET="\033[0m"
FAILED=0
pass() { echo -e "  ${GREEN}✓${RESET} $1"; }
fail() { echo -e "  ${RED}✗${RESET} $1"; FAILED=1; }
warn() { echo -e "  ${YELLOW}~${RESET} $1"; }
check_dir()  { if [ -d "$1" ]; then pass "$2"; else fail "$2 missing ($1)"; fi; }
check_file() { if [ -f "$1" ]; then pass "$2"; else fail "$2 missing ($1)"; fi; }

echo ""
echo -e "${BOLD}Windows Modern — Project Health Check${RESET}"
echo "======================================"

# ── Themes (every component ships dark + light) ─────────────────────
echo ""
echo " Themes:"
for v in dark light; do
    V="$(tr '[:lower:]' '[:upper:]' <<< "${v:0:1}")${v:1}"
    check_dir  "aurorae/windows-modern-${v}-aurorae"      "Aurorae ${v}"
    check_file "color-schemes/WindowsModern${V}.colors"    "Color scheme ${v}"
    check_dir  "plasma/desktoptheme/Windows-modern-${v}"   "Plasma theme ${v}"
    check_dir  "plasma/look-and-feel/org.kde.windowsmodern.${v}" "Global theme ${v}"
done
check_dir  "Kvantum/Windows-modern"                         "Kvantum theme"
check_dir  "wallpaper/Windows-modern"                       "Wallpaper"
check_file "icons/windows-modern/index.theme"               "Icon pack"
check_file "plasma/windowswitcher/org.kde.windowsmodern.alttab/contents/ui/main.qml" "Alt+Tab switcher"

# ── Layout ──────────────────────────────────────────────────────────
echo ""
echo " Layout:"
LAYOUT_TPL="plasma/layout-templates/org.kde.windowsmodern.panel/contents/layout.js"
LAYOUT_DARK="plasma/look-and-feel/org.kde.windowsmodern.dark/contents/layouts/org.kde.plasma.desktop-layout.js"
LAYOUT_LIGHT="plasma/look-and-feel/org.kde.windowsmodern.light/contents/layouts/org.kde.plasma.desktop-layout.js"
check_file "$LAYOUT_TPL" "Panel layout template"
# Applying a global theme replaces all panels (one per screen); "Add Panel"
# adds one. Only the widget section is shared — it must not drift.
widget_section() { sed -n '/--- Widgets/,$p' "$1" | sed 's/^ *//' | grep -v '^}$'; }
if cmp -s "$LAYOUT_DARK" "$LAYOUT_LIGHT"; then
    pass "Dark and light global-theme layouts are identical"
else
    fail "Dark and light global-theme layouts differ"
fi
if diff -q <(widget_section "$LAYOUT_TPL") <(widget_section "$LAYOUT_DARK") >/dev/null; then
    pass "Panel template and global-theme layout add the same widgets"
else
    fail "Widget section of $LAYOUT_TPL has drifted from $LAYOUT_DARK"
fi

# ── Applets ─────────────────────────────────────────────────────────
echo ""
echo " Applets:"
for applet in showdesktop startmenu digitalclock systemtray icontasks; do
    d="plasma/applets/org.kde.windowsmodern.$applet"
    check_file "$d/metadata.json" "$applet"
done
for applet in systemtray icontasks; do
    d="plasma/applets/org.kde.windowsmodern.$applet"
    if [ -f "$d/CMakeLists.txt" ] && [ -x "$d/dev.sh" ] && [ -x "$d/verify.sh" ]; then
        pass "$applet C++ sources, dev.sh, verify.sh"
    else
        fail "$applet is missing CMakeLists.txt, an executable dev.sh, or verify.sh"
    fi
done

# ── Metadata ────────────────────────────────────────────────────────
echo ""
echo " Metadata:"
META_ERRORS="$(python3 - <<'PY'
import json, pathlib, sys
skip = {"build", "CMakeFiles", "third_party", "dist", "icons", "icons-old", "icons_v2", "untracked", ".git"}
errors = []
count = 0
for p in sorted(pathlib.Path(".").rglob("metadata.json")):
    if any(part in skip or part.startswith("build") for part in p.parts):
        continue
    count += 1
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
    except Exception as e:
        errors.append(f"{p}: invalid JSON ({e})")
        continue
    if p.parts[:2] == ("plasma", "applets"):
        plugin = data.get("KPlugin", {})
        compiled = (p.parent / "CMakeLists.txt").exists()
        if compiled and plugin.get("Id"):
            # KF6: a compiled plugin's id comes from its file name; an explicit
            # Id in the embedded metadata only triggers a runtime warning.
            errors.append(f"{p}: compiled plugin must not set KPlugin.Id")
        required = ("Name", "Version", "License") if compiled else ("Id", "Name", "Version", "License")
        for key in required:
            if not plugin.get(key):
                errors.append(f"{p}: KPlugin.{key} is missing")
print(f"ok {count}")
for e in errors:
    print(e)
PY
)"
META_COUNT="$(head -1 <<< "$META_ERRORS" | cut -d' ' -f2)"
META_PROBLEMS="$(tail -n +2 <<< "$META_ERRORS")"
if [ -z "$META_PROBLEMS" ]; then
    pass "$META_COUNT metadata.json files parse; applet metadata complete (Id only for QML applets)"
else
    while IFS= read -r line; do fail "$line"; done <<< "$META_PROBLEMS"
fi

# ── Shell scripts ───────────────────────────────────────────────────
echo ""
echo " Shell scripts:"
mapfile -t SCRIPTS < <(git ls-files '*.sh')
SYNTAX_OK=1
for s in "${SCRIPTS[@]}"; do
    if ! bash -n "$s" 2>/dev/null; then
        fail "syntax error: $s"
        SYNTAX_OK=0
    fi
done
[ "$SYNTAX_OK" -eq 1 ] && pass "${#SCRIPTS[@]} scripts pass bash -n"
if command -v shellcheck &>/dev/null; then
    if shellcheck -x "${SCRIPTS[@]}" >/dev/null 2>&1; then
        pass "shellcheck clean"
    else
        fail "shellcheck reported problems — run: shellcheck -x \$(git ls-files '*.sh')"
        shellcheck -x "${SCRIPTS[@]}" 2>&1 | head -40 || true
    fi
else
    warn "shellcheck not installed — skipped (CI runs it)"
fi

# ── QML tests ───────────────────────────────────────────────────────
echo ""
echo " QML tests:"
if command -v qmltestrunner6 &>/dev/null || command -v qmltestrunner &>/dev/null \
   || [ -x /usr/lib64/qt6/bin/qmltestrunner ] || [ -x /usr/lib/qt6/bin/qmltestrunner ]; then
    if QT_QPA_PLATFORM=offscreen tests/run-qml-tests.sh >/dev/null 2>&1; then
        pass "QML test suites (tests/*/tst_*.qml)"
    else
        fail "QML tests failed — run: tests/run-qml-tests.sh"
    fi
else
    warn "qmltestrunner not installed — skipped (CI runs it)"
fi

# ── Shared code copies ──────────────────────────────────────────────
# The lock screen is its own package, so it carries a copy of the clock's
# date formatting; the two must not drift apart.
SHARED_DRIFT=""
LOCK=plasma/shells/org.kde.windowsmodern.lockscreen/contents/lockscreen
LOGIN=plasma/look-and-feel/org.kde.windowsmodern.dark/contents/lockscreen
for pair in \
    "plasma/applets/org.kde.windowsmodern.digitalclock/contents/ui/code/dateformat.js $LOCK/dateformat.js" \
    "$LOCK/dateformat.js $LOGIN/dateformat.js" \
    "$LOCK/StatusIconButton.qml $LOGIN/StatusIconButton.qml" \
    "$LOCK/NetworkStatusIcon.qml $LOGIN/NetworkStatusIcon.qml" \
    "$LOCK/BatteryStatusIcon.qml $LOGIN/BatteryStatusIcon.qml"; do
    # shellcheck disable=SC2086  # two paths on purpose
    cmp -s $pair || SHARED_DRIFT="$SHARED_DRIFT ${pair##* }"
done
if [ -z "$SHARED_DRIFT" ]; then
    pass "shared copies (date format, lock/login status icons) are identical"
else
    fail "copies drifted from their source:$SHARED_DRIFT"
    FAILED=1
fi

# ── Theme renders ───────────────────────────────────────────────────
echo ""
echo " Theme renders:"
set +e; SWITCH_OUT=$(tests/theme/check-switch.py 2>&1); SWITCH_RC=$?; set -e
case "$SWITCH_RC" in
    0)  pass "switch.svg: no outline around the on-pill (dark + light)" ;;
    77) warn "switch render skipped: ${SWITCH_OUT##*$'\n'}" ;;
    *)  fail "switch.svg render check failed — run: tests/theme/check-switch.py"
        FAILED=1 ;;
esac

set +e; KBD_OUT=$(python3 scripts/keyboard-labels.py --self-test 2>&1); KBD_RC=$?; set -e
case "$KBD_RC" in
    0)  pass "keyboard labels: XKB languages map to Windows-style codes" ;;
    77) warn "keyboard label check skipped: $KBD_OUT" ;;
    *)  fail "keyboard-labels.py --self-test failed"; echo "$KBD_OUT"
        FAILED=1 ;;
esac

# ── Installed C++ applets (opt-in) ──────────────────────────────────
if [ "$CHECK_INSTALLED" -eq 1 ]; then
    # The lock screen overlay's copy of the logout screen (see
    # install-sessionlock.sh) must match the system's after Plasma updates.
    overlay="$HOME/.local/share/plasma/shells/org.kde.plasma.desktop/contents/logout"
    if [ -e "$overlay" ]; then
        if [ -L "$overlay" ]; then
            fail "lock screen overlay symlinks logout/ (Log out does nothing) — run: ./install.sh sessionlock"
        elif diff -rq "$overlay" /usr/share/plasma/shells/org.kde.plasma.desktop/contents/logout >/dev/null 2>&1; then
            pass "lock screen overlay: logout screen matches Plasma's"
        else
            fail "lock screen overlay: logout screen is out of date — run: ./install.sh sessionlock"
        fi
    fi
    # Our Alt+Tab switcher installed but not the one KWin uses (e.g. an
    # interrupted tests/windowswitcher/e2e.py left a test copy selected).
    if [ -d "$HOME/.local/share/kwin/tabbox/org.kde.windowsmodern.alttab" ]; then
        layout="$(kreadconfig6 --file kwinrc --group TabBox --key LayoutName 2>/dev/null || true)"
        if [ "$layout" = "org.kde.windowsmodern.alttab" ]; then
            pass "Alt+Tab uses the Windows Modern switcher"
        else
            warn "Alt+Tab uses '${layout:-the default}', not the installed Windows Modern switcher — run: ./install.sh alttab"
        fi
    fi
    for applet in systemtray icontasks; do
        if ! bash "plasma/applets/org.kde.windowsmodern.$applet/verify.sh"; then
            FAILED=1
        fi
    done
else
    echo ""
    echo "  (Run with --installed to also check the installed C++ applets.)"
fi

echo ""
if [ "$FAILED" -ne 0 ]; then
    echo -e "${RED}${BOLD}Health check FAILED${RESET} — fix the ✗ items above."
    exit 1
fi
echo -e "${GREEN}${BOLD}All checks passed.${RESET}"
