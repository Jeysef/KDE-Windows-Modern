#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  package.sh — build per-component ZIPs for KDE Store / GitHub release
#
#  Usage:
#    ./scripts/package.sh            # build all components
#    ./scripts/package.sh <name>...   # build specific components
#    ./scripts/package.sh --list      # list available components
#
#  Output: dist/WindowsModern-<component>-<version>.zip  (KDE Store items)
#          dist/KDE-Windows-Modern-<version>.zip         (full GitHub bundle)
#          dist/.manifest  — exact list of artifacts built by this run;
#                            scripts/release.sh uploads only these.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$SRC_DIR/dist"
MANIFEST="$DIST_DIR/.manifest"

BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"; RESET="\033[0m"
info()  { echo -e "${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
step()  { echo -e "${CYAN}  >>${RESET} $*"; }
warn()  { echo -e "${YELLOW}==>${RESET} $*"; }
err()   { echo -e "${RED}==>${RESET} $*" >&2; }

# Extract version from a metadata file (json or desktop).
get_version() {
    local meta="$1"
    if [[ "$meta" == *.json ]]; then
        python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['KPlugin'].get('Version',''))" "$meta" 2>/dev/null \
            || echo ""
    else
        grep -E '^(X-KDE-PluginInfo-)?Version=' "$meta" 2>/dev/null | head -1 | cut -d= -f2 || echo ""
    fi
}

# ── Component registry ─────────────────────────────────────────────
# name|source-dir|metadata-file|kde-store-category
# (category blank = GitHub-only)
#
# The C++ applets (systemtray, icontasks) are deliberately absent: they are
# compiled .so plugins, and installing them as a KPackage from the store
# produces the broken "dark rectangle" applet. They ship only in the full
# GitHub bundle, built on the user's machine by install.sh.
COMPONENTS=(
    "color-schemes|$SRC_DIR/color-schemes|colorschemes|Color Schemes"
    "icons|$SRC_DIR/icons/windows-modern|index.theme|Icons"
    "aurorae-dark|$SRC_DIR/aurorae/windows-modern-dark-aurorae|metadata.desktop|Aurorae Themes"
    "aurorae-light|$SRC_DIR/aurorae/windows-modern-light-aurorae|metadata.desktop|Aurorae Themes"
    "desktoptheme-dark|$SRC_DIR/plasma/desktoptheme/Windows-modern-dark|metadata.desktop|Plasma 6 Themes"
    "desktoptheme-light|$SRC_DIR/plasma/desktoptheme/Windows-modern-light|metadata.desktop|Plasma 6 Themes"
    "wallpaper|$SRC_DIR/wallpaper/Windows-modern|metadata.json|Wallpapers"
    "applet-showdesktop|$SRC_DIR/plasma/applets/org.kde.windowsmodern.showdesktop|metadata.json|Plasma 6 Applets"
    "applet-startmenu|$SRC_DIR/plasma/applets/org.kde.windowsmodern.startmenu|metadata.json|Plasma 6 Applets"
    "applet-digitalclock|$SRC_DIR/plasma/applets/org.kde.windowsmodern.digitalclock|metadata.json|Plasma 6 Applets"
    "windowswitcher|$SRC_DIR/plasma/windowswitcher/org.kde.windowsmodern.alttab|metadata.json|KWin Switching Layouts"
    "layout-panel|$SRC_DIR/plasma/layout-templates/org.kde.windowsmodern.panel|metadata.json|Plasma 6 Layout Templates"
    "lookfeel-dark|$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark|metadata.json|Global Themes (Plasma 6)"
    "lookfeel-light|$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.light|metadata.json|Global Themes (Plasma 6)"
)

list_components() {
    echo -e "${BOLD}Available components:${RESET}"
    for c in "${COMPONENTS[@]}"; do
        IFS='|' read -r name dir meta cat <<< "$c"
        printf "  %-22s %s\n" "$name" "${cat:-(GitHub only)}"
    done
}

# Build a single component into dist/
build_one() {
    local entry="$1"
    IFS='|' read -r name dir meta cat <<< "$entry"

    if [[ ! -d "$dir" ]]; then
        err "Source dir missing: $dir"
        return 1
    fi

    local version
    if [[ "$meta" == "index.theme" ]]; then
        version="$(get_version "$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark/metadata.json")"
    elif [[ "$meta" == "colorschemes" ]]; then
        version="$(get_version "$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark/metadata.json")"
    elif [[ -f "$dir/$meta" ]]; then
        version="$(get_version "$dir/$meta")"
    else
        version=""
    fi
    [[ -z "$version" ]] && version="1.0.0"

    local outname="WindowsModern-${name}-${version}.zip"
    local outpath="$DIST_DIR/$outname"

    rm -f "$outpath"
    if [[ "$meta" == "colorschemes" ]]; then
        # Discover unpacks color schemes straight into color-schemes/, so the
        # .colors files must sit at the top of the zip, not in a folder.
        (cd "$dir" && zip -q "$outpath" ./*.colors)
    else
        (cd "$(dirname "$dir")" && zip -qr "$outpath" "$(basename "$dir")" \
            -x '*/build/*' '*/build-*/*' '*/CMakeFiles/*' '*/dev.sh' '*/BUILD.md' '*.orig' '*.rej')
    fi
    step "built $outname  <-  $(basename "$dir")"
    echo "$outpath" >> "$MANIFEST"
}

# ── Main ────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--list" ]]; then
    list_components
    exit 0
fi

mkdir -p "$DIST_DIR"
: > "$MANIFEST"

FULL_BUILD=1
if [[ $# -gt 0 ]]; then
    FULL_BUILD=0
    info "Building selected components..."
    for want in "$@"; do
        found=""
        for c in "${COMPONENTS[@]}"; do
            IFS='|' read -r name _ _ _ <<< "$c"
            if [[ "$name" == "$want" ]]; then found="$c"; break; fi
        done
        if [[ -z "$found" ]]; then
            err "Unknown component: $want  (run with --list to see options)"
            exit 1
        fi
        build_one "$found"
    done
else
    info "Building all KDE Store components..."
    for c in "${COMPONENTS[@]}"; do
        build_one "$c"
    done
fi

# ── GitHub release bundle ──────────────────────────────────────────
# Built with `git archive` so the bundle contains exactly the committed
# tree — never untracked local files or build directories. Paths marked
# export-ignore in .gitattributes (screenshots, plans) are left out.
info "Building full GitHub release bundle..."
FULL_VER="$(get_version "$SRC_DIR/plasma/look-and-feel/org.kde.windowsmodern.dark/metadata.json")"
[[ -z "$FULL_VER" ]] && FULL_VER="1.0.0"
FULL_OUT="$DIST_DIR/KDE-Windows-Modern-${FULL_VER}.zip"
if [[ -n "$(git -C "$SRC_DIR" status --porcelain --untracked-files=no)" ]]; then
    warn "Working tree has uncommitted changes — the full bundle is built from HEAD and will not include them."
fi
rm -f "$FULL_OUT"
git -C "$SRC_DIR" archive --format=zip --prefix="KDE-Windows-Modern-${FULL_VER}/" \
    -o "$FULL_OUT" HEAD
echo "$FULL_OUT" >> "$MANIFEST"
step "built KDE-Windows-Modern-${FULL_VER}.zip  (full bundle from $(git -C "$SRC_DIR" rev-parse --short HEAD))"

# ── Prune stale artifacts ──────────────────────────────────────────
# Anything in dist/ a full run did not build (renamed/removed components,
# older versions) must not be published under a new tag. Partial runs
# leave other artifacts alone.
if [[ "$FULL_BUILD" -eq 1 ]]; then
    for stale in "$DIST_DIR"/*.zip; do
        [[ -e "$stale" ]] || continue
        if ! grep -qxF "$stale" "$MANIFEST"; then
            warn "Removing stale artifact: $(basename "$stale")"
            rm -f "$stale"
        fi
    done
fi

# ── Version consistency ────────────────────────────────────────────
# The release tag comes from the dark look-and-feel metadata; every
# component shipped under that tag must carry the same version.
VERSION_MISMATCH=0
for c in "${COMPONENTS[@]}"; do
    IFS='|' read -r name dir meta _ <<< "$c"
    [[ "$meta" == "index.theme" || "$meta" == "colorschemes" ]] && continue
    [[ -f "$dir/$meta" ]] || continue
    v="$(get_version "$dir/$meta")"
    if [[ "$v" != "$FULL_VER" ]]; then
        err "Version mismatch: $name is ${v:-<none>}, release is $FULL_VER ($dir/$meta)"
        VERSION_MISMATCH=1
    fi
done
if [[ "$VERSION_MISMATCH" -ne 0 ]]; then
    err "Bump the component metadata (or the look-and-feel Version) so they agree, then re-run."
    exit 1
fi

echo ""
info "Done. Artifacts in ${DIST_DIR}:"
sed "s|^$DIST_DIR/|    |" "$MANIFEST"
