# Release Guide

This document describes how to publish a release of Windows Modern for KDE
Plasma 6 to **GitHub** and the **KDE Store** (store.kde.org).

The automated parts are handled by three scripts:

| Script | Purpose |
|--------|---------|
| `scripts/package.sh` | Builds per-component ZIPs (for KDE Store) and a full bundle (for GitHub) into `dist/`. |
| `scripts/release.sh` | Runs health checks, tags, pushes, and creates the GitHub release with artifacts attached. |
| `scripts/capture-screenshots.sh` | Guided capture of README screenshots (dark/light, start menu, system tray, windows). |

Everything below marked **[manual]** must be done by a human.

---

## 1. Pre-release checklist

Before tagging, confirm:

- `./verify-all.sh` passes (it is also enforced by `release.sh`).
- All `metadata.json` / `metadata.desktop` share the same `Version`
  (`package.sh` refuses to build if any component disagrees).
- `Website` / `BugReportUrl` point at `https://github.com/Jeysef/KDE-Windows-Modern`.
- Screenshots are up to date (run `./scripts/capture-screenshots.sh` if not).
- Working tree is clean on `main`.

These were set up for the initial release; keep them consistent on future ones.

---

## 2. GitHub release

### 2a. One-time setup

```bash
# Authenticate gh CLI (if not already done)
gh auth login

# Create the repo and push main
gh repo create Jeysef/KDE-Windows-Modern --public --source=. --remote=origin --push
```

### 2b. Publish a release

```bash
# Commit all changes first, then:
./scripts/release.sh             # auto-detects version from metadata
# or
./scripts/release.sh 1.0.0       # explicit version (must match the metadata)

# To verify packaging without tagging/pushing:
./scripts/release.sh --dry-run
```

`release.sh` will:
1. Verify a clean `main` and run `verify-all.sh`.
2. Build all artifacts into `dist/` via `package.sh`. The full bundle is made
   with `git archive`, so it contains exactly the committed tree (minus the
   `export-ignore` paths in `.gitattributes`). Stale zips from earlier runs are
   pruned, and every component version is checked against the release version.
3. Create an annotated tag `v<version>` and push it.
4. Create a GitHub release and upload exactly the artifacts listed in
   `dist/.manifest` (the ones built in step 2).

---

## 3. KDE Store (store.kde.org)

The store has no upload API and sits behind an anti-bot check, so
`scripts/store/store-publish.py` drives a real Firefox with its own profile
(`~/.local/share/windows-modern/store-firefox`, nothing shared with your
browser). The products, their categories and texts live in
`scripts/store/products.json` and `scripts/store/descriptions/`.

### 3a. Publish a new version

```bash
./scripts/package.sh                          # zips into dist/
scripts/store/store-publish.py launch         # sign in once if asked (lasts ~a month)
scripts/store/store-publish.py update all --changelog notes.md
scripts/store/store-publish.py status         # every product: version and its one file
scripts/store/store-publish.py close
```

`update` uploads each product's zip for this version, labels it, archives
the previous zip (the store keeps its download count), sets the version and
description, and adds a "Version X" changelog entry. It verifies each step
and stops with an error otherwise; rerunning it is safe.

### 3b. Products

| Product | Category (what Discover queries) | Store id |
|---------|----------------------------------|----------|
| Color schemes | KDE Color Scheme KDE4 (112) | `products.json` |
| Icons | KDE Icon Theme (132) | |
| Window decoration dark / light | Window Decoration Aurorae (114) | |
| Plasma style dark / light | Plasma Theme (104) | |
| Clock | Plasma 6 Clocks (708) | |
| Show desktop | Plasma 6 Applets (706; the store rejects the parent 705) | |
| Alt-Tab (the store rejects "+" in titles) | Kwin Switching Layouts Plasma 6 (721) | |
| Start menu | Plasma 6 Menus (709) | |
| Global theme dark / light | Global Themes (Plasma 6) (722) | |

Not published: the **wallpaper** (its photos are under the Pexels License,
which forbids redistribution on wallpaper platforms), **Kvantum** (no store
category Discover installs from), and the **C++ System Tray and Icon
Tasks** (compiled plugins; GitHub releases carry them prebuilt for Fedora).

A new product: add it to `products.json` and `descriptions/`, then
`store-publish.py create NAME --images DIR` (logo first, then up to five
gallery pictures). Take pictures with `scripts/store/capture.py DIR`: it
uses a temporary virtual desktop with neutral windows, so nothing personal
is shown, and switches to light and back for the light shots.

### 3c. Global theme dependencies

The global themes list the store items above in `X-KPackage-Dependencies`
(plus the Win10OS cursors, store item 1383064), so a store install brings
the whole look. `scripts/store/set-dependencies.py` writes them from
`products.json`. One failing dependency aborts the theme install, so before
a release test it in a throwaway home:

```bash
HOME=$(mktemp -d) kpackagetool6 -t Plasma/LookAndFeel -i dist/WindowsModern-lookfeel-dark-*.zip
```

## 4. Updating a release

For a subsequent release (e.g. `1.1.0`):

1. Bump `Version` in **every** `metadata.json` / `metadata.desktop` (see
   `./scripts/package.sh --list` for the full set).
2. Commit on `main`.
3. `./scripts/release.sh 1.1.0`
4. Update the KDE Store: `scripts/store/store-publish.py update all`
   (section 3a).
