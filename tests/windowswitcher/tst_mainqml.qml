// Loads the real main.qml exactly as KWin does (via the TabBoxSwitcher
// object) and checks the popup's view receives KWin's model. This catches
// wiring bugs in main.qml that tests of SwitcherView alone cannot.

import QtQuick
import QtTest

Item {
    id: root
    width: 400
    height: 300

    ListModel {
        id: windowModel
        function activate(i) {}
        function close(i) {}
        ListElement { caption: "One"; icon: ""; windowId: "1920x1080:#336699"; closeable: true; minimized: false }
        ListElement { caption: "Two"; icon: ""; windowId: "1280x800:#993366"; closeable: true; minimized: false }
        ListElement { caption: "Three"; icon: ""; windowId: "900x600:#669933"; closeable: true; minimized: false }
    }

    Loader {
        id: loader
        source: Qt.resolvedUrl("../../plasma/windowswitcher/org.kde.windowsmodern.alttab/contents/ui/main.qml")
    }

    TestCase {
        name: "MainQml"
        when: windowShown

        // Finds the SwitcherView created by main.qml's Instantiator.
        function findView(switcher) {
            for (const child of switcher.data) {
                if (child.objectAt === undefined || child.count === 0) continue;
                const dialog = child.objectAt(0);
                if (dialog && dialog.mainItem) return dialog.mainItem;
            }
            return null;
        }

        function test_viewReceivesKWinModel() {
            tryVerify(() => loader.status === Loader.Ready, 5000, "main.qml should load: " + loader.sourceComponent);
            const switcher = loader.item;
            switcher.model = windowModel;
            switcher.currentIndex = 1;
            switcher.visible = true;          // KWin shows the switcher
            let view = null;
            tryVerify(() => (view = findView(switcher)) !== null, 5000, "the popup should be created");
            compare(view.tabBox, switcher, "view.tabBox must be KWin's switcher object");
            tryCompare(view, "count", 3);
            compare(view.currentIndex, 1);
            compare(view.screenGeometry, switcher.screenGeometry);
            switcher.visible = false;
        }
    }
}
