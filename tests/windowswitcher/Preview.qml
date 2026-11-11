// Renders the Alt+Tab SwitcherView with mock windows and saves a PNG.
// Run via tests/windowswitcher/preview.sh.
import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import "../../plasma/windowswitcher/org.kde.windowsmodern.alttab/contents/ui"

Window {
    id: win
    width: 1920
    height: 1080
    visible: true
    color: light ? "#dfe7ef" : "#1b2633"

    readonly property var args: Qt.application.arguments
    readonly property bool light: args.indexOf("light") >= 0
    readonly property int windows: {
        for (const a of args) { if (/^[0-9]+$/.test(a)) return parseInt(a); }
        return 7;
    }
    readonly property string output: {
        for (const a of args) { if (a.endsWith(".png")) return a; }
        return "alttab-preview.png";
    }

    Item {
        anchors.fill: parent
        Kirigami.Theme.inherit: false
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.textColor: win.light ? "#1a1a1a" : "#ffffff"
        Kirigami.Theme.backgroundColor: win.light ? "#f3f3f3" : "#202020"

        ListModel {
            id: windowModel
            function activate(i) { console.warn("activate", i) }
            function close(i) { console.warn("close", i) }
        }

        Component.onCompleted: {
            const samples = [
                ["Firefox — Windows Modern for KDE Plasma 6", "firefox", "1920x1080:#d9541e"],
                ["Dolphin — Downloads", "system-file-manager", "1280x800:#2d7dd2"],
                ["Konsole", "utilities-terminal", "900x600:#333333"],
                ["Visual Studio Code — main.qml", "code", "1600x1000:#3c6ea8"],
                ["Calculator", "accessories-calculator", "360x560:#6a6a6a"],
                ["System Settings — Window Management", "preferences-system", "1100x780:#4a8c5c"],
                ["Spotify", "spotify", "1400x900:#1db954"],
                ["Kate — CHANGELOG.md", "kate", "1000x1000:#8e44ad"],
                ["GIMP", "gimp", "1920x1200:#7a6b5a"],
                ["Discord", "discord", "1300x760:#5865f2"],
                ["Okular — manual.pdf", "okular", "800x1100:#b03a2e"],
                ["Steam", "steam", "1280x720:#1b2838"],
            ];
            for (let i = 0; i < Math.min(win.windows, samples.length); ++i) {
                windowModel.append({ caption: samples[i][0], icon: samples[i][1], windowId: samples[i][2],
                                     closeable: true, minimized: false });
            }
        }

        QtObject {
            id: tabBox
            property var model: windowModel
            property int currentIndex: Math.min(2, Math.max(0, win.windows - 1))
        }

        // Stand-in for the desktop theme's dialog background.
        Rectangle {
            anchors.centerIn: view
            width: view.width
            height: view.height
            radius: 8
            color: Kirigami.Theme.backgroundColor
            opacity: 0.94
            border.color: win.light ? "#20000000" : "#30ffffff"
        }

        SwitcherView {
            id: view
            anchors.centerIn: parent
            tabBox: tabBox
            screenGeometry: Qt.rect(0, 0, win.width, win.height)
        }
    }

    Timer {
        interval: 600
        running: true
        onTriggered: win.contentItem.grabToImage(result => {
            result.saveToFile(win.output);
            console.warn("saved", win.output);
            Qt.quit();
        })
    }
}
