#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  package-plugins.sh — pack the built C++ plugins for a release
#
#  Usage: scripts/package-plugins.sh <build-root> <out-dir>
#
#  <build-root> is what scripts/ci-build.sh built into. Writes
#  windows-modern-plugins-<platform-key>.tar.gz (both plugins, named by
#  their plugin id) to <out-dir> and appends its line to <out-dir>/SHA256SUMS.
#  The key (distro, Plasma, Qt, CPU) is the one install-lib.sh looks for.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

BUILD_ROOT="${1:?build root}"; OUT="${2:?output dir}"
key="$(plugin_platform_key)"
[ -n "$key" ] || { err "Unknown platform (needs rpm with plasma-workspace-libs and qt6-qtbase)."; exit 1; }

stage="$(mktemp -d)"
for pair in "systemtray:org.kde.windowsmodern.systemtray" "icontasks:org.kde.plasma.icontasks"; do
    dir="${pair%%:*}"; id="${pair#*:}"
    so="$BUILD_ROOT/$dir/lib/plasma/applets/$id.so"
    [ -f "$so" ] || { err "Missing $so (run scripts/ci-build.sh first)."; exit 1; }
    cp "$so" "$stage/$id.so"
done
mkdir -p "$OUT"
file="windows-modern-plugins-${key}.tar.gz"
tar -czf "$OUT/$file" -C "$stage" org.kde.windowsmodern.systemtray.so org.kde.plasma.icontasks.so
rm -rf "$stage"
(cd "$OUT" && sha256sum "$file" >> SHA256SUMS)
info "Packed $OUT/$file"
