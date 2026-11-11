#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  fix-dolphin-statusbar.sh — rebuild Fedora's dolphin with the
#  status-bar fix (squashed capacity bar / free-space text)
#
#  Dolphin 26.08 lays out StatusBarSpaceInfo with negative vertical
#  margins (-1). With non-Breeze styles (Kvantum, Fusion, ...) Qt
#  resolves that to a few pixels, so the capacity bar and the
#  "228 GiB free" button render as a sliver (KDE bug 483172).
#  Upstream fixed it after 26.08 by using the style's frame spacing.
#
#  This downloads Fedora's source rpm, applies the upstream fix,
#  rebuilds and installs it (release gets a .wm1 tag). The next
#  `dnf upgrade` of dolphin replaces the build again: from Dolphin
#  26.12 the stock package has the fix, on 26.08.x re-run this.
#  The built rpms are kept in ~/.local/share/windows-modern/backup/.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail
shopt -s lastpipe

WORK="$(mktemp -d /tmp/opencode/dolphin-fix.XXXXXX)"
BACKUP="$HOME/.local/share/windows-modern/backup/dolphin-rpm"
mkdir -p "$BACKUP"

die() { echo "  >> $*" >&2; exit 1; }
step() { echo "  >> $*"; }

cd "$WORK"

# 1. Already patched?
if rpm -q dolphin 2>/dev/null | grep -q '\.wm1'; then
    step "dolphin is already locally patched ($(rpm -q dolphin))."
    exit 0
fi
rpm -q dolphin &>/dev/null || die "dolphin is not installed."
rpm -q dolphin-libs &>/dev/null || die "dolphin-libs is not installed."

# 2. Source rpm
step "Downloading the dolphin source rpm"
dnf download --enablerepo='*source*' --source dolphin &>/dev/null \
    || die "Could not download the source rpm (is the fedora-source repo around?)."
srpms=(dolphin-*.src.rpm)
SRPM="${srpms[0]}"

# 3. Still buggy upstream? Extract the file and look for the negative margins.
rpm2cpio "$SRPM" | cpio -idm --quiet
TARBALL="$(find . -maxdepth 1 \( -name 'dolphin-*.tar.xz' -o -name 'dolphin-*.tar.bz2' \) -print -quit)"
[ -n "$TARBALL" ] || die "No source tarball in the source rpm."
mkdir src
tar -xf "$TARBALL" -C src --strip-components=1
CPP="src/src/statusbar/statusbarspaceinfo.cpp"
[ -f "$CPP" ] || die "statusbarspaceinfo.cpp not found in the tarball."
if ! grep -q 'setContentsMargins(2, -1, 0, -1)' "$CPP"; then
    step "This dolphin already has the fix upstream."
    step "Run 'dnf upgrade dolphin dolphin-libs' instead of rebuilding."
    exit 0
fi

# 4. Patch it, tag the release .wm1
python3 - "$CPP" <<'EOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = "    layout->setContentsMargins(2, -1, 0, -1); // \"-1\" makes it so the fixed height won't be ignored."
new = ("    const auto spacing = style()->pixelMetric(QStyle::PM_DefaultFrameWidth);\n"
       "    layout->setContentsMargins(2, spacing, 0, spacing);")
assert old in s
open(p, 'w').write(s.replace(old, new, 1))
EOF
diff -u --label a/src/statusbar/statusbarspaceinfo.cpp --label b/src/statusbar/statusbarspaceinfo.cpp \
    <(tar -xOf "$TARBALL" "$(tar -tf "$TARBALL" | grep 'statusbar/statusbarspaceinfo.cpp$' | head -1)") \
    "$CPP" > statusbar-margins.patch
[ -s statusbar-margins.patch ] || die "Patch generation failed."
cp statusbar-margins.patch dolphin-wm-statusbar-margins.patch

sed -i 's/^Release:[[:space:]]*\([0-9.]*\)%{?dist}/Release:        \1.wm1%{?dist}/' dolphin.spec
grep -q '^\* .*wm1$' dolphin.spec || sed -i 's/^%changelog/%changelog/' dolphin.spec
grep -q 'Patch1:' dolphin.spec || sed -i 's/^\(Patch:.*\)$/\1\nPatch1:         dolphin-wm-statusbar-margins.patch/' dolphin.spec
# an existing Patch1/Patch2 line would collide; fail loudly instead
grep -q '^Patch1:' dolphin.spec || die "Could not add the patch to the spec."

# 5. Build dependencies, build
step "Installing build dependencies (pkexec)"
pkexec sh -c "cd '$PWD' && dnf builddep -y dolphin.spec" &>/dev/null \
    || die "dnf builddep failed."

step "Building dolphin (a few minutes)"
mkdir -p build rpms
rpmbuild \
    --define "_sourcedir $PWD" --define "_specdir $PWD" \
    --define "_builddir $PWD/build" --define "_rpmdir $PWD/rpms" \
    --define "_srcrpmdir $PWD/srpms" --define "_buildrootdir $PWD/buildroot" \
    -bb dolphin.spec > rpmbuild.log 2>&1 || { tail -20 rpmbuild.log; die "rpmbuild failed."; }

RPMS="$(ls rpms/x86_64/dolphin-*.wm1*.rpm rpms/x86_64/dolphin-libs-*.wm1*.rpm 2>/dev/null)"
[ -n "$RPMS" ] || die "No rpms produced."
cp rpms/x86_64/dolphin-*.wm1*.rpm "$BACKUP/"

# 6. Install
step "Installing the patched rpm (pkexec)"
pkexec sh -c "cd '$PWD' && dnf install -y $RPMS" &>/dev/null \
    || die "Install failed."
rpm -q dolphin

cat <<EOF

  >> dolphin rebuilt with the status-bar fix and installed.
  >> Restart Dolphin to see it. The rpms are kept in $BACKUP
  >> (see the README.md there). A future 'dnf upgrade' replaces this
  >> build; from Dolphin 26.12 the stock package has the fix.
EOF
