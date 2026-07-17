# Security Audit — Findings & Remediation

Two independent reviews were run over this repository: a manual pass and a
delegated Codex `reviewer-critic` pass (read-only, no network). Neither found
telemetry, phone-home behaviour, remote code download, or malicious code. What
follows are the hardening findings both passes surfaced.

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
| 5 | Medium | `scripts/update-plm.sh:32` | Updater builds a moving ref without commit/signature check | Open (maintainer-only) |
| 6 | Low | `plasma/shells/org.kde.windowsmodern.lockscreen/contents/lockscreen/MediaControls.qml:38` | Lock screen fetches remote MPRIS art URL | Open |
| 7 | Low | `plasma/shells/org.kde.windowsmodern.lockscreen/contents/lockscreen/config.xml:19` | Media controls default on (info disclosure at lock) | Open |
| 8 | Low | `plasma/applets/org.kde.windowsmodern.systemtray/contents/ui/components/ColorSchemeToggle.qml:20` | Config value concatenated into shell command | Open |
| 9 | Low | `plasma/applets/org.kde.windowsmodern.systemtray/contents/ui/components/BatteryPage.qml:99` | Sleep/lock inhibitor with no time bound | Open |

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
