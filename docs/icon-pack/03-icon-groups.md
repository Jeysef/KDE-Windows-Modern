# Icon Groups — Sprite Comparison Units

See `00-architecture.md` for the overall pipeline, including deduplication, fallback separation, local copies, and sprite formats.

## Two Sprite Formats

### Format A: Group Sprites (this document)
For **semantically related icons** that must come from the same pack (e.g., battery states: low, caution, full, charging — they must visually match). Each row shows all icons from one pack. The AI picks the best row (best pack for this group).
**Layout:** Grid, 1 row per pack, icons side-by-side within the row.

### Format B: Per-Icon Horizontal Sprites (see `03b-individual-icons.md`, TBD)
For **standalone icons** with no semantic group (e.g., branded apps, one-off mimetypes). Each column shows the same icon from a different pack. The AI picks per icon, not per group.
**Layout:** Single horizontal strip, 1 column per pack.

## Group Definition

Each group below is a **sprite comparison unit** for Format A. The AI evaluates these sprites with context: group name, UI context, expected pixel size, and whether dark/light variants are needed.

## Group Categories

Groups are organized by their UI placement and visual role. Icons in the same category share similar size, context, and visual weight.

---

## STATUS: Panel & Tray Icons (16-24px)

These appear in the system tray, panel, and notification area. Small, highly recognizable, need to work at 16-24px.

### G-status-audio — Audio Volume States
**Size:** 16-24px | **Context:** panel/status | **Count:** ~6-12 per pack
```
audio-volume-muted
audio-volume-low
audio-volume-medium
audio-volume-high
```
Plus extended variants: `audio-volume-low-zero-panel`, `audio-volume-muted-blocking-panel`, etc.

### G-status-battery — Battery States
**Size:** 16-24px | **Context:** panel/status | **Count:** ~8-15 per pack
```
battery
battery-low
battery-caution
battery-full
battery-empty
battery-charging
battery-full-charging
battery-good-charging
battery-low-charging
battery-empty-charging
```
Plus `battery-0*` numeric variants in some packs.

### G-status-network-wireless — WiFi Signal States
**Size:** 16-24px | **Context:** panel/status | **Count:** ~6-20 per pack
```
network-wireless
network-wireless-connected
network-wireless-acquiring
network-wireless-signal-excellent
network-wireless-signal-good
network-wireless-signal-ok
network-wireless-signal-weak
network-wireless-signal-none
network-wireless-encrypted
network-wireless-hotspot
network-wireless-offline
```

### G-status-network-wired — Wired Network States
**Size:** 16-24px | **Context:** panel/status | **Count:** ~3-8 per pack
```
network-wired
network-wired-connected
network-wired-disconnected
network-wired-acquiring
network-wired-unavailable
network-wired-no-route
```

### G-status-network-activity — Data Transfer Indicators
**Size:** 16-24px | **Context:** status | **Count:** ~6 per pack
```
network-idle
network-receive
network-transmit
network-transmit-receive
network-error
network-offline
```

### G-status-bluetooth — Bluetooth States
**Size:** 16-24px | **Context:** panel/status | **Count:** ~4-10 per pack
```
bluetooth-active
bluetooth-connected
bluetooth-disabled
bluetooth-paired (varies)
```
Note: Bluetooth is not in the freedesktop spec but expected by KDE.

### G-status-cellular — Mobile Data States
**Size:** 16-24px | **Context:** panel/status | **Count:** ~4-10 per pack
```
network-cellular-signal-excellent
network-cellular-signal-good
network-cellular-signal-ok
network-cellular-signal-weak
network-cellular-signal-none
```
Note: Not in the freedesktop spec but expected by KDE.

### G-status-dialogs — Dialog Notification Icons
**Size:** 16-48px | **Context:** status | **Count:** ~5 per pack
```
dialog-error
dialog-information
dialog-warning
dialog-question
dialog-password
```

### G-status-security — Connection Security States
**Size:** 16-48px | **Context:** status | **Count:** ~3 per pack
```
security-high
security-medium
security-low
```

### G-status-software — Update States
**Size:** 16-48px | **Context:** status | **Count:** ~2 per pack
```
software-update-available
software-update-urgent
```

### G-status-sync — Synchronization States
**Size:** 16-48px | **Context:** status | **Count:** ~2 per pack
```
sync-error
sync-synchronizing
```

### G-status-user — Chat Presence States
**Size:** 16-22px | **Context:** status | **Count:** ~4 per pack
```
user-available
user-away
user-idle
user-offline
```

### G-status-weather — Weather Conditions
**Size:** 22-64px | **Context:** status | **Count:** ~14 per pack
```
weather-clear
weather-clear-night
weather-few-clouds
weather-few-clouds-night
weather-fog
weather-overcast
weather-severe-alert
weather-showers
weather-showers-scattered
weather-snow
weather-storm
```
Plus variants with `-large` suffix in some packs.

### G-status-mail — Mail Status Indicators
**Size:** 16-22px | **Context:** status | **Count:** ~6 per pack
```
mail-unread
mail-read
mail-replied
mail-attachment
mail-signed
mail-signed-verified
```

### G-status-media — Media Playlist States
**Size:** 16-22px | **Context:** status | **Count:** ~2 per pack
```
media-playlist-repeat
media-playlist-shuffle
```

### G-status-printer — Printer States
**Size:** 16-48px | **Context:** status | **Count:** ~2 per pack
```
printer-error
printer-printing
```

### G-status-task — Task/Appointment States
**Size:** 16-22px | **Context:** status | **Count:** ~4 per pack
```
appointment-missed
appointment-soon
task-due
task-past-due
```

### G-status-misc — Miscellaneous Status
**Size:** 16-48px | **Context:** status | **Count:** ~4 per pack
```
image-loading
image-missing
folder-drag-accept
folder-visiting
```

---

## ACTIONS: Toolbar & Menu Icons (16-32px)

These appear in toolbars, menus, and buttons. Typically 16-22px for toolbars, 24-32px for larger buttons.

### G-actions-navigation — Directional Navigation
**Size:** 16-32px | **Context:** actions | **Count:** ~10 per pack
```
go-next
go-previous
go-up
go-down
go-first
go-last
go-top
go-bottom
go-home
go-jump
```

### G-actions-media — Media Playback Controls
**Size:** 16-32px | **Context:** actions | **Count:** ~8 per pack
```
media-playback-start
media-playback-pause
media-playback-stop
media-skip-backward
media-skip-forward
media-seek-backward
media-seek-forward
media-record
media-eject
```

### G-actions-document — Document Operations
**Size:** 16-32px | **Context:** actions | **Count:** ~10 per pack
```
document-new
document-open
document-open-recent
document-save
document-save-as
document-print
document-print-preview
document-properties
document-revert
document-send
document-page-setup
```

### G-actions-edit — Editing Operations
**Size:** 16-32px | **Context:** actions | **Count:** ~8 per pack
```
edit-cut
edit-copy
edit-paste
edit-delete
edit-undo
edit-redo
edit-find
edit-find-replace
edit-select-all
edit-clear
```

### G-actions-format-text — Text Formatting
**Size:** 16-22px | **Context:** actions | **Count:** ~4 per pack
```
format-text-bold
format-text-italic
format-text-underline
format-text-strikethrough
```

### G-actions-format-justify — Text Justification
**Size:** 16-22px | **Context:** actions | **Count:** ~4 per pack
```
format-justify-left
format-justify-right
format-justify-center
format-justify-fill
```

### G-actions-format-layout — Layout Controls
**Size:** 16-22px | **Context:** actions | **Count:** ~4 per pack
```
format-indent-less
format-indent-more
format-text-direction-ltr
format-text-direction-rtl
```

### G-actions-insert — Insertion Operations
**Size:** 16-22px | **Context:** actions | **Count:** ~4 per pack
```
insert-image
insert-link
insert-object
insert-text
```

### G-actions-list — List Operations
**Size:** 16-22px | **Context:** actions | **Count:** ~2 per pack
```
list-add
list-remove
```

### G-actions-mail — Mail Operations
**Size:** 16-22px | **Context:** actions | **Count:** ~10 per pack
```
mail-forward
mail-mark-important
mail-mark-junk
mail-mark-notjunk
mail-mark-read
mail-mark-unread
mail-message-new
mail-reply-all
mail-reply-sender
mail-send
mail-send-receive
```

### G-actions-view — View Controls
**Size:** 16-22px | **Context:** actions | **Count:** ~5 per pack
```
view-fullscreen
view-refresh
view-restore
view-sort-ascending
view-sort-descending
```

### G-actions-window — Window Operations
**Size:** 16-22px | **Context:** actions | **Count:** ~2 per pack
```
window-close
window-new
```

### G-actions-zoom — Zoom Controls
**Size:** 16-22px | **Context:** actions | **Count:** ~4 per pack
```
zoom-in
zoom-out
zoom-original
zoom-fit-best
```

### G-actions-object — Object Transforms
**Size:** 16-22px | **Context:** actions | **Count:** ~4 per pack
```
object-flip-horizontal
object-flip-vertical
object-rotate-left
object-rotate-right
```

### G-actions-system — System Actions
**Size:** 16-48px | **Context:** actions | **Count:** ~6 per pack
```
system-lock-screen
system-log-out
system-run
system-search
system-reboot
system-shutdown
```

### G-actions-misc — Miscellaneous Actions
**Size:** 16-22px | **Context:** actions | **Count:** ~10 per pack
```
address-book-new
application-exit
appointment-new
call-start
call-stop
contact-new
folder-new
help-about
help-contents
help-faq
process-stop
tools-check-spelling
find-location
```

---

## DEVICES: Hardware Icons (16-64px)

These appear in device notifiers, settings, and file manager sidebars.

### G-devices-audio — Audio Hardware
**Size:** 16-64px | **Context:** devices | **Count:** ~3 per pack
```
audio-card
audio-input-microphone
```
Plus extended: `audio-headphones`, `audio-headset`, `audio-speakers` (varies by pack).

### G-devices-camera — Camera Devices
**Size:** 16-64px | **Context:** devices | **Count:** ~3 per pack
```
camera-photo
camera-video
camera-web
```

### G-devices-storage — Storage Devices
**Size:** 16-64px | **Context:** devices | **Count:** ~3 per pack
```
drive-harddisk
drive-optical
drive-removable-media
```

### G-devices-input — Input Devices
**Size:** 16-64px | **Context:** devices | **Count:** ~4 per pack
```
input-gaming
input-keyboard
input-mouse
input-tablet
```

### G-devices-media — Removable Media
**Size:** 16-64px | **Context:** devices | **Count:** ~4 per pack
```
media-flash
media-floppy
media-optical
media-tape
```

### G-devices-network — Network Devices
**Size:** 16-64px | **Context:** devices | **Count:** ~3 per pack
```
modem
network-wired
network-wireless
```

### G-devices-peripheral — Peripheral Devices
**Size:** 16-64px | **Context:** devices | **Count:** ~6 per pack
```
computer
battery
multimedia-player
pda
phone
printer
scanner
video-display
```

---

## PLACES: Folder & Location Icons (16-256px)

These appear in file managers, save/open dialogs, and the places sidebar.

### G-places-core — Core Folder Icons
**Size:** 16-256px | **Context:** places | **Count:** ~5 per pack
```
folder
folder-open
folder-remote
folder-drag-accept (status)
folder-visiting (status)
```

### G-places-user — User Directories
**Size:** 16-256px | **Context:** places | **Count:** ~5 per pack
```
user-home
user-desktop
user-trash
user-trash-full (status)
user-bookmarks
start-here
```

### G-places-folders — Special Folders
**Size:** 16-256px | **Context:** places | **Count:** ~8-15 per pack
```
folder-documents
folder-download
folder-music
folder-pictures
folder-videos
folder-templates
folder-publicshare
```
Plus color variants (`folder-blue`, `folder-green`, etc.) and application-specific folders (`folder-html`, `folder-vm`, etc.) in extended themes.

### G-places-network — Network Locations
**Size:** 16-256px | **Context:** places | **Count:** ~2 per pack
```
network-server
network-workgroup
```

---

## APPS: Application Launcher Icons (32-256px)

These appear in the application menu, task manager, and window decorations.

### G-apps-generic — Standard Desktop Apps
**Size:** 32-256px | **Context:** apps | **Count:** ~16 per pack
```
accessories-calculator
accessories-character-map
accessories-dictionary
accessories-screenshot-tool
accessories-text-editor
help-browser
multimedia-volume-control
preferences-desktop-accessibility
preferences-desktop-font
preferences-desktop-keyboard
preferences-desktop-locale
preferences-desktop-multimedia
preferences-desktop-screensaver
preferences-desktop-theme
preferences-desktop-wallpaper
```

### G-apps-system — System Utility Apps
**Size:** 32-256px | **Context:** apps | **Count:** ~5 per pack
```
system-file-manager
system-software-install
system-software-update
utilities-system-monitor
utilities-terminal
```

### G-apps-branded — Branded/Third-Party Apps
**Size:** 32-256px | **Context:** apps | **Count:** varies wildly (100-1000+ per pack)

This is a massive category. Not every pack has icons for the same apps. Strategy:
- Check which branded app icons `Eleven` has
- For those, compare against other packs that also have them
- For branded apps missing from Eleven, fall back through the pack order
- Ultimately, many branded app icons will come from the app itself (installed to `/usr/share/icons/hicolor/`)

**Key branded apps to check across packs:**
Firefox, Chromium, Thunderbird, GIMP, Inkscape, Krita, VLC, Audacious, Rhythmbox, Dolphin, Nautilus, Kate, Konsole, Gwenview, Okular, Ark, Steam, Discord, Telegram, Signal, Slack, VS Code, IntelliJ, LibreOffice (writer, calc, impress, draw, base, math), Wine apps (1E64_notepad.0, etc.)

---

## CATEGORIES: Menu Category Icons (16-64px)

These appear in the application menu as section headers.

### G-categories-apps — Application Categories
**Size:** 16-64px | **Context:** categories (sometimes apps) | **Count:** ~12 per pack
```
applications-accessories
applications-development
applications-engineering
applications-games
applications-graphics
applications-internet
applications-multimedia
applications-office
applications-other
applications-science
applications-system
applications-utilities
```

### G-categories-prefs — Preferences Categories
**Size:** 16-64px | **Context:** categories | **Count:** ~7 per pack
```
preferences-desktop
preferences-desktop-peripherals
preferences-desktop-personal
preferences-other
preferences-system
preferences-system-network
system-help
```

---

## MIME TYPES: File Type Icons (16-256px)

These appear in file managers. The freedesktop spec defines only ~15 standard types, but real themes have hundreds.

### G-mimes-standard — Spec-Standard MIME Types
**Size:** 16-256px | **Context:** mimetypes (or `mimes`) | **Count:** ~15 per pack
```
application-x-executable
audio-x-generic
font-x-generic
image-x-generic
package-x-generic
text-html
text-x-generic
text-x-generic-template
text-x-script
video-x-generic
x-office-address-book
x-office-calendar
x-office-document
x-office-presentation
x-office-spreadsheet
```

### G-mimes-archives — Archive/Compressed Types
**Size:** 16-256px | **Context:** mimetypes | **Count:** ~8-20 per pack
```
application-zip
application-x-archive
application-x-tar
application-x-bzip
application-x-compressed-tar
application-x-gzip
application-x-rar
application-x-7z-compressed
application-x-xz
```
Plus `.deb`, `.rpm`, etc.

### G-mimes-audio — Audio File Types
**Size:** 16-256px | **Context:** mimetypes | **Count:** ~8-15 per pack
```
audio-x-generic
audio-mpeg
audio-flac
audio-ogg
audio-x-wav
audio-aac
audio-x-ms-wma
audio-opus
audio-x-m4a
audio-x-matroska
```

### G-mimes-video — Video File Types
**Size:** 16-256px | **Context:** mimetypes | **Count:** ~8-15 per pack
```
video-x-generic
video-mp4
video-x-matroska
video-x-msvideo
video-x-ms-wmv
video-webm
video-x-flv
video-quicktime
video-x-ogm
```

### G-mimes-image — Image File Types
**Size:** 16-256px | **Context:** mimetypes | **Count:** ~10-20 per pack
```
image-x-generic
image-jpeg
image-png
image-gif
image-svg+xml
image-bmp
image-webp
image-tiff
image-x-xcf
image-x-psd
image-heif
```

### G-mimes-text — Text/Document Types
**Size:** 16-256px | **Context:** mimetypes | **Count:** ~10-20 per pack
```
text-x-generic
text-plain
text-x-log
text-x-readme
text-x-changelog
text-csv
text-markdown
text-xml
text-yaml
text-x-source
application-json
application-pdf
application-rtf
```

### G-mimes-office — Office Document Types
**Size:** 16-256px | **Context:** mimetypes | **Count:** ~10-30 per pack
```
x-office-document
x-office-spreadsheet
x-office-presentation
x-office-drawing
application-vnd.oasis.opendocument.text
application-vnd.oasis.opendocument.spreadsheet
application-vnd.oasis.opendocument.presentation
application-vnd.oasis.opendocument.graphics
application-msword
application-vnd.ms-excel
application-vnd.ms-powerpoint
application-vnd.openxmlformats-officedocument.*
```

### G-mimes-code — Code/Developer Types
**Size:** 16-256px | **Context:** mimetypes | **Count:** ~10-20 per pack
```
text-x-script
text-x-python
text-x-java
text-x-csrc
text-x-chdr
text-x-c++src
application-x-desktop
application-x-shellscript
application-xml
application-x-php
```

### G-mimes-font — Font Types
**Size:** 16-256px | **Context:** mimetypes | **Count:** ~4-8 per pack
```
font-x-generic
font-otf
font-ttf
font-woff
```

### G-mimes-disk — Disk Image Types
**Size:** 16-256px | **Context:** mimetypes | **Count:** ~3-8 per pack
```
application-x-cd-image
application-x-raw-disk-image
application-x-iso
application-x-apple-diskimage
```

---

## EMBLEMS: File Overlay Badges (8-24px)

Small overlays that appear on top of file/folder icons.

### G-emblems-states — File State Emblems
**Size:** 8-24px | **Context:** emblems | **Count:** ~10 per pack
```
emblem-default
emblem-favorite
emblem-important
emblem-readonly
emblem-shared
emblem-symbolic-link
emblem-synchronized
emblem-system
emblem-unreadable
emblem-locked
```

### G-emblems-dirs — Directory Marker Emblems
**Size:** 8-24px | **Context:** emblems | **Count:** ~4 per pack
```
emblem-documents
emblem-downloads
emblem-mail
emblem-photos
```

---

## EMOTES: Chat Emoticons (16-24px)

Appear in chat applications.

### G-emotes-faces — Emotion Faces
**Size:** 16-24px | **Context:** emotes | **Count:** ~21 per pack
```
face-angel
face-angry
face-cool
face-crying
face-devilish
face-embarrassed
face-kiss
face-laugh
face-monkey
face-plain
face-raspberry
face-sad
face-sick
face-smile
face-smile-big
face-smirk
face-surprise
face-tired
face-uncertain
face-wink
face-worried
```

---

## ANIMATIONS: Loading Spinners (16-24px)

### G-animations-process — Process Working
**Size:** 16-24px | **Context:** animations | **Count:** ~1 per pack
```
process-working (spritesheet)
```

---

## Group Summary Table

| Group ID | Category | UI Placement | Priority | Typical Count | Sensitive to Style Consistency |
|----------|----------|-------------|----------|---------------|-------------------------------|
| G-status-audio | Status | Tray panel | HIGH | 6-12 | Yes — must match other tray icons |
| G-status-battery | Status | Tray panel | HIGH | 8-15 | Yes |
| G-status-network-wireless | Status | Tray panel | HIGH | 6-20 | Yes |
| G-status-network-wired | Status | Tray panel | MEDIUM | 3-8 | Yes |
| G-status-network-activity | Status | Tooltips/status | MEDIUM | 6 | Yes |
| G-status-bluetooth | Status | Tray panel | HIGH | 4-10 | Yes |
| G-status-cellular | Status | Tray panel | MEDIUM | 4-10 | Yes |
| G-status-dialogs | Status | Dialogs | HIGH | 5 | Medium |
| G-status-security | Status | Dialogs | LOW | 3 | Low |
| G-status-software | Status | Tray | MEDIUM | 2 | Yes |
| G-status-sync | Status | Tray | LOW | 2 | Yes |
| G-status-user | Status | Chat | LOW | 4 | Low |
| G-status-weather | Status | Widget | LOW | 14 | Medium |
| G-status-mail | Status | Tray | LOW | 6 | Yes |
| G-status-media | Status | Tray | LOW | 2 | Yes |
| G-status-printer | Status | Tray | LOW | 2 | Yes |
| G-status-task | Status | Tray | LOW | 4 | Yes |
| G-status-misc | Status | Misc | LOW | 4 | Low |
| G-actions-navigation | Actions | Toolbars | HIGH | 10 | Yes — must match toolbar style |
| G-actions-media | Actions | Toolbars | HIGH | 8 | Yes |
| G-actions-document | Actions | Toolbars/menus | HIGH | 10 | Yes |
| G-actions-edit | Actions | Toolbars/menus | HIGH | 8 | Yes |
| G-actions-format-text | Actions | Toolbars | MEDIUM | 4 | Yes |
| G-actions-format-justify | Actions | Toolbars | MEDIUM | 4 | Yes |
| G-actions-format-layout | Actions | Toolbars | LOW | 4 | Yes |
| G-actions-insert | Actions | Toolbars | LOW | 4 | Yes |
| G-actions-list | Actions | Toolbars | LOW | 2 | Yes |
| G-actions-mail | Actions | Toolbars | LOW | 10 | Yes |
| G-actions-view | Actions | Menus | MEDIUM | 5 | Yes |
| G-actions-window | Actions | Menus | MEDIUM | 2 | Yes |
| G-actions-zoom | Actions | Toolbars | MEDIUM | 4 | Yes |
| G-actions-object | Actions | Toolbars | LOW | 4 | Yes |
| G-actions-system | Actions | Menus/panel | HIGH | 6 | Medium |
| G-actions-misc | Actions | Menus/toolbars | MEDIUM | 10 | Yes |
| G-devices-audio | Devices | Settings | MEDIUM | 3 | Medium |
| G-devices-camera | Devices | Settings | LOW | 3 | Medium |
| G-devices-storage | Devices | File mgr | MEDIUM | 3 | Medium |
| G-devices-input | Devices | Settings | LOW | 4 | Medium |
| G-devices-media | Devices | File mgr | LOW | 4 | Medium |
| G-devices-network | Devices | Settings | LOW | 3 | Medium |
| G-devices-peripheral | Devices | Settings/file mgr | MEDIUM | 8 | Medium |
| G-places-core | Places | File mgr | HIGH | 5 | Yes — must match folder style |
| G-places-user | Places | File mgr/sidebar | HIGH | 5 | Yes |
| G-places-folders | Places | File mgr/sidebar | MEDIUM | 8-15 | Yes |
| G-places-network | Places | File mgr/sidebar | LOW | 2 | Yes |
| G-apps-generic | Apps | App menu | MEDIUM | 16 | Medium |
| G-apps-system | Apps | App menu | MEDIUM | 5 | Medium |
| G-apps-branded | Apps | App menu | LOW | varies | Low |
| G-categories-apps | Categories | App menu | MEDIUM | 12 | Medium |
| G-categories-prefs | Categories | Settings | LOW | 7 | Medium |
| G-mimes-standard | MIME Types | File mgr | HIGH | 15 | Medium |
| G-mimes-archives | MIME Types | File mgr | MEDIUM | 8-20 | Medium |
| G-mimes-audio | MIME Types | File mgr | LOW | 8-15 | Medium |
| G-mimes-video | MIME Types | File mgr | LOW | 8-15 | Medium |
| G-mimes-image | MIME Types | File mgr | LOW | 10-20 | Medium |
| G-mimes-text | MIME Types | File mgr | MEDIUM | 10-20 | Medium |
| G-mimes-office | MIME Types | File mgr | MEDIUM | 10-30 | Medium |
| G-mimes-code | MIME Types | File mgr | LOW | 10-20 | Medium |
| G-mimes-font | MIME Types | File mgr | LOW | 4-8 | Medium |
| G-mimes-disk | MIME Types | File mgr | LOW | 3-8 | Medium |
| G-emblems-states | Emblems | File mgr | LOW | 10 | Low |
| G-emblems-dirs | Emblems | File mgr | LOW | 4 | Low |
| G-emotes-faces | Emotes | Chat | LOW | 21 | Low |

## Group Overlap Note

Some icon names appear in multiple contexts within a pack:
- `network-wireless` is in BOTH `devices/` and `status/` or `panel/` — different sizes
- `folder-open` is in BOTH `places/` and `status/`
- Action icons exist at multiple pixel sizes (16px toolbar, 22px main toolbar, 24px, 32px)

When evaluating, we compare the same context+size across packs. The group definition above accounts for this — each group is scoped to a specific context and size range.
