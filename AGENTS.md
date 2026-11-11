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
- **Headless renders use the software scene graph**: shader effects
  (`MultiEffect`) draw nothing there. Render inside the Wayland session to
  see the GPU path, and give shader-only visuals a software fallback.
- **Forks that reuse a stock plugin ID** (Icon Tasks) replace files owned by
  distro packages: move them to `/var/lib/windows-modern/backup/` and
  restore them on uninstall.
