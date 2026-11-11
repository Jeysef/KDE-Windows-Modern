"""A disposable window that reports its own size and focus, for live tests."""

import json
import os
import pathlib
import subprocess
import tempfile
import threading
import time

QML_TOOL = next((t for t in ("/usr/lib64/qt6/bin/qml", "/usr/lib/qt6/bin/qml") if pathlib.Path(t).exists()), "qml")

TEST_WINDOW_QML = """
import QtQuick
import QtQuick.Window
Window {
    id: w
    title: "WM-SHORTCUTS-E2E"
    width: 640; height: 400; visible: true
    color: "#2d5f8a"
    Text { anchors.centerIn: parent; text: "Windows Modern shortcut test"; color: "white"; font.pixelSize: 24 }
    function report() { console.warn("WM-STATE " + JSON.stringify({ w: width, h: height, active: active })) }
    onWidthChanged: report()
    onHeightChanged: report()
    onActiveChanged: report()
    Component.onCompleted: report()
}
"""


class TestWindow:
    """A window that prints its size and focus; .state is the latest."""

    def __init__(self):
        path = pathlib.Path(tempfile.mkdtemp()) / "TestWindow.qml"
        path.write_text(TEST_WINDOW_QML)
        self.proc = subprocess.Popen([QML_TOOL, str(path)], stderr=subprocess.PIPE, text=True,
                                     env={**os.environ, "QT_FORCE_STDERR_LOGGING": "1"})
        self.state = {}
        threading.Thread(target=self._read, daemon=True).start()

    def _read(self):
        for line in self.proc.stderr:
            if "WM-STATE " in line:
                self.state = json.loads(line.split("WM-STATE ", 1)[1])

    def wait(self, predicate, timeout=3.0):
        end = time.time() + timeout
        while time.time() < end:
            if self.state and predicate(self.state):
                return True
            time.sleep(0.1)
        return False

    def close(self):
        self.proc.terminate()
        self.proc.wait(timeout=5)




def place(pid, x, y, out_dir):
    """Move (and focus) the window of process pid to x, y with a one-off KWin script."""
    js = pathlib.Path(out_dir) / "wm-place.js"
    js.write_text(f"for (const w of workspace.windowList()) if (w.pid === {pid} && w.normalWindow) "
                  f"{{ w.frameGeometry = {{x: {x}, y: {y}, width: w.frameGeometry.width, "
                  f"height: w.frameGeometry.height}}; workspace.activeWindow = w; }}\n")
    call = ["dbus-send", "--session", "--print-reply", "--type=method_call", "--dest=org.kde.KWin", "/Scripting"]
    sid = subprocess.run([*call, "org.kde.kwin.Scripting.loadScript", f"string:{js}", "string:wm-place"],
                         capture_output=True, text=True).stdout.split()[-1]
    subprocess.run(["dbus-send", "--session", "--type=method_call", "--dest=org.kde.KWin",
                    f"/Scripting/Script{sid}", "org.kde.kwin.Script.run"])
    time.sleep(0.6)
    subprocess.run([*call, "org.kde.kwin.Scripting.unloadScript", "string:wm-place"], capture_output=True)
