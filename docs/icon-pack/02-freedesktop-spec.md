# Freedesktop Icon Naming Specification

Source: https://specifications.freedesktop.org/icon-naming-spec/latest/

This specification defines a standard naming scheme for icons so that icon themes work across KDE, GNOME, and other desktops without artists having to duplicate icons. A theme that follows this spec can be used by any compliant desktop environment.

## Standard Contexts

Icons belong to one of these 10 contexts, which map to directory names in the theme:

| Context | Dir | Purpose | Typical Sizes | UI Placement |
|---------|-----|---------|---------------|-------------|
| **Actions** | `actions`, `actions@2x` | Menu/dialog interaction icons | 16, 22, 24, 32px | Toolbars, menus, buttons |
| **Animations** | `animations` | Loading spinners, progress animations | 16, 22, 24px | Progress indicators |
| **Applications** | `apps` | App launcher icons | 32, 48, 64, 256px | App menu, task manager, window decoration |
| **Categories** | `categories` | Menu category icons | 16, 22, 24, 32, 48px | Application menu categories |
| **Devices** | `devices` | Hardware icons | 16, 22, 24, 32, 48, 64px | Device notifier, settings |
| **Emblems** | `emblems` | File property overlays | 8, 16, 22, 24px | File manager emblem overlays |
| **Emotes** | `emotes` | Chat emotion icons | 16, 22, 24px | Chat/IRC applications |
| **International** | `intl` | Country flags (ISO 3166 two-letter) | 16, 22, 24, 32px | Region selectors |
| **MIME Types** | `mimetypes` (or `mimes`) | File type icons | 16, 22, 24, 32, 48, 64, 256px | File manager, "Open with" dialogs |
| **Places** | `places` | Folder/location icons | 16, 22, 24, 32, 48, 64, 256px | File manager, save/open dialogs |
| **Status** | `status`, `panel` | System status indicators | 16, 22, 24px (panel), dialog sizes | System tray, notification area, dialogs |

### Important: Panel vs Status

The `panel` directory is a KDE convention — status icons that appear specifically in the system tray panel at small fixed sizes (16/22/24px). The `status` directory covers general status icons including dialog sizes. Some themes merge these, some keep them separate. When both exist, `panel` takes priority for tray usage.

## Naming Rules

1. All names in `en_US.US_ASCII` — lowercase letters, numbers, underscore, dash, period only
2. No spaces, colons, slashes, backslashes
3. Dash `-` separates specificity levels: `input-mouse` → `input-mouse-usb`
4. If a specific icon is missing, fall back to the more generic one
5. **Applications** must either use a generic name from this spec or install an icon matching their executable name

## Complete Standard Icon Catalog

### Actions (menu/dialog interactions)

| Icon Name | Description |
|-----------|-------------|
| `address-book-new` | Create new address book |
| `application-exit` | Exit/quit application |
| `appointment-new` | Create new appointment |
| `call-start` | Initiate/accept call (green handset up) |
| `call-stop` | End call (red handset down) |
| `contact-new` | Create new contact |
| `document-new` | Create new document |
| `document-open` | Open document |
| `document-open-recent` | Open recent document |
| `document-page-setup` | Page setup |
| `document-print` | Print |
| `document-print-preview` | Print preview |
| `document-properties` | Document properties |
| `document-revert` | Revert to previous version |
| `document-save` | Save (arrow down to disk) |
| `document-save-as` | Save as |
| `document-send` | Send (arrow up from disk) |
| `edit-clear` | Clear |
| `edit-copy` | Copy |
| `edit-cut` | Cut |
| `edit-delete` | Delete |
| `edit-find` | Find/search |
| `edit-find-replace` | Find and replace |
| `edit-paste` | Paste |
| `edit-redo` | Redo |
| `edit-select-all` | Select all |
| `edit-undo` | Undo |
| `find-location` | Find physical location |
| `folder-new` | Create new folder |
| `format-indent-less` | Decrease indent |
| `format-indent-more` | Increase indent |
| `format-justify-center` | Center justification |
| `format-justify-fill` | Fill justification |
| `format-justify-left` | Left justification |
| `format-justify-right` | Right justification |
| `format-text-direction-ltr` | Left-to-right text |
| `format-text-direction-rtl` | Right-to-left text |
| `format-text-bold` | Bold |
| `format-text-italic` | Italic |
| `format-text-underline` | Underline |
| `format-text-strikethrough` | Strikethrough |
| `go-bottom` | Go to bottom |
| `go-down` | Go down |
| `go-first` | Go to first |
| `go-home` | Go to home location |
| `go-jump` | Jump to |
| `go-last` | Go to last |
| `go-next` | Go next |
| `go-previous` | Go previous |
| `go-top` | Go to top |
| `go-up` | Go up |
| `help-about` | About dialog |
| `help-contents` | Help contents |
| `help-faq` | FAQ |
| `insert-image` | Insert image |
| `insert-link` | Insert link |
| `insert-object` | Insert object |
| `insert-text` | Insert text |
| `list-add` | Add to list |
| `list-remove` | Remove from list |
| `mail-forward` | Forward mail |
| `mail-mark-important` | Mark as important |
| `mail-mark-junk` | Mark as junk |
| `mail-mark-notjunk` | Mark as not junk |
| `mail-mark-read` | Mark as read |
| `mail-mark-unread` | Mark as unread |
| `mail-message-new` | Compose new mail |
| `mail-reply-all` | Reply to all |
| `mail-reply-sender` | Reply to sender |
| `mail-send` | Send mail |
| `mail-send-receive` | Send and receive |
| `media-eject` | Eject media |
| `media-playback-pause` | Pause |
| `media-playback-start` | Play |
| `media-playback-stop` | Stop |
| `media-record` | Record |
| `media-seek-backward` | Seek backward |
| `media-seek-forward` | Seek forward |
| `media-skip-backward` | Skip backward |
| `media-skip-forward` | Skip forward |
| `object-flip-horizontal` | Flip horizontal |
| `object-flip-vertical` | Flip vertical |
| `object-rotate-left` | Rotate left |
| `object-rotate-right` | Rotate right |
| `process-stop` | Stop (loading processes) |
| `system-lock-screen` | Lock screen |
| `system-log-out` | Log out |
| `system-run` | Run application |
| `system-search` | Search |
| `system-reboot` | Reboot |
| `system-shutdown` | Shutdown |
| `tools-check-spelling` | Check spelling |
| `view-fullscreen` | Fullscreen |
| `view-refresh` | Refresh/reload |
| `view-restore` | Leave fullscreen |
| `view-sort-ascending` | Sort ascending |
| `view-sort-descending` | Sort descending |
| `window-close` | Close window |
| `window-new` | New window |
| `zoom-fit-best` | Best fit zoom |
| `zoom-in` | Zoom in |
| `zoom-original` | Original size |
| `zoom-out` | Zoom out |

### Animations

| Icon Name | Description |
|-----------|-------------|
| `process-working` | Spinner/loading animation |

### Applications (generic app launcher icons)

| Icon Name | Description |
|-----------|-------------|
| `accessories-calculator` | Calculator |
| `accessories-character-map` | Character map |
| `accessories-dictionary` | Dictionary |
| `accessories-screenshot-tool` | Screenshot tool |
| `accessories-text-editor` | Text editor |
| `help-browser` | Help browser |
| `multimedia-volume-control` | Volume control |
| `preferences-desktop-accessibility` | Accessibility preferences |
| `preferences-desktop-font` | Font preferences |
| `preferences-desktop-keyboard` | Keyboard preferences |
| `preferences-desktop-locale` | Locale preferences |
| `preferences-desktop-multimedia` | Multimedia preferences |
| `preferences-desktop-screensaver` | Screensaver preferences |
| `preferences-desktop-theme` | Theme preferences |
| `preferences-desktop-wallpaper` | Wallpaper preferences |
| `system-file-manager` | File manager |
| `system-software-install` | Software installer |
| `system-software-update` | Software updater |
| `utilities-system-monitor` | System monitor |
| `utilities-terminal` | Terminal emulator |

### Categories (menu categories)

| Icon Name | Description |
|-----------|-------------|
| `applications-accessories` | Accessories |
| `applications-development` | Programming |
| `applications-engineering` | Engineering |
| `applications-games` | Games |
| `applications-graphics` | Graphics |
| `applications-internet` | Internet |
| `applications-multimedia` | Multimedia |
| `applications-office` | Office |
| `applications-other` | Other |
| `applications-science` | Science |
| `applications-system` | System tools |
| `applications-utilities` | Utilities |
| `preferences-desktop` | Desktop preferences |
| `preferences-desktop-peripherals` | Peripherals |
| `preferences-desktop-personal` | Personal |
| `preferences-other` | Other preferences |
| `preferences-system` | System preferences |
| `preferences-system-network` | Network preferences |
| `system-help` | Help system |

### Devices (hardware)

| Icon Name | Description |
|-----------|-------------|
| `audio-card` | Audio/sound card |
| `audio-input-microphone` | Microphone |
| `battery` | Battery |
| `camera-photo` | Digital camera |
| `camera-video` | Video camera |
| `camera-web` | Web camera |
| `computer` | Computer (desktop/laptop) |
| `drive-harddisk` | Hard disk |
| `drive-optical` | Optical drive (CD/DVD) |
| `drive-removable-media` | Removable media drive |
| `input-gaming` | Game controller |
| `input-keyboard` | Keyboard |
| `input-mouse` | Mouse |
| `input-tablet` | Graphics tablet |
| `media-flash` | Flash media (SD, memory stick) |
| `media-floppy` | Floppy disk |
| `media-optical` | Optical media (CD/DVD) |
| `media-tape` | Tape media |
| `modem` | Modem |
| `multimedia-player` | Media player device |
| `network-wired` | Wired network |
| `network-wireless` | Wireless network |
| `pda` | PDA device |
| `phone` | Phone device |
| `printer` | Printer |
| `scanner` | Scanner |
| `video-display` | Monitor/display |

### Emblems (file overlays)

| Icon Name | Description |
|-----------|-------------|
| `emblem-default` | Default selection |
| `emblem-documents` | Documents directory |
| `emblem-downloads` | Downloads directory |
| `emblem-favorite` | Favorite/bookmarked |
| `emblem-important` | Important/priority |
| `emblem-mail` | Mail directory |
| `emblem-photos` | Photos directory |
| `emblem-readonly` | Read-only |
| `emblem-shared` | Shared |
| `emblem-symbolic-link` | Symbolic link |
| `emblem-synchronized` | Synchronized/syncing |
| `emblem-system` | System files |
| `emblem-unreadable` | Inaccessible |

### Emotes (chat emotions)

| Icon Name | Emoticon |
|-----------|----------|
| `face-angel` | `0:-)` |
| `face-angry` | `X-(` |
| `face-cool` | `B-)` |
| `face-crying` | `:'(` |
| `face-devilish` | `>:-)` |
| `face-embarrassed` | `:-[` |
| `face-kiss` | `:-*` |
| `face-laugh` | `:-))` |
| `face-monkey` | `:-(|)` |
| `face-plain` | `:-|` |
| `face-raspberry` | `:-P` |
| `face-sad` | `:-(` |
| `face-sick` | `:-&` |
| `face-smile` | `:-)` |
| `face-smile-big` | `:-D` |
| `face-smirk` | `:-!` |
| `face-surprise` | `:-0` |
| `face-tired` | `|-)` |
| `face-uncertain` | `:-/` |
| `face-wink` | `;-)` |
| `face-worried` | `:-S` |

### MIME Types (file types)

| Icon Name | Description |
|-----------|-------------|
| `application-x-executable` | Executable binary |
| `audio-x-generic` | Generic audio file |
| `font-x-generic` | Generic font file |
| `image-x-generic` | Generic image file |
| `package-x-generic` | Generic package/archive |
| `text-html` | HTML file |
| `text-x-generic` | Generic text file |
| `text-x-generic-template` | Text template |
| `text-x-script` | Script file |
| `video-x-generic` | Generic video file |
| `x-office-address-book` | Address book file |
| `x-office-calendar` | Calendar file |
| `x-office-document` | Document file |
| `x-office-presentation` | Presentation file |
| `x-office-spreadsheet` | Spreadsheet file |

### Places (folders & locations)

| Icon Name | Description |
|-----------|-------------|
| `folder` | Standard folder |
| `folder-remote` | Remote folder |
| `network-server` | Network server/host |
| `network-workgroup` | Network workgroup |
| `start-here` | Main menu |
| `user-bookmarks` | Bookmarks |
| `user-desktop` | Desktop directory |
| `user-home` | Home directory |
| `user-trash` | Trash/recycle bin |

### Status (system status indicators)

| Icon Name | Description |
|-----------|-------------|
| `appointment-missed` | Missed appointment |
| `appointment-soon` | Upcoming appointment |
| `audio-volume-high` | High volume |
| `audio-volume-low` | Low volume |
| `audio-volume-medium` | Medium volume |
| `audio-volume-muted` | Muted volume |
| `battery-caution` | Battery below 40% |
| `battery-low` | Battery below 20% |
| `dialog-error` | Error dialog |
| `dialog-information` | Info dialog |
| `dialog-password` | Password/auth dialog |
| `dialog-question` | Question dialog |
| `dialog-warning` | Warning dialog |
| `folder-drag-accept` | Folder accepting drag |
| `folder-open` | Open folder |
| `folder-visiting` | Folder (spatial mode) |
| `image-loading` | Image loading/thumbnail |
| `image-missing` | Missing/broken image |
| `mail-attachment` | Mail with attachment |
| `mail-unread` | Unread mail |
| `mail-read` | Read mail |
| `mail-replied` | Replied mail |
| `mail-signed` | Signed mail |
| `mail-signed-verified` | Verified signed mail |
| `media-playlist-repeat` | Repeat mode |
| `media-playlist-shuffle` | Shuffle mode |
| `network-error` | Network error |
| `network-idle` | Network idle |
| `network-offline` | Network offline/disconnected |
| `network-receive` | Receiving data |
| `network-transmit` | Transmitting data |
| `network-transmit-receive` | Transmitting and receiving |
| `printer-error` | Printer error |
| `printer-printing` | Printer active |
| `security-high` | High security (strong encryption, valid cert) |
| `security-medium` | Medium security (strong encryption, unverified cert) |
| `security-low` | Low security (weak encryption, untrusted cert) |
| `software-update-available` | Update available |
| `software-update-urgent` | Urgent update available |
| `sync-error` | Sync error |
| `sync-synchronizing` | Sync in progress |
| `task-due` | Task due soon |
| `task-past-due` | Overdue task |
| `user-available` | User available (chat) |
| `user-away` | User away |
| `user-idle` | User idle |
| `user-offline` | User offline |
| `user-trash-full` | Trash with items |
| `weather-clear` | Clear skies |
| `weather-clear-night` | Clear night |
| `weather-few-clouds` | Partly cloudy |
| `weather-few-clouds-night` | Partly cloudy night |
| `weather-fog` | Foggy |
| `weather-overcast` | Overcast |
| `weather-severe-alert` | Severe weather alert |
| `weather-showers` | Rain showers |
| `weather-showers-scattered` | Scattered showers |
| `weather-snow` | Snow |
| `weather-storm` | Storm |

## Extended Icons (not in spec but widely expected)

Many desktops and apps expect icons beyond the spec. These come from KDE, GNOME, and third-party conventions:

### Extended Status (panel/tray)
- `network-wireless-signal-*` (excellent/good/ok/weak/none)
- `network-wireless-connected`
- `network-wireless-acquiring`
- `network-wireless-encrypted`
- `network-wireless-hotspot`
- `network-cellular-*` (signal strengths)
- `bluetooth-active`, `bluetooth-connected`, `bluetooth-disabled`
- `audio-volume-*` variants (more granular levels)
- `battery-*` (full, good, caution, low, empty, charging variants)
- `preferences-system-time`
- `night-light` / `redshift-status-on`

### Extended Places
- `folder-documents`, `folder-download`, `folder-music`
- `folder-pictures`, `folder-videos`, `folder-templates`
- `folder-publicshare`, `folder-{color}`, `folder-{name}`
- `user-trash-full`

### Extended Apps (typical KDE/GNOME apps)
- `firefox`, `chromium`, `thunderbird`
- `gimp`, `inkscape`, `krita`
- `vlc`, `audacious`, `rhythmbox`
- `dolphin`, `nautilus`
- `steam`, `discord`, `telegram`
- And hundreds more via reverse-DNS or executable names

### Extended MIME Types
- `application-pdf`, `application-zip`, `application-json`
- `application-vnd.oasis.opendocument.*` (ODF suite)
- `application-vnd.ms-*` (Office formats)
- `audio-mpeg`, `audio-flac`, `audio-ogg`
- `image-jpeg`, `image-png`, `image-svg+xml`
- `video-mp4`, `video-x-matroska`, `video-webm`
- Hundreds more format-specific types

## How This Relates to Our Icon Groups

Our `03-icon-groups.md` organizes these into **sprite groups** — clusters of semantically related icons that should share visual style. E.g., all `audio-volume-*` variants form one group and should come from the same source pack.
