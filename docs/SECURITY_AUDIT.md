# Security Audit — Findings & Remediation

Two independent reviews were run over this repository: a manual pass and a
delegated Codex `reviewer-critic` pass (read-only, no network). Neither found
telemetry, phone-home behaviour, remote code download, or malicious code. What
follows are the hardening findings both passes surfaced.

Findings 10–11 were surfaced later, by a review of the upstream commits merged
when this branch was rebased onto `7ef6bfe`. They are **introduced by upstream**,
not by this branch, and are not yet fixed here.

**Scope caveat:** the `third_party/plasma-login-manager` submodule source was
*not* audited line-by-line — it is only verified to be pinned to an official KDE
commit (`2b06a296…`, HTTPS origin `invent.kde.org`). The greeter binary is built
from that source, so trust in the login path currently rests on trusting that
pinned upstream commit.

## Status

| # | Severity | File | Issue | Status |
|---|----------|------|-------|--------|
| 3 | High | `scripts/install-greeter.sh` | Greeter built from unverified submodule state | **Fixed** |
| 4 | High | `plasma/look-and-feel/org.kde.windowsmodern.dark/patches/main-cpp.patch` | Greeter loads user-writable QML | **Fixed** |
| 1 | High | `plasma/applets/org.kde.windowsmodern.icontasks/dev.sh:62` | Root command injection via `pkg-config` path | **Fixed** |
| 2 | High | `plasma/applets/org.kde.windowsmodern.systemtray/dev.sh:62`, `.../systemtray/install.sh:179` | Root command injection via interpolated install script | **Fixed** |
| 10 | High | `plasma/applets/org.kde.windowsmodern.icontasks/metadata.json:18`, `.../icontasks/dev.sh:15`, `uninstall.sh:114` | Applet squats the stock KDE plugin ID — root install overwrites, and uninstall deletes, distro-owned files | Open (upstream) |
| 5 | Medium | `scripts/update-plm.sh:32` | Updater builds a moving ref without commit/signature check | Open (maintainer-only) |
| 6 | Low | `plasma/shells/org.kde.windowsmodern.lockscreen/contents/lockscreen/MediaControls.qml:38` | Lock screen fetches remote MPRIS art URL | Open |
| 7 | Low | `plasma/shells/org.kde.windowsmodern.lockscreen/contents/lockscreen/config.xml:19` | Media controls default on (info disclosure at lock) | Open |
| 8 | Low | `plasma/applets/org.kde.windowsmodern.systemtray/contents/ui/components/ColorSchemeToggle.qml:20` | Config value concatenated into shell command | Open |
| 9 | Low | `plasma/applets/org.kde.windowsmodern.systemtray/contents/ui/components/BatteryPage.qml:99` | Sleep/lock inhibitor with no time bound | Open |
| 11 | Low | `plasma/shells/org.kde.windowsmodern.lockscreen/contents/lockscreen/LockScreenUi.qml:154` | Failed unlock attempt is retained in the password field indefinitely | Open (upstream) |

## Fixed in this branch

### 3 — Greeter built from unverified submodule state
`install-greeter.sh` previously checked only that the submodule worktree was
*clean*, not that its `HEAD` matched the commit this repo pins. A clean checkout
of a different (attacker-supplied) ref would be patched, built, and installed as
the system login binary. The script now reads the pinned gitlink via
`git ls-tree HEAD -- third_party/plasma-login-manager` and aborts unless the
submodule `HEAD` matches it.

### 4 — Greeter loads user-writable QML
The greeter patch fell back to loading `Main.qml` from
`~/.local/share/plasma/look-and-feel/…` when the system copy was absent. Loading
QML from a non-root, user-writable path into the process that handles login
credentials is a code-injection channel into the credential path. The patch now
loads only from the root-owned `/usr/share` path, falling back to the built-in
`qrc:` theme — never from `$HOME`.

### 1 & 2 — Root command injection in developer / plugin install scripts
`icontasks/dev.sh`, `systemtray/dev.sh`, and `systemtray/install.sh` previously
piped a heredoc into `pkexec bash -s` (or wrote a temp script run by `pkexec`)
with paths interpolated from `pkg-config`/`kf6-config` output *before* the root
shell parsed them. A malicious or malformed `.pc` file could yield root code
execution.

All three now pass the paths as **positional arguments** into a **quoted**
heredoc (`pkexec bash -s -- "$PLUGIN_DST" … <<'EOF'`, read via `"$1"`/`"$2"`), so
a shell-metacharacter in a hostile value is an inert string, never a command.
Each destructive/privileged path is additionally guarded against an unexpected
prefix (`/usr/*`, or the user's `$HOME` for the uninstall data dir) before
`pkexec` runs. The `dev.sh` scripts remain developer-only and are not part of the
end-user `install.sh` flow.

## Introduced by upstream (rebase onto `7ef6bfe`)

### 10 — Icon Tasks squats the stock KDE plugin ID (High, integrity)
Upstream commit `7ef6bfe` renamed the applet's plugin ID from the vendor-
namespaced `org.kde.windowsmodern.icontasks` to `org.kde.plasma.icontasks` — the
ID of KDE's own Icons-only Task Manager shipped by `plasma-desktop`. This repo's
own layout script previously treated that exact ID as the *stock* fallback
(`// custom Win11 style, or fall back to stock`), and the README still describes
the applet as a fork "rebranded as `org.kde.windowsmodern.icontasks`".

Consequences, all under `pkexec`:

- `dev.sh` copies the built `.so` into `$QT_PLUGIN_DIR/plasma/applets/`, so it
  **overwrites the distro-packaged `org.kde.plasma.icontasks.so`** with an
  unaudited third-party build under the same identity. No `.orig` backup is
  taken (unlike the greeter path, which does keep one).
- `dev.sh` runs `rm -rf "$kpackage_dir"`, which now resolves to the
  distro-owned `/usr/share/plasma/plasmoids/org.kde.plasma.icontasks`.
- `uninstall.sh:114-118` deletes the same distro-owned paths, so **removing the
  theme also removes KDE's stock task manager**, with no way to restore it short
  of a package reinstall.
- Package-manager file verification now fails for `plasma-desktop`, and a distro
  update silently reverts the applet (or vice versa).

The `/usr/*` prefix guard added in finding 1 still holds — it stops a hostile
`pkg-config` value from redirecting the write — but it cannot help here, because
the destination genuinely *is* under `/usr` and is simply the wrong file.

*Fix:* restore the vendor-namespaced ID. If the rename was to make Plasma reuse
stock Icon Tasks configuration, migrate that config in the layout script instead
of taking over the upstream ID. Failing that, guard the privileged `cp`/`rm -rf`
so they refuse any path owned by a distro package, and back up what is replaced.

### 11 — Failed unlock attempt is retained on the lock screen (Low)
Upstream commit `cd6c6d9` dropped `root.clearPassword()` from the 3-second
`graceLockTimer` that fires after a failed unlock. The rejected password now
stays in the field indefinitely. Because the same commit made `loginUiActive`
include `mainPasswordBox.text.length > 0`, a non-empty field also pins the login
panel at full opacity, so the lock screen never returns to its idle clock view
after a failed attempt.

Impact is limited — there is no reveal toggle wired up in the UI, so the text is
not directly readable — but the credential stays resident in the QML property
rather than being cleared per attempt, and the password's length is left on
display to anyone passing the machine.

*Fix:* restore `root.clearPassword()` in the `graceLockTimer` handler.

## Open findings and recommended fixes

Not malicious; not triggered by the normal `install.sh` flow. Listed most
important first.

### 5 — Updater builds a moving ref without verification (Medium, MITM)
`update-plm.sh` fetches and builds a caller-selected branch/tag with no
commit-hash or signature check. It is opt-in and HTTPS to `invent.kde.org`, but a
compromised upstream or a bad ref argument is built unverified.

*Fix:* default to the superproject's pinned gitlink; when moving forward, require
an explicit commit hash (or verify a signed tag) and update the pin in the same
commit.

### 6 — Lock screen fetches remote album art (Low, telemetry)
`MediaControls.qml` binds a QML `Image` straight to the MPRIS `artUrl`. A player
supplying an `http(s)://` URL makes the **lock screen** issue a network request,
disclosing the client IP and lock-screen timing to an arbitrary host.

*Fix:* accept only local schemes, e.g.
`source: /^(file|image):/.test(artUrl) ? artUrl : ""`.

### 7 — Media controls default on (Low)
`config.xml` enables lock-screen media controls by default, exposing current
track/artist/artwork to anyone at the locked machine.

*Fix:* default the key to `false`.

### 8 — Config value concatenated into shell command (Low)
`ColorSchemeToggle.qml` concatenates a color-scheme name from writable plasmoid
config into a command run via the `executable` data engine — same-user command
injection when the toggle is clicked.

*Fix:* validate the value against `/^[A-Za-z0-9._-]+$/`, or invoke
`plasma-apply-colorscheme` without a shell.

### 9 — Unbounded sleep/lock inhibitor (Low)
`BatteryPage.qml`'s toggle blocks sleep *and* screen lock indefinitely, which can
leave an unattended session unlocked.

*Fix:* make it time-bounded or auto-clear on manual lock, with a visible
indicator while active.
