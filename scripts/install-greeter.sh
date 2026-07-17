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

# ── Verify PLM is clean ──
PLM_DIRTY=$(cd "${PLM_DIR}" && git status --porcelain 2>/dev/null | wc -l)
if [ "$PLM_DIRTY" -gt 0 ]; then
    warn "PLM repo has uncommitted changes. Resetting to clean state..."
    (cd "${PLM_DIR}" && git reset --hard HEAD)
fi

# ── Verify PLM HEAD matches the commit this repo pins ──
# A "clean" worktree is not enough: a clean checkout of some *other* ref would
# be patched, built, and installed as the system login binary. Refuse to build
# unless the submodule HEAD equals the gitlink recorded in the superproject.
PLM_HEAD=$(cd "${PLM_DIR}" && git rev-parse HEAD 2>/dev/null)
PLM_PINNED=$(cd "${SRC_DIR}" && git ls-tree HEAD -- third_party/plasma-login-manager 2>/dev/null | awk '{print $3}')
if [ -z "$PLM_PINNED" ]; then
    err "Could not read the pinned PLM commit from the superproject."
    err "Run this from a clean checkout with the submodule initialized."
    exit 1
fi
if [ "$PLM_HEAD" != "$PLM_PINNED" ]; then
    err "PLM submodule HEAD does not match the pinned commit."
    err "  pinned:   ${PLM_PINNED}"
    err "  checkout: ${PLM_HEAD:-<none>}"
    err "Refusing to build the login greeter from an unverified source."
    err "Restore the pinned revision with:"
    err "  git submodule update --init --recursive third_party/plasma-login-manager"
    exit 1
fi

# ── Apply all PLM patches ──
BUILD_NEEDED=false
for patch_name in "${PATCHES[@]}"; do
    patch_path="${PATCH_DIR}/${patch_name}"
    step "Applying ${patch_name}..."
    if patch -d "${PLM_DIR}" -p1 --dry-run -s -f < "${patch_path}" 2>/dev/null; then
        patch -d "${PLM_DIR}" -p1 < "${patch_path}"
        echo "    Patch applied."
        BUILD_NEEDED=true
    else
        echo "    Patch already applied or not needed — skipping."
    fi
done

# ── Build PLM (skip if binary exists and is newer than patches) ──
BUILD_DIR="${PLM_DIR}/build-user"
BINARY="${BUILD_DIR}/bin/plasma-login-greeter"
mkdir -p "${BUILD_DIR}"

# Ensure patches are ALWAYS reverted, even if the build fails (set -e would
# otherwise skip the revert step and leave the submodule dirty).
revert_patches() {
    for patch_name in "${PATCHES[@]}"; do
        patch_path="${PATCH_DIR}/${patch_name}"
        patch -d "${PLM_DIR}" -R -p1 < "${patch_path}" 2>/dev/null || true
    done
}
trap revert_patches EXIT

if [ -f "$BINARY" ] && [ "$BUILD_NEEDED" = false ]; then
    step "Patched binary already up-to-date, skipping build."
else
    step "Building plasma-login-manager..."
    cd "${BUILD_DIR}"

    # Configure if needed. A previously FAILED configure can leave a stale
    # CMakeCache.txt with no Makefile, so reconfigure whenever the Makefile
    # is missing — and force a fresh configure when we just patched source.
    if [ "$BUILD_NEEDED" = true ] || [ ! -f Makefile ]; then
        echo "  Configuring CMake..."
        rm -f CMakeCache.txt
        cmake "${PLM_DIR}" \
            -DCMAKE_BUILD_TYPE=RelWithDebInfo \
            -DCMAKE_INSTALL_PREFIX="/usr" \
            -DQT_MAJOR_VERSION=6
    fi

    cmake --build . --target plasma-login-greeter --parallel "$(nproc)"
    echo "  Build complete."
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
warn "This shows warnings and requires typing YES."
warn "Keep a TTY (Ctrl+Alt+F3) open before proceeding."
