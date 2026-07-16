# Firefox Window Controls

Replaces Firefox's native CSD window buttons with Windows10Modern-styled SVGs using the background-paint method.

## Install

1. Find your Firefox profile folder:
   - Open Firefox, navigate to `about:support`
   - Look for **Profile Folder** under Application Basics, click **Open Directory**
2. Inside the profile folder, create a `chrome` folder if it doesn't exist.
3. Copy `userChrome.css` from this folder into `<profile>/chrome/userChrome.css`.
4. Enable custom chrome:
   - Go to `about:config`
   - Set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`
5. Fully restart Firefox (`Ctrl+Q` then reopen).

## How it works

Hides Firefox's `.toolbarbutton-icon` and `.toolbarbutton-badge-stack` entirely with `display: none !important`, then paints flat white MDL2 SVGs as `background-image` on the `.titlebar-button` container itself. This bypasses GTK icon theming that resists overwriting `list-style-image`.

## Files

- `userChrome.css` — drop-in stylesheet, copy to profile `chrome/` folder.
