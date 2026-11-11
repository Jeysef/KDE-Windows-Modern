# Contributing to Windows Modern

Thanks for helping. Before proposing a feature, read
[`PRODUCT.md`](PRODUCT.md): it says what belongs in the project and what is
deliberately left out.

This document covers how the repository is laid out, the
checks every change must pass, and the conventions the project follows.

## Repository layout

| Path | What lives there |
|------|------------------|
| `install.sh`, `uninstall.sh` | Entry points. Each component has its own `scripts/install-<name>.sh`. |
| `scripts/install-lib.sh` | Shared helpers (paths, logging, apply/restart). Every installer sources it. |
| `plasma/applets/` | Applets. `startmenu`, `showdesktop`, `digitalclock` are pure QML; `systemtray` and `icontasks` are C++ forks of upstream Plasma applets. |
| `plasma/look-and-feel/`, `plasma/desktoptheme/`, `aurorae/`, `Kvantum/`, `color-schemes/` | Theme assets, always in **dark and light** variants. |
| `plasma/layout-templates/` | The "Add Panel → Windows Modern Panel" template. |
| `plasma/windowswitcher/` | The Alt+Tab switcher (a KWin window-switcher layout). |
| `tests/` | Automated tests and preview tools that run without a Plasma session. |
| `plasma/shells/` | Session lock screen (installed as a shell overlay). |
| `third_party/plasma-login-manager/` | Git submodule for the boot greeter (pinned). |
| `docs/` | Style spec, architecture notes, decision records, release runbook. |

## Checks

Run these before opening a pull request. CI runs the same ones.

```bash
./verify-all.sh            # repository health check — must pass
./scripts/ci-build.sh      # builds both C++ applets and checks they link
```

`verify-all.sh` checks that every component exists in both variants, that the
layout scripts have not drifted apart, that every `metadata.json` parses and
applets declare `Id`/`Name`/`Version`/`License`, and runs `bash -n` and
[shellcheck](https://www.shellcheck.net) on every tracked script. Install
shellcheck locally (`dnf install ShellCheck`, `apt install shellcheck`,
`pacman -S shellcheck`) — without it the check is skipped locally but still
enforced in CI.

On a machine with the applets installed, `./verify-all.sh --installed`
additionally inspects the installed System Tray and Icon Tasks plugins.

The Alt+Tab switcher has its own tests and a preview tool that run without
KWin (against a mock `org.kde.kwin`):

```bash
tests/run-qml-tests.sh                       # every headless QML suite (tests/*/tst_*.qml)
tests/windowswitcher/preview.sh dark 7 x.png # render a screenshot
tests/panel/e2e.py --out shots/              # the panel in your running session
tests/shortcuts/e2e.py --out shots/          # Windows shortcuts in your running session
tests/snaplayouts/e2e.py --out shots/        # Snap Layouts: drags a test window to the top
tests/windowswitcher/e2e.py --out shots/     # real Alt+Tab inside your running KWin
tests/windowswitcher/e2e.py --scenario close-buttons --out shots/
```

KWin caches the compiled QML of a switcher it has already shown for the
whole session, so reinstalling the switcher does not change what Alt+Tab
shows until you log out. `e2e.py` installs the current code under a one-off
ID (a fresh compile), drives a virtual keyboard and mouse through uinput,
saves screenshots, fails on any QML error KWin logs, and restores your
setting. The `close-buttons` scenario opens three disposable windows and
closes two of them from the switcher with the mouse. `--package DIR` runs a
scenario against other code (e.g. a `git archive` of an older commit) to
confirm a test fails where it should. It needs `python3-evdev`, access to
`/dev/uinput`, and Spectacle.

For QML changes, also run `qmllint` (`/usr/lib64/qt6/bin/qmllint` on Fedora)
on the files you touched and don't add new warnings.

## Conventions

### Shell scripts

- `#!/bin/bash` + `set -euo pipefail`; component installers get this from
  `scripts/install-lib.sh`.
- Use the `info` / `warn` / `err` / `step` helpers from `install-lib.sh`.
- Quote every expansion. Guard `rm -rf` targets with `${var:?}` when a
  variable could ever be empty. Use `$HOME`, never a literal `~` in paths.
- **Never build as root.** Root is only for copying finished artifacts into
  `/usr`; use `pkexec bash -s <<EOF` (no temp files in `/tmp`).
- **Never delete files owned by a distro package.** Move them aside to
  `/var/lib/windows-modern/backup/` and restore them on uninstall — see the
  Icon Tasks fork, which reuses the stock `org.kde.plasma.icontasks` ID.
- Anything that replaces a user's config (e.g. the session-lock shell overlay)
  must be built in a staging location and swapped in at the end, so a failed
  run never leaves a half-built state behind.

### Themes

- Every visual change lands in **both** the dark and light variants.
- The panel layout is defined in three files: the layout template and the
  dark/light global-theme layout scripts. The dark and light copies are
  identical; the template differs only in creating one panel instead of
  replacing all panels. Keep the widget sections identical —
  `verify-all.sh` enforces it.

### C++ applets

- Both are forks of upstream plasma-desktop code. Keep local changes small and
  commented so they survive the next upstream rebase; see
  `docs/SYSTEMTRAY_DECISION.md` for why the tray is a C++ fork.
- The QML is compiled into the `.so`. Never install these applets as a
  KPackage (it produces the "dark rectangle" bug); build and install with
  `./install.sh systray` / `./install.sh icontasks`.
- After a Plasma upgrade, rebuild and run `./scripts/ci-build.sh` — a soname
  bump or removed API shows up there first.

### Plugin IDs

Plugin IDs in docs must match `metadata.json`. If you rename one, update
`metadata.json`, `CMakeLists.txt`, the applet's `dev.sh`/`verify.sh`, the
layout scripts, `uninstall.sh`, `README.md`, and `docs/STYLE.md` in the same
commit.

### Icon pack

`icons/windows-modern/` is marked `--skip-worktree`. Never stage icon changes
by hand; use:

```bash
COMMIT_MSG="feat(icons): describe your change" ./scripts/commit-icons.sh
```

## Commits and pull requests

- [Conventional Commits](https://www.conventionalcommits.org):
  `fix(systemtray): …`, `feat(install): …`, `docs: …`, `chore: …`.
- One logical change per commit; add an entry under **Unreleased** in
  `CHANGELOG.md` for anything user-visible.
- Describe how you tested: which checks you ran, and for UI changes which
  Plasma version and variant (dark/light) you tried, ideally with a screenshot.

## Releases

Maintainers follow [`docs/RELEASE.md`](docs/RELEASE.md). `scripts/release.sh`
refuses to publish unless `verify-all.sh` passes and every component version
matches the release version.

## License

By contributing you agree that your contributions are licensed under the
GNU GPL v3 (see [`LICENSE`](LICENSE)). Code forked from KDE keeps its original
SPDX headers.
