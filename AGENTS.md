# AGENTS.md

This codebase is yours: what it's for and how it's built are your call, and
you'll keep building on it.

- **Scope** — before adding or proposing a feature, read
  [`PRODUCT.md`](PRODUCT.md): vision, what's in, and what is deliberately left out.
- **Checks and conventions** — [`CONTRIBUTING.md`](CONTRIBUTING.md).
  `./verify-all.sh` must pass before every commit.

## Done means seen working on the desktop

Static checks and headless tests are not proof for anything KWin or Plasma
loads. Verify in the live session:

- Drive real input with uinput virtual devices (`python3-evdev`; the
  logged-in user can open `/dev/uinput`) and capture with
  `spectacle -b -n -f -o <file>`, then look at the image.
  `tests/panel/e2e.py` (panel) and `tests/windowswitcher/e2e.py`
  (Alt+Tab) do all of this; shared helpers live in `tests/e2e/`. Extend
  their scenarios rather than writing one-off scripts.
- Find UI by accessible name (`tests/e2e/a11y.py`), never by guessed
  coordinates: tray icons move as icons appear and hide. Use the AT-SPI
  *showing* state for popups — closed popups keep their old extents.
- Wiggle the pointer before driving input (`VirtualInput.announce()`) so
  the person at the machine keeps off the mouse; retry once on failure.
- Read `journalctl --user -b --since …` for QML errors from `kwin_wayland`
  and `plasmashell`.
- Use `pkexec` for anything that needs root. Never build as root.

## Traps

- **KWin caches compiled QML by file path for the whole session.**
  Reinstalling a switcher, effect or script at the same path changes nothing
  until logout. Test the current code with `tests/windowswitcher/e2e.py`,
  which installs under a fresh ID.
- **`dbus-send` defaults to sending a signal**, which KWin ignores. Reload
  KWin through `kwin_reconfigure` in `scripts/install-lib.sh`
  (`--type=method_call`).
- **QML name shadowing across components**: inside a delegate, `foo: foo`
  binds to the object's own `foo` property, not an outer `id: foo`. Give ids
  names that no property uses.
- **Hover over interactive children**: a `MouseArea`'s `containsMouse`
  drops when the pointer moves onto a child `MouseArea` stacked above it, so
  anything bound to it flickers. Track hover with a `HoverHandler`, and test
  hover in the live session; QtTest's synthetic hover hides the flicker.
- **Plasma's scripting API can crash plasmashell**: `evaluateScript`
  reading panel properties segfaults when a panel has no view (its screen
  is disconnected). Read `~/.config/plasma-org.kde.plasma.desktop-appletsrc`
  and `plasmashellrc` instead.
- **Sizes that follow content must not depend on geometry-driven
  visibility**: a view whose height tracks its content, with a scrollbar
  shown "when needed", loops (scrollbar → width → cell size → height).
  Decide such things from counts.
- **The Start button's "Shut down" is a split button**: its left part
  shuts down immediately; only the right-hand chevron opens the menu. Never
  click the left part in a test.
- **Native Qt menus close instantly under uinput input** (e.g. the
  taskbar's right-click menu); a real mouse works. Check those by hand.
- **`spectacle --output` rewrites the user's settings**: Spectacle stores
  every output path as its "last save location". Capture through
  `tests/e2e/session.py:screenshot`, which puts the old value back.
- **Shortcuts registered at runtime don't fire until marked present**:
  kglobalaccel's `setForeignShortcutKeys` stores keys for a new launcher
  (`app.desktop` / `_launch`) but the key does nothing until next login.
  Use `setShortcutKeys` with the SetPresent flag
  (`scripts/windows-shortcuts.py`).
- **dnf cancels a prepared system upgrade**: installing any package
  invalidates a pending `dnf system-upgrade`. Only call
  `install_packages` for packages that are really missing.
- **`cmd | grep -q` lies under `pipefail`** (all installer scripts set it):
  grep exits on the first match, a long-writing `cmd` gets SIGPIPE, and
  the condition comes out false. Use `grep -q pat <<< "$(cmd)"`.
- **Dolphin rewrites its toolbar file** (`dolphinui.rc`) and drops
  comments, so a marker comment cannot prove the file is ours. Record
  ownership in `~/.local/share/windows-modern/backup/`.
- **A plain QtQuick `Window` in a KWin script breaks scripting**: it never
  shows, and other scripts loaded afterwards silently do nothing. Use
  `PlasmaCore.Window` (it always draws the theme's popup frame: don't add
  a second one).
- **Removing a KWin script's package does not unload it**: call
  `org.kde.kwin.Scripting.unloadScript` too, or old and new copies run
  side by side. While iterating on QML scripts, install under fresh ids.
- **Dolphin is a locally patched rpm** (release `.wm1`, status-bar fix):
  `dnf upgrade` silently replaces it with stock — the squashed status bar
  returns until `scripts/fix-dolphin-statusbar.sh` is re-run (or Dolphin
  26.12 arrives, which has the fix). The rpms are kept in
  `~/.local/share/windows-modern/backup/dolphin-rpm/`.
- **`dnf autoremove` removes the user's own leftovers** (wine, mercurial,
  f44-backgrounds…): never run it after installing build deps; the dolphin
  build's `-devel` packages are meant to stay.
- **Headless renders use the software scene graph**: shader effects
  (`MultiEffect`) draw nothing there. Render inside the Wayland session to
  see the GPU path, and give shader-only visuals a software fallback.
- **The lock screen's shell overlay must not symlink `logout/`**: the logout
  screen resolves symlinks and refuses files outside the package ("Path
  traversal attempt detected"), so Log out silently does nothing.
  `install-sessionlock.sh` copies it; `verify-all.sh --installed` flags a
  copy that a Plasma update left stale.
- **Forks that reuse a stock plugin ID** (Icon Tasks) replace files owned by
  distro packages: move them to `/var/lib/windows-modern/backup/` and
  restore them on uninstall.
