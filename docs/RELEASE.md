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

- `./verify-all.sh` passes.
- All `metadata.json` / `metadata.desktop` share the same `Version`.
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
./scripts/release.sh 1.0.0       # explicit version

# To verify packaging without tagging/pushing:
./scripts/release.sh --dry-run
```

`release.sh` will:
1. Verify a clean `main` and run `verify-all.sh`.
2. Build all artifacts into `dist/` via `package.sh`.
3. Create an annotated tag `v<version>` and push it.
4. Create a GitHub release and upload every `dist/*.zip`.

---

## 3. KDE Store (store.kde.org) — manual publishing

The KDE Store publishes **each component as a separate product**. Build the
ZIPs with `./scripts/package.sh`, then upload each one.

### 3a. Build the artifacts

```bash
./scripts/package.sh
ls dist/
```

### 3b. Upload order (dependencies first)

Publish in this order so that downstream `X-KPackage-Dependencies` can be
wired up later (see step 3c).

| # | Product name (suggested) | Category | ZIP file |
|---|--------------------------|----------|----------|
| 1 | Windows Modern — Color Schemes | Color Schemes | `WindowsModern-color-schemes-*.zip` |
| 2 | Windows Modern — Icons | Icons | `WindowsModern-icons-*.zip` |
| 3 | Windows Modern — Aurorae Dark | Aurorae Themes | `WindowsModern-aurorae-dark-*.zip` |
| 4 | Windows Modern — Aurorae Light | Aurorae Themes | `WindowsModern-aurorae-light-*.zip` |
| 5 | Windows Modern — Plasma Theme Dark | Plasma 6 Themes | `WindowsModern-desktoptheme-dark-*.zip` |
| 6 | Windows Modern — Plasma Theme Light | Plasma 6 Themes | `WindowsModern-desktoptheme-light-*.zip` |
| 7 | Windows Modern — Wallpaper | Wallpapers | `WindowsModern-wallpaper-*.zip` |
| 8 | Windows Modern — Show Desktop applet | Plasma 6 Applets | `WindowsModern-applet-showdesktop-*.zip` |
| 9 | Windows Modern — Start Menu applet | Plasma 6 Applets | `WindowsModern-applet-startmenu-*.zip` |
| 10 | Windows Modern — Icon Tasks applet | Plasma 6 Applets | `WindowsModern-applet-icontasks-*.zip` |
| 11 | Windows Modern — Digital Clock applet | Plasma 6 Applets | `WindowsModern-applet-digitalclock-*.zip` |
| 12 | Windows Modern — Panel Layout | Plasma 6 Layout Templates | `WindowsModern-layout-panel-*.zip` |
| 12 | Windows Modern — Global Theme Dark | Global Themes (Plasma 6) | `WindowsModern-lookfeel-dark-*.zip` |
| 13 | Windows Modern — Global Theme Light | Global Themes (Plasma 6) | `WindowsModern-lookfeel-light-*.zip` |

**[manual]** For each product:
1. Go to <https://store.kde.org/browse> and click **Add Content** (or edit an
   existing product for a new version).
2. Pick the category from the table above.
3. Upload the corresponding ZIP.
4. Add a **screenshot** (use the project `View-*.png` images, or a screenshot
   of the specific component).
5. Fill the description, license (GPL-3.0), and a link to
   `https://github.com/Jeysef/KDE-Windows-Modern`.
6. Note the **product ID** (the number in the product's `api.kde-look.org`
   URL) — you'll need these in step 3c.

### 3c. Wire up Global Theme dependencies **[manual]**

The Global Themes (items 13–14) can auto-install their color scheme, Plasma
theme, Aurorae, and icon dependencies via `X-KPackage-Dependencies`.
These dependency lines were **emptied** for the initial release because the
new KDE Store product IDs were not yet known.

After publishing products 1–6 and 11, collect their product IDs and rebuild the
dependency entries in:

```
plasma/look-and-feel/org.kde.windowsmodern.dark/metadata.json
plasma/look-and-feel/org.kde.windowsmodern.dark/metadata.desktop
plasma/look-and-feel/org.kde.windowsmodern.light/metadata.json
plasma/look-and-feel/org.kde.windowsmodern.light/metadata.desktop
```

Format (one per dependency, example):

**metadata.json:**
```json
"X-KPackage-Dependencies": [
    "kns://colorschemes.knsrc/api.kde-look.org/<NEW_ID>",
    "kns://plasma-themes.knsrc/api.kde-look.org/<NEW_ID>",
    "kns://aurorae.knsrc/api.kde-look.org/<NEW_ID>",
    "kns://icons.knsrc/api.kde-look.org/<NEW_ID>"
]
```

**metadata.desktop:**
```ini
X-KPackage-Dependencies=kns://colorschemes.knsrc/api.kde-look.org/<NEW_ID>,kns://plasma-themes.knsrc/api.kde-look.org/<NEW_ID>,...
```

Then re-package and re-upload the Global Themes (items 13–14) with the updated
dependencies, and bump the version (e.g. `1.0.1`).

### 3d. Components NOT published to the KDE Store

| Component | Reason | Distribution |
|-----------|--------|--------------|
| **Kvantum** (`Kvantum/`) | 3rd-party engine, no KDE Store category. | GitHub release bundle only. |
| **C++ System Tray** (`plasma/applets/org.kde.windowsmodern.systemtray`) | Compiled `.so` plugin, not an installable KPackage. | GitHub release bundle only. See `BUILD.md`. |

Optional future: package the System Tray as distro packages (COPR for Fedora,
AUR for Arch).

---

## 4. Updating a release

For a subsequent release (e.g. `1.1.0`):

1. Bump `Version` in **every** `metadata.json` / `metadata.desktop` (see
   `./scripts/package.sh --list` for the full set).
2. Commit on `main`.
3. `./scripts/release.sh 1.1.0`
4. Re-upload new-version ZIPs to each existing KDE Store product.
