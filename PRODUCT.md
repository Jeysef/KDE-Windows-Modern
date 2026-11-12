# Windows Modern — Product Brief

This file states what the project is for and what it is not. Every new feature,
and every "should we add X?" question, is judged against it.

## Vision

**Sit down at a Windows Modern desktop and feel at home as a Windows user,
on Linux.** It should look, move, and respond like Windows 11, so your
muscle memory just works, with KDE Plasma underneath.

It is a **curated** Windows: the best of Windows 11, a few things Windows 10
did better, and none of the parts that get in the user's way.

## Who it is for

- People moving from Windows to Linux who want their desktop to keep working
  the way their hands expect.
- Linux users who like the Windows 11 design language and want it done
  properly, not as a skin.
- The maintainer's own daily driver: if something feels off in daily use, it's
  a bug.

## Principles

1. **Behaviour matters as much as looks.** Keyboard shortcuts, Alt+Tab,
   window snapping, notifications and flyouts count as much as colours and
   icons. A Windows user should rarely hit "that's not where it is" or "that
   key does something else".
2. **Best of Windows 11, a little of Windows 10.** Windows 11 is the baseline.
   Windows 10 contributes where it was better: today the quick-settings/tray
   flyout (a Windows 11/10 hybrid) and the lock screen's bottom-left user
   switcher and error message. Anything else taken from Windows 10 needs a
   reason.
3. **No slop** (see the list below). If a Windows feature exists to sell,
   track, distract, or advertise, it doesn't come along.
4. **Dark and light are equal.** Every surface ships in both variants. A
   light-only or dark-only gap is a bug.
5. **Build on KDE, don't fight it.** Use KWin and Plasma's own mechanisms
   (window-switcher layouts, tiling, effects, look-and-feel packages, global
   shortcuts) wherever they exist. Forks of upstream code (System Tray, Icon
   Tasks) stay as small as possible so they survive Plasma updates.
6. **Never break the user's system.** Every install step is reversible, files
   owned by distro packages are moved aside and restored rather than deleted,
   nothing is built as root, and a failed install leaves the previous state
   intact.
7. **No Microsoft assets are redistributed.** Windows fonts, cursors, sounds
   and wallpapers are not shipped. Use openly licensed equivalents, and use
   the real thing only when the user already has it installed (for example
   Segoe UI).

## In scope

Windows 11 surfaces and behaviours a user reaches for without thinking:

- Taskbar, Start menu, system tray and quick settings, clock/calendar flyout,
  Show Desktop.
- Window chrome, controls, widget style, colours, icons, cursors, typography.
- Alt+Tab, Task View, window snapping and Snap Layouts.
- Notifications (toasts) and the volume/brightness OSD.
- Lock screen and login screen.
- Windows keyboard shortcuts (Win+E, Win+Tab, Win+Shift+S, Win+V, Win+.,
  Win+I, Win+D, Win+L, Win+arrows).
- Small per-app touches so common non-KDE apps match (see `app-decorations/`).

## Out of scope ("slop")

Not added, even on request, unless this brief changes:

- Widgets board / news and interests feed.
- "Recommended" (recent files, suggested apps) in Start.
- Web or Bing results mixed into local search.
- Copilot or any AI/assistant entry point.
- Ads, tips, "get started", promoted apps, suggestions.
- Windows 10 live tiles.
- A Recycle Bin icon on the desktop (the Trash is in Explorer's sidebar).

## Settled

- **Tray icons stay separate (Windows 10 style):** network, volume,
  battery and the rest are individual icons, each opening its own page.
  Windows 11's single grouped Quick Settings button was considered and
  not wanted.
- **Tray overflow chevron:** stays right of the tray icons, next to the
  clock. Windows 11 puts it on the left; the right side was preferred.
- **Window decoration:** the Aurorae decoration is a deliberate blend of
  Windows 11 and Windows 10 with **sharp corners**. Rounded corners and
  window shadows were considered and not wanted.
- **Lock and login screens look the same in light and dark mode,** as on
  Windows (white text over the wallpaper); there is no light variant.
- **Start menu:** feature-complete as far as the product is concerned.
  Changes are bug fixes and polish only. The Phase 2 ideas in
  `docs/STARTMENU_PLAN.md` (folders, launch tracking, command palette) are
  not planned.

## Roadmap

| Status | Item | Notes |
|--------|------|-------|
| Done | Windows 11 Alt+Tab switcher | `plasma/windowswitcher/`, selected by both global themes. |
| Done | Windows shortcuts, cursor, everyday apps | `./install.sh shortcuts` / `apps`; Win10OS cursors (fetched from upstream, GPL-3.0). Win+X (power-user menu) is not mapped. |
| Done | OSD position, Cascadia Mono | KWin script for the OSD; Cascadia Mono via `./install.sh apps`. |
| Done | Dolphin status bar | Patched rpm (`scripts/fix-dolphin-statusbar.sh`); stock fixes itself from Dolphin 26.12. |
| Done | Window animations | KDE's defaults match Windows 11; "Everything" only turns off the corner-sliding Show Desktop effect, unless the user set it. |
| Done | Fonts | `./install.sh fonts`: Segoe UI or Selawik, Cascadia Mono. |
| Done | Snap Layouts | Drag-to-top layout bar (`plasma/kwinscripts/org.kde.windowsmodern.snaplayouts`). The maximize-button hover flyout is not possible with an Aurorae decoration. |
| Done | Prebuilt C++ plugins | Releases carry the tray and taskbar plugins per Fedora/Plasma/Qt version; a release checkout installs them without a compiler, anything else builds from source. |
| Done | KDE Store | Every component is its own store item; the global themes depend on them, so a Discover install brings the look. Published with `scripts/store/`. |
| Done | Quick Settings | Hidden icons as launchers, toggles below, Windows 11 footer (battery, settings). |
| Later | Notifications in the clock flyout | Windows 11 stacks notifications above the calendar. Needs the notification server's history model (the tray's page only sees notifications since it started); the bell next to the clock covers it meanwhile. |

## How to judge a new idea

1. Would a Windows 11 user reach for it without thinking? If not, it probably
   doesn't belong.
2. Is it on the slop list? Then no.
3. Does KDE already provide the mechanism? Then theme or configure it rather
   than rebuild it.
4. Does it ship in both dark and light, and can it be uninstalled cleanly?
