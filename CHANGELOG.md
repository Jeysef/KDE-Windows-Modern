# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
the `Version` field shared by every component's metadata.

## [Unreleased]

### Fixed

- **Icon Tasks builds and loads on Plasma 6.8.** libplasma 6.8 dropped
  `PlasmaQuick::SharedQmlEngine` and bumped its sonames; the tooltip now loads
  its default content with a plain `QQmlComponent`.
- Uninstalling Icon Tasks no longer deletes the distro's stock icons-only task
  manager. Installing moves it aside to `/var/lib/windows-modern/backup/` and
  uninstalling restores it.
- System Tray: no crash when a plugin is unregistered twice, no duplicate or
  leaked tray entries when a status-notifier service registers twice, no
  dangling pointer when a tray icon disappears while its menu is being fetched,
  and themed tray icons no longer revert after an icon-theme-path change.
- Icon Tasks: no crash while the tooltip is still loading, and hovering no
  longer creates a tooltip window just to hide it.
- Digital Clock: time-zone offsets such as −7:30 now read "7:30 earlier"
  instead of "8:-30 earlier".
- Start Menu: right-clicking a search result always resolves the right app,
  even after the app list is re-sorted or apps are installed/removed, and app
  actions are triggered on the correct row.
- The session lock screen is built in a staging directory and swapped in
  atomically; a failed install can no longer leave a broken shell overlay.
  Old overlay backups are capped at two.
- The release bundle now contains `scripts/` (installing from a downloaded
  release previously failed immediately) and is built from the committed tree,
  so local build output is never shipped.
- Stale artifacts in `dist/` are no longer uploaded with a new release, and
  `package.sh` fails if component versions disagree with the release version.
- The panel layout scripts no longer contain a dead "fallback" that re-added
  the same task-manager ID.
- `verify-all.sh` now exits non-zero when a check fails (it previously always
  passed, so the release gate never fired).

### Security

- The boot greeter is no longer built as root: `install-greeter-live.sh`
  builds as the invoking user and only copies the finished binary into `/usr`.
  It refuses to overwrite a greeter binary that carries file capabilities and
  keeps its SELinux label.
- `install-greeter.sh` stashes local changes in the PLM submodule instead of
  running `git reset --hard`.
- `update-plm.sh` only accepts upstream release branches and tags, refuses to
  run on a dirty submodule, prints the resolved commit, and always reverts its
  patches.
- The System Tray installer no longer runs root scripts from `/tmp`.

### Changed

- The Icon Tasks applet is no longer packaged for the KDE Store; like the
  System Tray it is a compiled plugin and ships only in the GitHub bundle.
- `verify-all.sh` checks both theme variants, all five applets, layout drift,
  metadata, and shell scripts. `--installed` adds checks of the installed C++
  plugins; Icon Tasks has a new `verify.sh`.
- The System Tray `metadata.json` now declares its `KPlugin.Id`.

### Added

- CI (GitHub Actions): the repository health check plus a build-and-link check
  of both C++ applets against Fedora's Plasma.
- `scripts/ci-build.sh`, `CONTRIBUTING.md`, `.editorconfig`, `.shellcheckrc`.

## [1.0.0]

Initial release.
