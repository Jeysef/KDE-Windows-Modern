// Automated tests for the Alt+Tab SwitcherView (layout + keyboard).
// Run: tests/windowswitcher/run-tests.sh   (uses a mock org.kde.kwin)

import QtQuick
import QtTest
import "../../plasma/windowswitcher/org.kde.windowsmodern.alttab/contents/ui"

Item {
    id: root
    width: 1920
    height: 1080

    ListModel {
        id: windowModel
        property int activated: -1
        property int closed: -1
        function activate(i) { activated = i; }
        function close(i) { closed = i; }
    }

    QtObject {
        id: tabBox
        property var model: windowModel
        property int currentIndex: 0
    }

    SwitcherView {
        id: view
        tabBox: tabBox
        screenGeometry: Qt.rect(0, 0, 1920, 1080)
        focus: true
    }

    TestCase {
        name: "SwitcherView"
        when: windowShown

        // "<w>x<h>:<color>" sizes; 12 windows wrap into two rows at 1920 px.
        readonly property var sizes: ["1920x1080", "1280x800", "900x600", "1600x1000", "360x560", "1100x780",
                                      "1400x900", "1000x1000", "1920x1200", "1300x760", "800x1100", "1280x720"]

        function fill(n) {
            windowModel.clear();
            for (let i = 0; i < n; ++i) {
                windowModel.append({ caption: "Window " + i, icon: "", windowId: sizes[i % sizes.length] + ":#336699",
                                     closeable: true, minimized: false });
            }
            tabBox.currentIndex = 0;
            view.forceActiveFocus();
            tryVerify(() => view.count === n && (n === 0 || view.rows.length > 0));
            wait(50); // let the deferred relayout run
        }

        function card(i) {
            // Ask the Repeater: the Flickable's children can still hold
            // delegates of a cleared model until deferred deletion runs.
            const flick = view.children.find(c => c.contentItem !== undefined);
            const repeater = flick.contentItem.children.find(c => c.itemAt !== undefined);
            return repeater.itemAt(i);
        }

        function test_previewWidthFollowsAspectRatio() {
            fill(3);
            const wide = card(0);     // 16:9
            const narrow = card(2);   // 3:2
            verify(wide.width > narrow.width, "16:9 card should be wider than 3:2 card");
            compare(wide.height, narrow.height, "all cards share one height");
        }

        function test_rowsWrapAndAreCentered() {
            fill(12);
            verify(view.rows.length >= 2, "12 windows should wrap");
            for (const row of view.rows) {
                const first = card(row[0]);
                const last = card(row[row.length - 1]);
                const left = first.x;
                const right = view.contentWidth - (last.x + last.width);
                verify(Math.abs(left - right) <= 1, "row should be centered: " + left + " vs " + right);
            }
        }

        function test_leftRightWrap() {
            fill(5);
            keyClick(Qt.Key_Right);
            compare(tabBox.currentIndex, 1);
            tabBox.currentIndex = 0;
            keyClick(Qt.Key_Left);
            compare(tabBox.currentIndex, 4, "Left from the first window wraps to the last");
        }

        function test_upDownMovesBetweenRows() {
            fill(12);
            const firstRowLength = view.rows[0].length;
            tabBox.currentIndex = 0;
            keyClick(Qt.Key_Down);
            verify(view.rowOfIndex[tabBox.currentIndex] === 1, "Down moves to the second row");
            keyClick(Qt.Key_Down);
            verify(view.rowOfIndex[tabBox.currentIndex] === 0, "Down from the last row wraps to the first");
            keyClick(Qt.Key_Up);
            verify(tabBox.currentIndex >= firstRowLength, "Up from the first row wraps to the last");
        }

        function test_clickActivates() {
            fill(3);
            windowModel.activated = -1;
            const c = card(1);
            mouseClick(c, c.width / 2, c.height - 10);
            compare(windowModel.activated, 1);
        }

        // Finds a card's close button (the Rectangle carrying the close MouseArea).
        function closeButtonOf(c) {
            function walk(item) {
                for (const child of item.children) {
                    if (child.radius !== undefined && child.width > 0 && child.width === child.height
                            && child.children.length === 2 && child.children[1].hoverEnabled !== undefined) {
                        return child;
                    }
                    const found = walk(child);
                    if (found) return found;
                }
                return null;
            }
            return walk(c);
        }

        // Scenario: with the switcher open, hover the close button of a card
        // that is NOT selected and click it. The button must stay visible
        // while the pointer is on it, and the click must close that window.
        function test_closeButtonOnUnselectedCard() {
            fill(4);
            tabBox.currentIndex = 0;
            windowModel.closed = -1;
            const c = card(2);
            mouseMove(c, c.width / 2, c.height / 2);        // hover the card
            const button = closeButtonOf(c);
            verify(button !== null, "card should have a close button");
            tryVerify(() => button.visible, 1000, "hovering the card shows its close button");
            const p = button.mapToItem(c, button.width / 2, button.height / 2);
            let flips = 0;
            const countFlip = () => { flips++; };
            button.visibleChanged.connect(countFlip);
            mouseMove(c, p.x, p.y);                          // onto the X
            wait(100);
            button.visibleChanged.disconnect(countFlip);
            compare(flips, 0, "close button must not flicker while the pointer is on it");
            verify(button.visible, "close button must stay visible while hovered");
            mouseClick(c, p.x, p.y);
            compare(windowModel.closed, 2, "clicking the X closes that window");
        }

        // Scenario: close one window, then close another one by its X.
        function test_closeTwoWindowsInARow() {
            fill(4);
            tabBox.currentIndex = 0;
            windowModel.closed = -1;
            const first = card(1);
            mouseMove(first, first.width / 2, first.height / 2);
            let button = closeButtonOf(first);
            tryVerify(() => button.visible, 1000);
            let p = button.mapToItem(first, button.width / 2, button.height / 2);
            mouseMove(first, p.x, p.y);
            mouseClick(first, p.x, p.y);
            compare(windowModel.closed, 1);
            windowModel.remove(1);                           // KWin removes the closed window
            wait(50);
            const second = card(2);                           // was index 3
            mouseMove(second, second.width / 2, second.height / 2);
            button = closeButtonOf(second);
            tryVerify(() => button.visible, 1000, "the next card's close button appears on hover");
            p = button.mapToItem(second, button.width / 2, button.height / 2);
            mouseMove(second, p.x, p.y);
            wait(100);
            verify(button.visible, "and stays visible while hovered");
            mouseClick(second, p.x, p.y);
            compare(windowModel.closed, 2);
        }

        function test_emptyModel() {
            fill(0);
            compare(view.rows.length, 0);
            verify(view.width > 0 && view.height > 0, "placeholder keeps a visible size");
        }
    }
}
