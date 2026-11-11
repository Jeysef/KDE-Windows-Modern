#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  preview.sh — render the Alt+Tab switcher with mock windows to a PNG
#
#  Usage:  tests/windowswitcher/preview.sh [dark|light] [window-count] [out.png]
#
#  Uses a mock org.kde.kwin module, so it runs without KWin. Inside a
#  Plasma Wayland session a window flashes briefly and the GPU renderer
#  is used (rounded preview corners). Headless (QT_QPA_PLATFORM=offscreen)
#  uses the software renderer, which draws square corners — the same
#  fallback the real switcher uses.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

QML=""
for candidate in qml6 /usr/lib64/qt6/bin/qml /usr/lib/qt6/bin/qml qml; do
    if command -v "$candidate" &>/dev/null; then QML="$candidate"; break; fi
done
[ -n "$QML" ] || { echo "Qt 6 'qml' tool not found (Fedora: qt6-qtdeclarative-devel)." >&2; exit 1; }

variant="${1:-dark}"
count="${2:-7}"
out="$(realpath -m "${3:-alttab-preview-${variant}.png}")"

QT_FORCE_STDERR_LOGGING=1 QML_IMPORT_PATH="$HERE/mock" \
    "$QML" "$HERE/Preview.qml" -- "$variant" "$count" "$out" 2>&1 \
    | grep -vE '^(qt|kf)\.' || true
[ -f "$out" ] || { echo "Preview failed: $out was not written." >&2; exit 1; }
echo "$out"
