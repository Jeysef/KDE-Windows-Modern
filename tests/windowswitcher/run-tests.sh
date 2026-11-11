#!/bin/bash
# Kept for muscle memory: runs all QML suites (tests/run-qml-tests.sh).
exec "$(cd "$(dirname "$0")/.." && pwd)/run-qml-tests.sh" "$@"
