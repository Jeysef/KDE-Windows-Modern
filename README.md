## Windows-modern KDE Theme

Windows-modern kde is a light clean theme for KDE Plasma desktop.

In this repository you'll find:

- Aurorae Themes
- Kvantum Themes
- Plasma Color Schemes
- Plasma Desktop Themes
- Plasma Look-and-Feel Settings
- Icon pack
- Custom Plasma applets (Start Menu, Show Desktop, System Tray)

> **Note:** The System Tray applet is a compiled C++ Plasma Containment.
> Install it with `./install.sh systray` so it is built and deployed correctly.

## Installation

```sh
./install.sh
```

## Development

### Committing icon pack changes

The `icons/windows-modern/` pack contains thousands of SVGs. To keep `git status`
fast, those files are marked with `--skip-worktree` and `icons/**` is treated as
binary in `.gitattributes`. This hides icon changes from normal `git status` and
`git diff` output.

When you want to commit icon changes, use the helper script instead of staging
manually:

```sh
COMMIT_MSG="feat(icons): describe your change" ./scripts/commit-icons.sh
```

The script will:

1. Temporarily re-enable git tracking for all `icons/windows-modern/` files.
2. Stage the current icon pack.
3. Commit with the provided message (or prompt for one).
4. Re-apply `--skip-worktree` so day-to-day git operations stay fast.

## License

GNU GPL v3

## view
![view](View-1.png?raw=true)
![view](View-2.png?raw=true)
![view](View-3.png?raw=true)
![view](View-4.png?raw=true)


