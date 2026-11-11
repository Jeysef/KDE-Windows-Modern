#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  ci-build.sh — compile both C++ applets out of tree and check that the
#  resulting plugins resolve every symbol against the installed Plasma.
#
#  Catches the most common breakage: a Plasma/KF6 update that changes an
#  API or bumps a library soname. Installs nothing and needs no session.
#
#  Usage:  ./scripts/ci-build.sh [build-root]   (default: a temp dir)
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_ROOT="${1:-$(mktemp -d)}"
FAILED=0

for applet in systemtray icontasks; do
    src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.$applet"
    build="$BUILD_ROOT/$applet"
    echo "==> Building $applet in $build"
    cmake -S "$src" -B "$build" -DCMAKE_BUILD_TYPE=Release
    cmake --build "$build" --parallel "$(nproc)"

    so="$(find "$build" -path '*plasma/applets/*.so' -print -quit)"
    if [ -z "$so" ]; then
        echo "ERROR: $applet produced no plugin .so" >&2
        FAILED=1
        continue
    fi
    unresolved="$(ldd -r "$so" 2>&1 | grep -E 'not found|undefined symbol' || true)"
    if [ -n "$unresolved" ]; then
        echo "ERROR: $so does not link cleanly:" >&2
        echo "$unresolved" >&2
        FAILED=1
    else
        echo "==> $applet OK: $so"
    fi
done

exit "$FAILED"
