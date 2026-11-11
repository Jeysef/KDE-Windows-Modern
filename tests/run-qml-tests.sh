#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  run-qml-tests.sh — run every headless QML test suite in tests/
#
#  Each tests/<area>/ with tst_*.qml files is one suite; a mock/ dir in
#  it is added to the QML import path. Needs Qt 6 QtTest
#  (Fedora: qt6-qtdeclarative-devel) and Kirigami.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

RUNNER=""
for candidate in qmltestrunner6 /usr/lib64/qt6/bin/qmltestrunner /usr/lib/qt6/bin/qmltestrunner qmltestrunner; do
    if command -v "$candidate" &>/dev/null; then RUNNER="$candidate"; break; fi
done
[ -n "$RUNNER" ] || { echo "qmltestrunner (Qt 6) not found." >&2; exit 1; }

failed=0
for suite in "$HERE"/*/; do
    compgen -G "$suite/tst_*.qml" >/dev/null || continue
    args=(-input "$suite")
    [ -d "$suite/mock" ] && args=(-import "$suite/mock" "${args[@]}")
    echo "── $(basename "$suite")"
    if ! QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}" QT_FORCE_STDERR_LOGGING=1 "$RUNNER" "${args[@]}"; then
        failed=1
    fi
done
exit "$failed"
