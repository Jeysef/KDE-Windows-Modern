# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
the `Version` field shared by every component's metadata.

## [Unreleased]

### Fixed

- After a restart, Alt+Tab could fall back to Breeze: an interrupted
  `tests/windowswitcher/e2e.py` left a test copy of the switcher selected,
  and its cleanup removed the copy. The test now restores the real
  switcher in that case, and `verify-all.sh --installed` warns when the
  installed Windows Modern switcher is not the one KWin uses.

## [1.1.2] - 2026-11-12

### Changed

- Tray flyout: the hidden tray icons above Quick Settings are drawn as
  plain launchers (centered icon over its name, a background only on
  hover), so they no longer look like the Quick Settings toggles below.

### Fixed

- No splash screen at login, as the global themes intend: they set the
  splash theme to "none", which Plasma does not know; it is "None".
- Tray flyout: two-line names (e.g. "Display Configuration") spilled
  below the card's hover background; icon size and margins now fit two
  lines. The pages' Back button has an accessible name.
- Log out (Start menu, or anywhere else) did nothing: the lock screen's
  shell overlay symlinked Plasma's logout screen, which Plasma now refuses
  to load from outside the package. The overlay copies it instead, and
  `verify-all.sh --installed` checks the copy is current.
- Login screen: showed Breeze icons, as the greeter's user cannot read the
  icon pack in your home. `install-greeter-live.sh` now installs the pack
  to `/usr/share/icons` and sets it as the greeter's icon theme; the
  greeter uninstall removes both. It also gives the greeter the Windows
  Modern Dark colors (it had Plasma's light default, so the wallpaper
  showed its light picture under a dark desktop); uninstall puts the
  greeter's original settings back. Neither script stops `plasmalogin` any
  more (that would end the running session).

## [1.1.1] - 2026-11-12

### Added

- KDE Store: the color schemes, icons, window decorations and Plasma styles
  (dark and light), the clock, Show desktop and Alt+Tab are now their own
  store items, and the global themes depend on them. Installing a global
  theme from Discover now also installs its look, the Win10OS cursors and
  the Start menu, clock, Show desktop and Alt+Tab widgets (the tray,
  taskbar and the rest still come from `./install.sh`).
- `scripts/store/`: publishing to the KDE Store from the command line
  (`store-publish.py`, driving a Firefox with its own profile, since the
  store has no upload API), clean listing screenshots taken on a temporary
  virtual desktop (`capture.py`), and the global themes' dependencies
  written from the product list (`set-dependencies.py`).

### Fixed

- The color schemes zip unpacked into `color-schemes/color-schemes/` when
  installed from the store, where Plasma does not look: its `.colors` files
  now sit at the top of the zip.

## [1.1.0] - 2026-11-11

### Added

- Quick Settings footer, as in Windows 11: battery level on the left
  (laptops; opens the battery page) and a Settings gear on the right
  (right-click for display, sound, network, power and notification
  settings).
- Prebuilt System Tray and Icon Tasks plugins: CI builds them for each
  supported Fedora and attaches them to releases, keyed by distro, Plasma
  and Qt version. Installing from a release checkout downloads the
  matching build (checksum-verified) and skips the compiler and -devel
  packages; any other checkout, or a system without a match, builds from
  source as before.
- Snap Layouts, as in Windows 11: drag a window towards the top edge, and
  a bar with six layouts (50/50, 66/33, thirds, half + quarters, four
  quarters, 25/50/25) appears at the top centre; hovering a cell outlines
  the target area, dropping snaps the window there (KWin script, with
  `./install.sh shortcuts`).
- `./install.sh shortcuts`: Windows keyboard shortcuts. Win+Up/Down
  maximize, restore, minimize and snap to quarters as on Windows 11 (new
  KWin script), Win+Tab opens Task View, Win+R Run, Win+A Quick Settings,
  Win+N notifications, Win+M / Win+Home minimize all / others, Win+PrtSc
  saves a full screenshot silently, Alt+PrtSc captures the active window.
  Previous keys are backed up; `./uninstall.sh shortcuts` restores them.
- `./install.sh apps`: Haruna (default video player), KWrite, Mission
  Center (Flathub, per user) on Ctrl+Shift+Esc, and Snipping Tool
  behaviour for Spectacle (capture on release, copy, save), and an Up
  button in Dolphin's toolbar as in File Explorer.
- `./install.sh fonts`: Cascadia Mono (Windows 11's monospace font) as the
  fixed-width font, and, when Segoe UI is not installed, Microsoft's open
  Selawik standing in for it (downloaded, checksum-pinned, aliased so
  "Segoe UI" resolves to it). Fonts change only if still distro defaults.
- `./install.sh deps`: Kvantum, Flatpak and the C++ applets' build
  dependencies, so "Everything" works on a fresh machine.
- "Everything" now also installs dependencies, shortcuts and apps.
- `tests/shortcuts/e2e.py` presses every new shortcut in the live session
  and checks the result.
- **Windows 11-style Alt+Tab switcher** (`./install.sh alttab`, included in
  `all`): aspect-correct previews in centered rows, icon + title headers,
  close on hover, rounded focus ring, keyboard navigation across rows. Both
  global themes select it. Comes with a mock-KWin preview tool, QML tests,
  and an end-to-end test that drives a real Alt+Tab in the running KWin.
- `PRODUCT.md`: the product brief — vision, scope, and what is deliberately
  left out.
- CI (GitHub Actions): the repository health check plus a build-and-link check
  of both C++ applets against Fedora's Plasma.
- `scripts/ci-build.sh`, `CONTRIBUTING.md`, `.editorconfig`, `.shellcheckrc`.

### Changed

- Tray flyout: Bluetooth and Brightness & Color (already in Quick
  Settings below), Weather, Vaults and the X11 video bridge no longer sit
  behind the chevron. Pin one, set it to "Always hidden", or let it need
  attention and it shows again. The card grid fits without scrolling.
- Taskbar: no speaker badge on the icons of apps playing audio, as on
  Windows (mute from the tray's volume page). The option stays in the
  taskbar's settings.
- Cursor: the Win10OS cursors (GPL-3.0, Windows 10 style), fetched from
  upstream at a pinned commit by `./install.sh themes` / `lookfeel` when
  not already installed, replace Breeze Light in both global themes.
- "Everything" turns off KWin's Show Desktop effect that slides all windows
  to the screen corners (Windows doesn't), unless you set it yourself.
- Volume, brightness and keyboard-layout pop-ups appear bottom-centre just
  above the taskbar, as on Windows 11, instead of two-thirds down the
  screen (KWin script, installed with `./install.sh shortcuts`).
- Tooltips wait half a second before appearing, like Windows, instead of
  flashing up under every button the pointer crosses.
- Dark theme: selected items in file lists and sidebars (Dolphin, System
  Settings, file dialogs) are a light accent tint with white text, as in
  Windows 11 Explorer, instead of a solid light-blue bar whose white text
  was hard to read.
- Keyboard layouts are labelled by language in the tray, as on Windows
  (`ENG`, `CES`, `DEU` instead of `us`, `cz`, `de`), from XKB's own data so
  every language works. `./install.sh layout` sets it; your own labels are
  kept, and two layouts of one language keep their codes.
  The label uses the clock's text size (the stock widget scaled it to
  the icon cell, larger than the clock on a 48 px panel).
- System tray: the last icons before the clock are always input language,
  network, volume, battery, in that order, as on Windows 11. Other icons
  (apps, Bluetooth, clipboard...) come before them.
- System tray: like Windows 11, only input language, network, volume,
  battery, notifications and the camera-in-use indicator show by default.
  Everything else (apps, Bluetooth, clipboard, brightness...) waits behind
  the chevron until it needs attention or you pin it ("Always shown" in
  the tray settings).
- The Icon Tasks applet is no longer packaged for the KDE Store; like the
  System Tray it is a compiled plugin and ships only in the GitHub bundle.
- The global themes no longer reference Plasma 5's Breeze window and desktop
  switchers, which Plasma 6 no longer ships.
- `verify-all.sh` checks both theme variants, all five applets, layout drift,
  metadata, and shell scripts. `--installed` adds checks of the installed C++
  plugins; Icon Tasks has a new `verify.sh`.
- The System Tray `metadata.json` now declares its `KPlugin.Id`.

### Fixed

- Start menu search: results appearing under a resting pointer took the
  selection, so Enter ran whatever was under the mouse instead of the best
  match. The pointer now selects a result only once it actually moves.
  Result rows are also exposed to screen readers (name, selected).
- Quick Settings flyout: scrolling over the overflow cards (e.g. with a
  touchpad over "Brightness & Color") changed the brightness or volume.
  The wheel now scrolls the card grid and never reaches the applet's icon.
- "Recent Files" in Dolphin's Places panel drew a dark-gray line-art
  document that clashed with the yellow folder icons around it. The pack's
  `document-open-recent` is now a full-colour white document with a blue
  clock badge, in the style of the rest of the Places icons (the actions
  and places variants are identical, since Qt resolves the name to
  `actions/` first).
- Dolphin's status bar: the capacity bar and the "228 GiB free" text were
  squashed to a sliver with our Kvantum style (upstream bug 483172 —
  negative margins in `StatusBarSpaceInfo`). Fedora's dolphin is now
  locally rebuilt with the upstream fix (`scripts/fix-dolphin-statusbar.sh`,
  release tag `.wm1`); the next `dnf upgrade` replaces it — from Dolphin
  26.12 the stock package contains the fix, so nothing needs re-running.
- Installer conditions written as `cmd | grep -q` could come out false
  under `pipefail` when `cmd` printed a lot (`commit-icons.sh` skipped
  re-enabling tracking of the icon pack); all now read the output first.
- System tray: network, volume and (on laptops) battery always show, as on
  Windows. The battery disappeared behind the chevron when the laptop was
  full and on the charger, because Plasma marks it passive then.
- Login screen: builds and runs again on Plasma 6.8. Plasma Login Manager
  is pinned to 6.8.2 (the 6.6 build needed a libPlasmaQuick that Plasma
  6.8 no longer ships), the patch is rebased, and the theme follows 6.8's
  greeter interface (event filter, session selection, security-key
  messages). `--test` now loads your own copy of the theme.
- Login screen: live network and battery icons (the network icon was
  fixed), the date in your language, and the inert accessibility button
  is now an on-screen keyboard toggle, shown when one is available.
- Greeter uninstall could put back an outdated login greeter: it restored
  the `.orig` backup even when a package update had already replaced the
  patched greeter, and even when the backup needed libraries a Plasma
  update had removed (it would no longer start). It now does nothing when
  the greeter is the distro's own file, never restores a backup that
  doesn't link, and the installer refreshes the backup after updates.
- Lock screen: the network, volume and battery icons show the real state
  (signal strength, mute and level, charge and charging) instead of fixed
  "full" icons; the battery icon hides on machines without one.
- Lock screen: the date follows your language ("středa 11. listopadu"),
  the time is centred over it, and media controls appear again (a wrong
  config name had switched them off for good).
- Dark theme: the mouse cursor theme it set did not exist, so the cursor
  fell back (for GTK apps too). Both themes now use an installed cursor
  theme (now Win10OS, see Changed).
- `./install.sh themes` run on its own now applies the dark Plasma theme;
  it asked for a theme named `Windows-modern`, which does not exist.
- Clock: time and date now share the normal UI font size, as on Windows
  (the time used to grow with the panel and the date was shrunk to 65 %),
  and the date shows the full year (`11.11.2026`). The clock cell now
  sizes to its text; a longer date used to overflow a square cell. The
  "Compact padding" setting is gone with the old sizing.
- Switches: no more white (dark theme) or black (light theme) rim on the
  left of a switched-on switch. The off state now looks like Windows 11
  (grey outline, grey knob). Both SVGs are generated by
  `scripts/gen-switch-svg.py` and checked by `tests/theme/check-switch.py`.
- Show Desktop: the second click restores the windows again. It now uses
  KWin's show-desktop mode (the same state as Win+D) instead of minimizing
  windows one by one, which lost track of them mid-way.
- Start menu: each keystroke in the search field ran the search twice (a
  duplicate change signal) and logged a warning.
- Start menu: the Start button is exposed to screen readers and other
  accessibility tools (it was missing from the accessibility tree).
- Installing a C++ applet no longer stops Plasma Shell before asking for
  the password; cancelling the prompt used to leave the desktop without a
  shell. The plugin is installed as a new file, so the running shell is not
  disturbed, and any later failure restarts the shell.
- The C++ applets no longer set `KPlugin.Id` in their embedded metadata
  (KF6 derives it from the file name and warns about an explicit one).
- Icon Tasks: the task right-click handler matches upstream Plasma 6.8
  (no exclusive-grab gesture policy).
- Installing several applets at once (`./install.sh applets` or `all`) no
  longer leaves the desktop without Plasma Shell: the C++ applet installers
  stop it, and the final restart now also starts a stopped shell.
- System tray: the Quick Settings flyout fits its content instead of
  showing an empty band above the toggles, and the hidden-icon tiles line
  up with the toggles.
- Digital Clock: the flyout's date line uses the locale's own long date
  without the year ("středa 11. listopadu", not "středa, listopadu 11").
- Icon Tasks: the window-preview tooltip no longer logs layout warnings
  every time it opens.
- KWin settings applied by the installer (Alt+Tab switcher, border size,
  per-monitor Alt+Tab) now take effect immediately. The reload request was
  sent as a D-Bus signal, which KWin ignores, so they only applied after
  logging out.
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

## [1.0.0]

Initial release.
