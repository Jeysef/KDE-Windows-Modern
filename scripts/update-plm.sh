#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────────
#  update-plm.sh — Update Plasma Login Manager to a new upstream version
#
#  This script:
#    1. Fetches and updates PLM to the specified branch/tag
#    2. Reapplies our patches
#    3. Rebuilds the greeter
#
#  Usage:
#    ./scripts/update-plm.sh              # Update to current branch (Plasma/6.6)
#    ./scripts/update-plm.sh Plasma/6.7   # Update to specific branch
#    ./scripts/update-plm.sh v6.6.0       # Update to specific tag
# ───────────────────────────────────────────────────────────────────
set -e

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLM_DIR="${SRC_DIR}/third_party/plasma-login-manager"
PATCH_DIR="${SRC_DIR}/plasma/look-and-feel/org.kde.windowsmodern.dark/patches"
TARGET_BRANCH="${1:-Plasma/6.6}"

echo "Updating Plasma Login Manager to ${TARGET_BRANCH}..."

# ── 1. Verify PLM source exists ──
if [ ! -d "${PLM_DIR}/.git" ]; then
    echo "ERROR: PLM is not a git repository at ${PLM_DIR}"
    exit 1
fi

# ── 2. Reset PLM to clean state ──
echo "  Resetting PLM to clean state..."
(cd "${PLM_DIR}" && git fetch origin && git checkout "${TARGET_BRANCH}" && git pull --ff-only)

# ── 3. Apply all patches ──
PATCHES=(
    "main-cpp.patch"
)

for patch_name in "${PATCHES[@]}"; do
    patch_path="${PATCH_DIR}/${patch_name}"
    if [ ! -f "${patch_path}" ]; then
        echo "WARNING: Patch file not found: ${patch_path}"
        continue
    fi

    echo "  Applying ${patch_name}..."
    if patch -d "${PLM_DIR}" -p1 --dry-run -s -f < "${patch_path}" 2>/dev/null; then
        patch -d "${PLM_DIR}" -p1 < "${patch_path}"
        echo "    Patch applied."
    else
        echo "    ERROR: Patch failed to apply. Manual intervention required."
        echo "    Try: cd ${PLM_DIR} && git status"
        exit 1
    fi
done

# ── 4. Rebuild PLM ──
echo "  Building plasma-login-manager..."
BUILD_DIR="${PLM_DIR}/build-user"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Force reconfigure to pick up any API changes
rm -f CMakeCache.txt

cmake "${PLM_DIR}" \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="/usr" \
    -DQT_MAJOR_VERSION=6

cmake --build . --target plasma-login-greeter --parallel "$(nproc)"
echo "  Build complete."

echo ""
echo "=============================================="
echo "PLM updated to ${TARGET_BRANCH} successfully."
echo "=============================================="
echo ""
echo "To test:"
echo "  ${BUILD_DIR}/bin/plasma-login-greeter --test"
echo ""
echo "To install system-wide:"
echo "  sudo bash scripts/install-greeter-live.sh"
