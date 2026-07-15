#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  release.sh — tag, package, and publish a GitHub release
#
#  Usage:
#    ./scripts/release.sh             # version auto-detected from metadata
#    ./scripts/release.sh 1.0.0        # explicit version
#    ./scripts/release.sh --dry-run   # verify + package, no tag/push
#
#  Prerequisites:
#    - gh CLI installed and authenticated
#    - clean working tree on main
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_SLUG="Jeysef/KDE-Windows-Modern"

BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"; RESET="\033[0m"
info()  { echo -e "${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
step()  { echo -e "${CYAN}  >>${RESET} $*"; }
warn()  { echo -e "${YELLOW}==>${RESET} $*"; }
err()   { echo -e "${RED}==>${RESET} $*" >&2; }

cd "$SRC_DIR"

# ── Resolve version ────────────────────────────────────────────────
VERSION=""
DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            sed -n '3,12p' "$0"; exit 0 ;;
        *) VERSION="$arg" ;;
    esac
done

if [[ -z "$VERSION" ]]; then
    VERSION="$(python3 -c "import json;print(json.load(open('plasma/look-and-feel/org.kde.windowsmodern.dark/metadata.json'))['KPlugin']['Version'])" 2>/dev/null || true)"
fi
[[ -z "$VERSION" ]] && { err "Could not determine version."; exit 1; }
TAG="v${VERSION}"
info "Release version: ${TAG}"

# ── 1. Pre-flight checks ───────────────────────────────────────────
info "Pre-flight checks..."

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" != "main" ]]; then
    err "Not on main (currently on $BRANCH). Switch first."
    exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
    err "Working tree is dirty. Commit or stash first."
    git status --short
    exit 1
fi
step "working tree clean"

if ! command -v gh &>/dev/null; then
    err "gh CLI not found. Install: https://cli.github.com"
    exit 1
fi
step "gh CLI present"

info "Running project health check..."
if ! ./verify-all.sh >/dev/null 2>&1; then
    err "verify-all.sh failed. Fix issues before releasing."
    ./verify-all.sh
    exit 1
fi
step "verify-all.sh passed"

# ── 2. Package artifacts ───────────────────────────────────────────
info "Packaging artifacts..."
./scripts/package.sh >/dev/null
step "artifacts built in dist/"

# ── 3. Dry-run stop ────────────────────────────────────────────────
if [[ "$DRY_RUN" -eq 1 ]]; then
    warn "Dry run — stopping before tag/push."
    echo -e "  Artifacts ready: ${BOLD}dist/${RESET}"
    exit 0
fi

# ── 4. Tag ─────────────────────────────────────────────────────────
info "Creating tag ${TAG}..."
if git rev-parse "$TAG" >/dev/null 2>&1; then
    err "Tag ${TAG} already exists."
    exit 1
fi
git tag -a "$TAG" -m "Windows Modern for KDE Plasma 6 — release ${TAG}"
step "tagged ${TAG}"

# ── 5. Push tag + create GitHub release ────────────────────────────
info "Pushing tag..."
git push origin "$TAG" || { err "Push failed. Is 'origin' configured and reachable?"; exit 1; }

info "Creating GitHub release..."
NOTES="$(cat <<EOF
## Windows Modern for KDE Plasma 6 — ${TAG}

A complete Windows 11-inspired visual transformation for KDE Plasma 6.
Includes window decorations, widget style, color schemes, Plasma desktop
themes, global themes, an icon pack, custom applets, a panel layout
template, wallpapers, and SDDM login themes — in dark and light variants.

### Install

Download and extract the full bundle \`.zip\`, then:

\`\`\`bash
./install.sh all
\`\`\`

See the README for component-by-component options and the C++ System Tray
build instructions.

**Requires KDE Plasma 6 and Kvantum.**
EOF
)"

gh release create "$TAG" \
    --repo "$REPO_SLUG" \
    --title "Windows Modern ${TAG}" \
    --notes "$NOTES" \
    --generate-notes

# Attach all built artifacts.
info "Uploading artifacts..."
gh release upload "$TAG" \
    --repo "$REPO_SLUG" \
    dist/*.zip

echo ""
info "Release ${TAG} published: https://github.com/${REPO_SLUG}/releases/tag/${TAG}"
echo -e "  ${BOLD}Next:${RESET} publish components to KDE Store — see docs/RELEASE.md"
