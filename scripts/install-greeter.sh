#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-greeter.sh — PLM boot greeter (build + user theme install)
#
#  Builds a patched plasma-login-greeter that loads our Windows Modern
#  Main.qml from the dark look-and-feel package, and installs the theme
#  QML to the user look-and-feel directory for --test mode.
#
#  This does NOT touch system files. To install as your actual boot
#  greeter, run:  sudo bash scripts/install-greeter-live.sh
# ───────────────────────────────────────────────────────────────────
# shellcheck source=scripts/install-lib.sh
source "$(dirname "$0")/install-lib.sh"

PLM_DIR="$SRC_DIR/third_party/plasma-login-manager"
PATCH_DIR="$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark/patches"
THEME_SRC="$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark/contents/lockscreen"
PATCHES=(
    "main-cpp.patch"
)

info "Installing Windows Modern PLM boot greeter..."

# ── Verify PLM source exists ──
if [ ! -d "${PLM_DIR}" ]; then
    err "PLM source not found at ${PLM_DIR}"
    err "Make sure the submodule is initialized:"
    err "  git submodule update --init --recursive"
    exit 1
fi

# ── Never build as root ──
# The source tree is user-owned. Building as root leaves root-owned files
# behind that later user runs cannot overwrite, and it means root executes
# build steps from a user-writable directory. The system install step
# (install-greeter-live.sh) re-invokes this script as the invoking user.
if [ "$UID" -eq 0 ]; then
    err "Do not run install-greeter.sh as root."
    err "Build as your normal user, then install system-wide with:"
    err "  sudo bash scripts/install-greeter-live.sh"
    exit 1
fi

# ── Verify PLM is clean ──
# Local edits in the submodule are stashed, never discarded. Set
# WM_ALLOW_RESET=1 to throw them away instead.
if [ -n "$(cd "${PLM_DIR}" && git status --porcelain 2>/dev/null)" ]; then
    if [ "${WM_ALLOW_RESET:-0}" = "1" ]; then
        warn "PLM repo has uncommitted changes. Discarding them (WM_ALLOW_RESET=1)..."
        (cd "${PLM_DIR}" && git reset --hard HEAD)
    else
        warn "PLM repo has uncommitted changes. Stashing them instead of discarding:"
        (cd "${PLM_DIR}" && git status --porcelain)
        (cd "${PLM_DIR}" && git stash push --include-untracked \
            -m "windows-modern auto-stash $(date +%Y%m%d%H%M%S)")
        warn "Restore them later with:  git -C ${PLM_DIR} stash pop"
    fi
fi

# ── Determine whether a build is needed ──
BUILD_DIR="${PLM_DIR}/build-user"
BINARY="${BUILD_DIR}/bin/plasma-login-greeter"
mkdir -p "${BUILD_DIR}"

BUILD_NEEDED=false
SOURCE_COMMIT_FILE="${BUILD_DIR}/.source_commit"
CURRENT_COMMIT=$(cd "${PLM_DIR}" && git rev-parse HEAD 2>/dev/null || echo "unknown")
if [ ! -f "$BINARY" ]; then
    BUILD_NEEDED=true
elif [ ! -f "$SOURCE_COMMIT_FILE" ] || [ "$(cat "$SOURCE_COMMIT_FILE" 2>/dev/null)" != "$CURRENT_COMMIT" ]; then
    BUILD_NEEDED=true
else
    for patch_name in "${PATCHES[@]}"; do
        patch_path="${PATCH_DIR}/${patch_name}"
        if [ "$patch_path" -nt "$BINARY" ]; then
            BUILD_NEEDED=true
            break
        fi
    done
fi

# Ensure patches are ALWAYS reverted, even if the build fails (set -e would
# otherwise skip the revert step and leave the submodule dirty).
revert_patches() {
    for patch_name in "${PATCHES[@]}"; do
        patch_path="${PATCH_DIR}/${patch_name}"
        # Only when it is applied: on clean source, `patch -R --batch` takes
        # the patch for "previously applied" and applies it FORWARD,
        # leaving the submodule dirty (and release.sh refusing to run).
        if patch -d "${PLM_DIR}" -R -p1 --dry-run -s -f < "${patch_path}" &>/dev/null; then
            patch -d "${PLM_DIR}" -R -p1 -s -f --no-backup-if-mismatch < "${patch_path}" || true
        fi
    done
}
trap revert_patches EXIT

if [ "$BUILD_NEEDED" = false ]; then
    step "Patched binary already up-to-date, skipping build."
else
    # ── Apply all PLM patches ──
    for patch_name in "${PATCHES[@]}"; do
        patch_path="${PATCH_DIR}/${patch_name}"
        step "Applying ${patch_name}..."
        if patch -d "${PLM_DIR}" -p1 --dry-run -s -f < "${patch_path}" 2>/dev/null; then
            patch -d "${PLM_DIR}" -p1 < "${patch_path}"
            echo "    Patch applied."
        else
            echo "    Patch already applied or not needed — skipping."
        fi
    done

    step "Building plasma-login-manager..."
    cd "${BUILD_DIR}" || exit 1

    # Configure if needed. A previously FAILED configure can leave a stale
    # CMakeCache.txt with no Makefile, so reconfigure whenever the Makefile
    # is missing.
    if [ ! -f Makefile ]; then
        echo "  Configuring CMake..."
        rm -f CMakeCache.txt
        cmake "${PLM_DIR}" \
            -DCMAKE_BUILD_TYPE=RelWithDebInfo \
            -DCMAKE_INSTALL_PREFIX="/usr" \
            -DQT_MAJOR_VERSION=6
    fi

    cmake --build . --target plasma-login-greeter --parallel "$(nproc)"
    echo "  Build complete."
    echo "$CURRENT_COMMIT" > "$SOURCE_COMMIT_FILE"
fi

# Patches are reverted automatically by the EXIT trap (defined above) so the
# submodule stays clean even if the build failed. The theme install below is
# pure file copy and needs no patch, so disabling the trap is fine here.
trap - EXIT
revert_patches

# ── Install theme to user look-and-feel directory for testing ──
THEME_DST="$HOME/.local/share/plasma/look-and-feel/org.kde.windowsmodern.dark/contents/lockscreen"
step "Installing theme to user directory for testing..."
mkdir -p "$(dirname "${THEME_DST}")"
rm -rf "${THEME_DST}"
cp -r "${THEME_SRC}" "${THEME_DST}"
echo "    Theme installed to: ${THEME_DST}"
echo ""
echo "  To reload theme changes without rebuild:"
echo "    cp plasma/look-and-feel/org.kde.windowsmodern.dark/contents/lockscreen/*.qml \\"
echo "       ~/.local/share/plasma/look-and-feel/org.kde.windowsmodern.dark/contents/lockscreen/"

echo ""
echo "=============================================="
echo "PLM boot greeter built successfully."
echo "=============================================="
echo ""
echo "To test safely (no system changes):"
echo "  ${BUILD_DIR}/bin/plasma-login-greeter --test"
echo ""
echo "To install as your ACTUAL boot greeter:"
echo "  sudo bash scripts/install-greeter-live.sh"
echo ""
warn "That step shows warnings and requires typing YES."
warn "Keep a TTY (Ctrl+Alt+F3) open before proceeding."
