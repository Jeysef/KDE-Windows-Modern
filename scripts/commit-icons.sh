#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  commit-icons.sh — commit the icons/windows-modern/ pack
#
#  The icon pack contains thousands of SVGs. To keep day-to-day git
#  operations fast, the files are marked with --skip-worktree after
#  committing, which hides them from `git status` and `git diff`.
#
#  Run this script whenever you want to commit icon changes.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ICON_DIR="icons/windows-modern"

cd "$REPO_ROOT"

if [ ! -d "$ICON_DIR" ]; then
    echo "Error: $ICON_DIR not found" >&2
    exit 1
fi

# Allow git to see changes again (no-op on first run)
if git ls-files -z "$ICON_DIR" | grep -qz .; then
    echo "Re-enabling git tracking for $ICON_DIR ..."
    git ls-files -z "$ICON_DIR" | xargs -0 -r git update-index --no-skip-worktree
fi

# Remove any stale tracked state for this path, then force-add it
# (the directory may be gitignored while it is being populated)
echo "Staging $ICON_DIR ..."
git rm -r --cached "$ICON_DIR" 2>/dev/null || true
git add -f "$ICON_DIR"

# Show a short summary
STAGED=$(git diff --cached --stat "$ICON_DIR" | tail -1)
echo "Staged: $STAGED"

# Commit
DEFAULT_MSG="feat(icons): update windows-modern icon pack"
if [ -n "${COMMIT_MSG:-}" ]; then
    msg="$COMMIT_MSG"
elif [ -t 0 ]; then
    read -r -p "Commit message [$DEFAULT_MSG]: " msg
fi
msg="${msg:-$DEFAULT_MSG}"
git commit -m "$msg"

# Hide from future git status/diff to keep the repo responsive
echo "Applying --skip-worktree to $ICON_DIR files ..."
git ls-files -z "$ICON_DIR" | xargs -0 -r git update-index --skip-worktree

echo "Done. Icon pack committed and hidden from git status/diff."
