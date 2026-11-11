#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  run-tests.sh — automated tests for the Alt+Tab switcher view
#
#  Runs tst_switcherview.qml headlessly against a mock org.kde.kwin.
#  Needs Qt 6 QtTest (Fedora: qt6-qtdeclarative-devel) and Kirigami.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

RUNNER=""
for candidate in qmltestrunner6 /usr/lib64/qt6/bin/qmltestrunner /usr/lib/qt6/bin/qmltestrunner qmltestrunner; do
    if command -v "$candidate" &>/dev/null; then RUNNER="$candidate"; break; fi
done
[ -n "$RUNNER" ] || { echo "qmltestrunner (Qt 6) not found." >&2; exit 1; }

QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}" QT_FORCE_STDERR_LOGGING=1 \
    "$RUNNER" -import "$HERE/mock" -input "$HERE"
