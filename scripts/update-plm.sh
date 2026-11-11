#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────────
#  update-plm.sh — Update Plasma Login Manager to a new upstream version
#
#  Maintainer tool. This script:
#    1. Fetches and checks out the requested upstream branch/tag
#    2. Verifies our patches still apply, and builds the greeter
#    3. Reverts the patches again so the submodule stays clean
#
#  Usage:
#    ./scripts/update-plm.sh              # Update to the default branch (Plasma/6.8)
#    ./scripts/update-plm.sh Plasma/6.7   # Update to a specific release branch
#    ./scripts/update-plm.sh v6.6.0       # Update to a specific release tag
#
#  Only upstream release branches (Plasma/6.N) and tags (vX.Y.Z) are accepted.
#  Set WM_ALLOW_ANY_REF=1 to override (e.g. to test master).
#
#  After a successful run, commit the new submodule pointer so normal
#  installs stay pinned:  git add third_party/plasma-login-manager
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLM_DIR="${SRC_DIR}/third_party/plasma-login-manager"
PATCH_DIR="${SRC_DIR}/plasma/look-and-feel/org.kde.windowsmodern.dark/patches"
TARGET_REF="${1:-Plasma/6.8}"
PATCHES=(
    "main-cpp.patch"
)

if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Do not run update-plm.sh as root; it only touches the user-owned submodule."
    exit 1
fi

# ── 0. Validate the requested ref ──
if ! [[ "$TARGET_REF" =~ ^Plasma/6\.[0-9]+$ ]] && ! [[ "$TARGET_REF" =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    if [ "${WM_ALLOW_ANY_REF:-0}" != "1" ]; then
        echo "ERROR: '${TARGET_REF}' is not an upstream release branch (Plasma/6.N) or tag (vX.Y.Z)."
        echo "       Set WM_ALLOW_ANY_REF=1 to override."
        exit 1
    fi
    echo "WARNING: Using non-release ref '${TARGET_REF}' (WM_ALLOW_ANY_REF=1)."
fi

echo "Updating Plasma Login Manager to ${TARGET_REF}..."

# ── 1. Verify PLM source exists and is clean ──
if [ ! -e "${PLM_DIR}/.git" ]; then
    echo "ERROR: PLM is not a git checkout at ${PLM_DIR}"
    echo "       Run: git submodule update --init --recursive"
    exit 1
fi
if [ -n "$(git -C "${PLM_DIR}" status --porcelain)" ]; then
    echo "ERROR: ${PLM_DIR} has uncommitted changes:"
    git -C "${PLM_DIR}" status --short
    echo "       Commit, stash, or revert them first — this script never discards work."
    exit 1
fi

# ── 2. Fetch and check out the target ──
echo "  Fetching upstream..."
git -C "${PLM_DIR}" fetch --tags origin
if git -C "${PLM_DIR}" rev-parse --verify --quiet "refs/remotes/origin/${TARGET_REF}" >/dev/null; then
    git -C "${PLM_DIR}" checkout --detach "origin/${TARGET_REF}"
else
    git -C "${PLM_DIR}" checkout --detach "${TARGET_REF}"
fi
RESOLVED_SHA="$(git -C "${PLM_DIR}" rev-parse HEAD)"
echo "  Resolved ${TARGET_REF} → ${RESOLVED_SHA}"

# ── 3. Apply patches (always reverted on exit, success or failure) ──
APPLIED_PATCHES=()
cleanup() {
    local rc=$?
    local i
    for (( i=${#APPLIED_PATCHES[@]}-1; i>=0; i-- )); do
        if ! patch --batch -R -d "${PLM_DIR}" -p1 -s < "${APPLIED_PATCHES[$i]}"; then
            echo "  WARNING: could not revert ${APPLIED_PATCHES[$i]} — inspect: git -C ${PLM_DIR} status"
        fi
    done
    exit "$rc"
}
trap cleanup EXIT

for patch_name in "${PATCHES[@]}"; do
    patch_path="${PATCH_DIR}/${patch_name}"
    if [ ! -f "${patch_path}" ]; then
        echo "ERROR: Patch file not found: ${patch_path}"
        exit 1
    fi

    echo "  Applying ${patch_name}..."
    if patch -d "${PLM_DIR}" -p1 --dry-run -s -f < "${patch_path}" >/dev/null 2>&1; then
        patch -d "${PLM_DIR}" -p1 -s < "${patch_path}"
        APPLIED_PATCHES+=("${patch_path}")
        echo "    Patch applied."
    else
        echo "    ERROR: ${patch_name} no longer applies to ${TARGET_REF}."
        echo "    Rebase the patch against ${RESOLVED_SHA}, then re-run."
        exit 1
    fi
done

# ── 4. Rebuild PLM ──
echo "  Building plasma-login-manager..."
BUILD_DIR="${PLM_DIR}/build-user"
mkdir -p "${BUILD_DIR}"

# Force reconfigure to pick up any API changes
rm -f "${BUILD_DIR}/CMakeCache.txt"

cmake -S "${PLM_DIR}" -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="/usr" \
    -DQT_MAJOR_VERSION=6

cmake --build "${BUILD_DIR}" --target plasma-login-greeter --parallel "$(nproc)"
echo "${RESOLVED_SHA}" > "${BUILD_DIR}/.source_commit"
echo "  Build complete."

echo ""
echo "=============================================="
echo "PLM updated to ${TARGET_REF} (${RESOLVED_SHA:0:12}) successfully."
echo "=============================================="
echo ""
echo "Pin it for normal installs:"
echo "  git add third_party/plasma-login-manager && git commit"
echo ""
echo "To test:"
echo "  ${BUILD_DIR}/bin/plasma-login-greeter --test"
echo ""
echo "To install system-wide:"
echo "  sudo bash scripts/install-greeter-live.sh"
