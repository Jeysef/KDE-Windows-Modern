#!/usr/bin/env python3
"""End-to-end tests of the lock screen's password entry, without locking.

Runs kscreenlocker's greeter in its testing mode (a window, the session
stays unlocked) against a shell package, types WRONG passwords through a
virtual keyboard and checks that every Enter reaches PAM: PAM answers a
wrong password with "Unlocking failed", read through AT-SPI.

Wrong passwords only, so nothing can unlock; the greeter is closed after
each scenario. Fedora's default PAM stack has no pam_faillock, only a
2 s delay after a failure; check /etc/pam.d before running elsewhere.

  type-first  Type a password and Enter without touching the mouse first.
  retry       Enter a second wrong password right after the first failure.
  pointer-out Type, move the pointer off the lock window, press Enter
              (needs a second monitor; skipped otherwise).

Usage: tests/lockscreen/e2e.py --shell SHELL_ID [SCENARIO ...]
SHELL_ID is a Plasma/Shell package with our lockscreen/ (e.g. a copy of the
installed overlay under ~/.local/share/plasma/shells/ with its own Id).
"""
import argparse
import os
import pathlib
import subprocess
import sys
import time

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1]))

from evdev import ecodes as e  # noqa: E402

from e2e import a11y  # noqa: E402
from e2e.session import Checks  # noqa: E402
from e2e.vinput import VirtualInput  # noqa: E402

GREETER = "/usr/libexec/kscreenlocker_greet"
APP = "kscreenlocker_greet"
FAILED = "Unlocking failed"


class Greeter:
    def __init__(self, shell):
        env = {**os.environ, "LANGUAGE": "en", "LC_MESSAGES": "C.UTF-8"}
        self.proc = subprocess.Popen([GREETER, "--testing", "--shell", shell],
                                     stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True, env=env)
        a11y.application(APP, timeout=15)
        time.sleep(2.5)                 # the launch fade-in

    def failed_shown(self):
        try:
            return any(FAILED in (n.name or "") or FAILED in (n.text() or "") for n in a11y.nodes(APP))
        except Exception:  # noqa: BLE001 — the tree changes while we walk it
            return False

    def wait_failed(self, timeout):
        end = time.time() + timeout
        while time.time() < end:
            if self.failed_shown():
                return True
            time.sleep(0.25)
        return False

    def close(self):
        self.proc.terminate()
        try:
            self.proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            self.proc.kill()


def type_enter(vi, text):
    vi.type_text(text)
    vi.tap(e.KEY_ENTER, after=0.1)


def type_first(vi, g, c):
    """Keys only: the first key wakes the screen and Enter must still count."""
    type_enter(vi, "wrongpass")
    c.check(g.wait_failed(6), "a password typed without touching the mouse reaches PAM")


def retry(vi, g, c):
    vi.move_to(960, 540)
    vi.move_to(980, 560)
    time.sleep(0.6)
    type_enter(vi, "wrongpass")
    c.check(g.wait_failed(6), "first wrong password reaches PAM")
    time.sleep(0.5)                     # retry straight after the failure
    type_enter(vi, "wrongagain")
    # The first message clears 3 s after it appeared; it is still (or again)
    # shown 4 s later only if the second attempt failed in PAM too.
    time.sleep(4.0)
    c.check(g.wait_failed(3), "a retry right after a failure reaches PAM")


def pointer_out(vi, g, c):
    out = subprocess.run(["kscreen-doctor", "-j"], capture_output=True, text=True).stdout
    if out.count('"enabled": true') < 2:
        print("  SKIP  pointer-out needs a second monitor")
        return
    vi.move_to(960, 540)
    time.sleep(0.5)
    vi.type_text("wrongpass")
    vi.move_to(3000, 540)               # onto the other screen
    time.sleep(0.6)
    vi.tap(e.KEY_ENTER)
    c.check(g.wait_failed(6), "Enter after the pointer left the window reaches PAM")


SCENARIOS = {"type-first": type_first, "retry": retry, "pointer-out": pointer_out}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--shell", required=True)
    parser.add_argument("scenarios", nargs="*", metavar="SCENARIO", help=" ".join(SCENARIOS))
    args = parser.parse_args()
    unknown = [s for s in args.scenarios if s not in SCENARIOS]
    if unknown:
        parser.error(f"unknown scenario(s): {', '.join(unknown)}")

    failed = []
    with a11y.enabled():
        time.sleep(2)
        vi = VirtualInput()
        try:
            for name in args.scenarios or list(SCENARIOS):
                print(f"scenario {name} ({args.shell})")
                vi.announce()
                checks = Checks()
                g = Greeter(args.shell)
                try:
                    SCENARIOS[name](vi, g, checks)
                except Exception as ex:  # noqa: BLE001
                    checks.check(False, f"{name} raised {ex!r}")
                finally:
                    g.close()
                if checks.failures:
                    failed.append(name)
        finally:
            vi.close()
    print(f"FAILED: {', '.join(failed)}" if failed else "ALL PASSED")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
