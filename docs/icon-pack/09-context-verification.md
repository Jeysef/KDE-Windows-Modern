# Context Verification Report — windows-modern-v2

**Date:** 2026-06-29  
**Theme:** `~/.local/share/icons/windows-modern-v2/`  
**Source Packs:** icons_v2/sources/{Eleven, Cobalt, Win11, We10X, Fluent, Windows-Eleven, Fluentwin, Windows-Beuty}/  

---

## 1. Initial Scan Results

| Context | Icon Count |
|---------|-----------|
| actions/ | 2,666 |
| animations/ | 55 |
| apps/ | 1,045 |
| categories/ | 113 |
| devices/ | 89 |
| emblems/ | 28 |
| emotes/ | 21 |
| mimetypes/ | 518 |
| places/ | 61 |
| status/ | 338 |
| **TOTAL** | **4,934** |

---

## 2. KCM .desktop File Analysis

Scanned 82 KCM `.desktop` files (`/usr/share/applications/kcm_*.desktop`) and 25 systemsettings categories (`/usr/share/systemsettings/categories/*.desktop`).

All referenced `Icon=` values are now satisfied in `categories/` or `apps/`.

---

## 3. Context Placement Rules Applied

| # | Pattern | Expected Context |
|---|---------|-----------------|
| 1 | `preferences-desktop-*` | categories/ |
| 2 | `preferences-system-*` | categories/ |
| 3 | `preferences-other-*` | categories/ |
| 4 | `applications-*` (category icons) | categories/ |
| 5 | `network-wireless-*`, `network-wired-*`, `bluetooth-*` (tray) | status/ |
| 6 | `audio-volume-*`, `battery-*` | status/ |
| 7 | `dialog-*`, `security-*`, `software-update-*` | status/ |
| 8 | `drive-*`, `media-*`, `input-*`, `printer-*`, `scanner-*` | devices/ |
| 9 | `document-*`, `edit-*`, `format-*`, `go-*`, `media-playback-*`, `view-*`, `zoom-*` | actions/ |
| 10 | `folder-*`, `user-*`, `network-server`, `network-workgroup` | places/ |
| 11 | `face-*` | emotes/ |
| 12 | `emblem-*` | emblems/ |
| 13 | `text-*`, `audio-*`, `video-*`, `image-*`, `application-*`, `x-office-*`, `font-*`, `package-*` | mimetypes/ |
| 14 | `accessories-*`, `utilities-*`, branded apps | apps/ |

---

## 4. Misplaced Icons Found & Fixed

### 4.1 preferences-desktop-* in apps/ → categories/ (38 icons)

These were present in `apps/` but **not** in `categories/`. KDE KCMs (Settings modules) search `categories/` first, so missing them there causes fallback resolution, potentially picking wrong icons from fallback themes.

**Fixed:** Copied from `apps/` to `categories/` (duplication is correct — KDE resolves per context).

| Icon | Source |
|------|--------|
| `preferences-desktop-accessibility.svg` | apps/ → categories/ |
| `preferences-desktop-apps.svg` | apps/ → categories/ |
| `preferences-desktop-color.svg` | apps/ → categories/ |
| `preferences-desktop-default-applications.svg` | apps/ → categories/ |
| `preferences-desktop-display.svg` | apps/ → categories/ |
| `preferences-desktop-display-color.svg` | apps/ → categories/ |
| `preferences-desktop-effects.svg` | apps/ → categories/ |
| `preferences-desktop-emoticons.svg` | apps/ → categories/ |
| `preferences-desktop-feedback.svg` | apps/ → categories/ |
| `preferences-desktop-font.svg` | apps/ → categories/ |
| `preferences-desktop-font-installer.svg` | apps/ → categories/ |
| `preferences-desktop-gaming.svg` | apps/ → categories/ |
| `preferences-desktop-gestures-screenedges.svg` | apps/ → categories/ |
| `preferences-desktop-gestures-touch.svg` | apps/ → categories/ |
| `preferences-desktop-icons.svg` | apps/ → categories/ |
| `preferences-desktop-keyboard.svg` | apps/ → categories/ |
| `preferences-desktop-locale.svg` | apps/ → categories/ |
| `preferences-desktop-menu-edit.svg` | apps/ → categories/ |
| `preferences-desktop-mouse.svg` | apps/ → categories/ |
| `preferences-desktop-multimedia.svg` | apps/ → categories/ |
| `preferences-desktop-notifications.svg` | apps/ → categories/ |
| `preferences-desktop-plasma.svg` | apps/ → categories/ |
| `preferences-desktop-plasma-theme.svg` | apps/ → categories/ |
| `preferences-desktop-screensaver.svg` | apps/ → categories/ |
| `preferences-desktop-search.svg` | apps/ → categories/ |
| `preferences-desktop-sound.svg` | apps/ → categories/ |
| `preferences-desktop-tablet.svg` | apps/ → categories/ |
| `preferences-desktop-theme.svg` | apps/ → categories/ |
| `preferences-desktop-theme-applications.svg` | apps/ → categories/ |
| `preferences-desktop-theme-global.svg` | apps/ → categories/ |
| `preferences-desktop-theme-windowdecorations.svg` | apps/ → categories/ |
| `preferences-desktop-touchscreen.svg` | apps/ → categories/ |
| `preferences-desktop-user.svg` | apps/ → categories/ |
| `preferences-desktop-user-feedback.svg` | apps/ → categories/ |
| `preferences-desktop-user-password.svg` | apps/ → categories/ |
| `preferences-desktop-users.svg` | apps/ → categories/ |
| `preferences-desktop-virtual.svg` | apps/ → categories/ |
| `preferences-desktop-wallpaper.svg` | apps/ → categories/ |

### 4.2 preferences-system-* in apps/ → categories/ (19 icons)

| Icon | Source |
|------|--------|
| `preferences-system-backup.svg` | apps/ → categories/ |
| `preferences-system-bluetooth.svg` | apps/ → categories/ |
| `preferences-system-details.svg` | apps/ → categories/ |
| `preferences-system-disks.svg` | apps/ → categories/ |
| `preferences-system-hotcorners.svg` | apps/ → categories/ |
| `preferences-system-linux.svg` | apps/ → categories/ |
| `preferences-system-login.svg` | apps/ → categories/ |
| `preferences-system-notifications.svg` | apps/ → categories/ |
| `preferences-system-notifications-rtl.svg` | apps/ → categories/ |
| `preferences-system-power.svg` | apps/ → categories/ |
| `preferences-system-power-management.svg` | apps/ → categories/ |
| `preferences-system-privacy.svg` | apps/ → categories/ |
| `preferences-system-search.svg` | apps/ → categories/ |
| `preferences-system-splash.svg` | apps/ → categories/ |
| `preferences-system-tabbox.svg` | apps/ → categories/ |
| `preferences-system-time.svg` | apps/ → categories/ |
| `preferences-system-users.svg` | apps/ → categories/ |
| `preferences-system-windows.svg` | apps/ → categories/ |
| `preferences-system-windows-effect-flipswitch.svg` | apps/ → categories/ |
| `preferences-system-windows-tiling.svg` | apps/ → categories/ |

### 4.3 Other contexts → categories/ (5 icons)

| Icon | Source |
|------|--------|
| `preferences-desktop-display-randr.svg` | status/ → categories/ |
| `preferences-system-session-services.svg` | actions/ → categories/ |
| `preferences-devices-printer.svg` | apps/ → categories/ |
| `preferences-online-accounts.svg` | apps/ → categories/ |
| `preferences-security.svg` | apps/ → categories/ |
| `preferences-web-browser-shortcuts.svg` | apps/ → categories/ |

### 4.4 Bluetooth icons → status/ (5 icons)

Bluetooth icons were in `apps/` and `devices/` but not in `status/`. System tray and KDE Bluetooth applet resolve from `status/`.

| Icon | Source |
|------|--------|
| `bluetooth.svg` | devices/ → status/ |
| `bluetooth-inactive.svg` | devices/ → status/ |
| `bluetooth-48.svg` | apps/ → status/ |
| `bluetooth-radio.svg` | apps/ → status/ |
| `bluetoothradio.svg` | apps/ → status/ |

### 4.5 input-keyboard-virtual → devices/ (1 icon)

| Icon | Source |
|------|--------|
| `input-keyboard-virtual.svg` | apps/ → devices/ |

---

## 5. Icons Already Correctly Placed (No Action Needed)

These icons are in the correct contexts per the rules and were **not** moved:

- **status/:** `audio-volume-*`, `battery-*`, `network-wireless-*`, `network-wired-*`, `dialog-error/information/password/question/warning`, `security-high/medium/low`, `software-update-available/urgent`, `user-available/away/idle/offline` (user presence), `printer-error/printing-symbolic` (printer state), `input-keyboard-virtual-on/off` (keyboard state)
- **devices/:** `audio-card`, `audio-input-microphone`, `audio-speakers`, `camera-*`, `drive-*`, `input-*`, `media-*`, `printer*`, `scanner`, `video-display`, `video-television`
- **places/:** `folder*`, `user-*`, `network-server`, `network-workgroup`
- **actions/:** `document-*`, `edit-*`, `format-*`, `go-*`, `media-playback-*`, `view-*`, `zoom-*`, `system-lock-screen/log-out/reboot/shutdown`, `dialog-*` (application-specific, e.g., Inkscape dialogs)
- **emotes/:** `face-*`
- **emblems/:** `emblem-*`
- **mimetypes/:** `text-*`, `audio-x-*`, `video-x-*`, `image-*` (MIME), `application-*` (MIME), `x-office-*`, `font-*`, `package-*`

---

## 6. False Positives (Intentionally Not Moved)

Some icons match prefix patterns but belong in their current context for good reasons:

| Icon Pattern | Current Context | Reason |
|-------------|----------------|--------|
| `dialog-apply`, `dialog-cancel`, `dialog-ok`, etc. | actions/ | Application-specific dialogs (Inkscape, etc.), not freedesktop standard dialog-icons |
| `audio-card`, `audio-input-microphone`, `audio-speakers` | devices/ | Hardware devices, not MIME audio files |
| `video-display`, `video-television` | devices/ | Hardware devices, not MIME video files |
| `image-loading`, `image-missing` | status/ | Status indicators, not MIME image files |
| `user-available/away/idle/offline` | status/ | User presence status (freedesktop spec) |
| `input-keyboard-virtual-on/off` | status/ | On-screen keyboard visibility status |
| `printer-error/printing-symbolic` | status/ | Printer state indicators |
| `folder-drag-accept`, `folder-visiting`, `folder-open` | status/ | Freedesktop spec status icons |
| `application-exit`, `application-menu` | actions/ | GUI actions, not MIME types |
| `text-field-*`, `text-convert-*`, etc. | actions/ | GUI/text editing actions, not MIME types |
| `font-disable`, `font-enable`, `font-face`, `font-size-*` | actions/ | Text editing actions, not MIME font files |
| `image-adjust`, `image-auto-adjust` | actions/ | Image editing actions |
| `folder-new`, `folder-sync`, `folder-tag`, etc. | actions/ | Folder-related actions, not places icons |

---

## 7. KCM .desktop Verification

All 82 KCM `.desktop` files and 25 systemsettings category `.desktop` files reference icons that now resolve correctly:

- All `preferences-desktop-*` and `preferences-system-*` icons are in `categories/` (primary search context)
- Other referenced icons (`camera-photo`, `input-keyboard`, `smartphone`, `user-trash`, etc.) are in their correct specialized contexts (devices/, places/, status/)
- All systemsettings category icons resolve from `categories/`

---

## 8. Summary

| Category | Count |
|----------|-------|
| Total icons scanned | 4,934 |
| Icons flagged for context mismatch | 124 (initial broad scan) |
| False positives (intentionally kept) | ~50 |
| **Icons actually fixed** | **70** |
| Icons copied: apps/ → categories/ | 58 |
| Icons copied: status/ → categories/ | 1 |
| Icons copied: actions/ → categories/ | 1 |
| Icons copied: apps/ → categories/ (additional KCM) | 4 |
| Icons copied: → status/ (bluetooth) | 5 |
| Icons copied: apps/ → devices/ | 1 |
| Source packs consulted | 0 (icons already existed in installed theme) |
| Backup available | untracked/windows-modern-v2-backup-20260629-0013/ |

**Verdict:** Theme now has correct context placement. KDE Settings (System Settings) will resolve KCM icons from `categories/` first, finding the correct versions immediately. System tray will find bluetooth and status icons in `status/`.
