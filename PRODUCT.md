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

## Settled

- **Start menu:** feature-complete as far as the product is concerned.
  Changes are bug fixes and polish only. The Phase 2 ideas in
  `docs/STARTMENU_PLAN.md` (folders, launch tracking, command palette) are
  not planned.

## Roadmap

| Status | Item | Notes |
|--------|------|-------|
| In progress | Windows 11 Alt+Tab switcher | KWin window-switcher layout shipped with both global themes. Currently both use the Breeze switcher. |
| Next | Muscle-memory batch | Windows shortcuts; a cursor theme that actually exists (the dark defaults point at a missing theme); Segoe UI when installed, Selawik otherwise; toast position and OSD; window animations. |
| Next | Snap Layouts | Investigate first: a KWin script plus a Windows 11-style picker on top of KWin's built-in tiling. |
| Later | Light lock and login screen | The lock screen is dark-only today. |
| Later | Prebuilt C++ plugins | So installing the tray and taskbar doesn't need a compiler. CI already builds them against Fedora. |

## How to judge a new idea

1. Would a Windows 11 user reach for it without thinking? If not, it probably
   doesn't belong.
2. Is it on the slop list? Then no.
3. Does KDE already provide the mechanism? Then theme or configure it rather
   than rebuild it.
4. Does it ship in both dark and light, and can it be uninstalled cleanly?
