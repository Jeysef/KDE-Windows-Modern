// The shared Search / Task View taskbar button (TaskbarButton.qml):
// activation by mouse and keyboard, its accessible name, and the glyph
// size cap that keeps the icon theme on the monochrome action glyphs.

import QtQuick
import QtTest
import "../../plasma/applets/org.kde.windowsmodern.search/contents/ui"

Item {
    id: root
    width: 200
    height: 200

    TestCase {
        id: testCase
        name: "TaskbarButton"
        when: windowShown

        Component {
            id: buttonComponent
            TaskbarButton {
                width: 48
                height: 48
                iconName: "edit-find"
                fallbackIconName: "system-search-symbolic"
                text: "Search"
                description: "Open Start and search"
            }
        }

        SignalSpy {
            id: triggeredSpy
            signalName: "triggered"
        }

        function makeButton(props) {
            const button = createTemporaryObject(buttonComponent, root, props || {});
            verify(button);
            triggeredSpy.clear();
            triggeredSpy.target = button;
            return button;
        }

        function test_click() {
            const button = makeButton();
            mouseClick(button);
            compare(triggeredSpy.count, 1);
        }

        function test_keys_data() {
            return [
                { tag: "space", key: Qt.Key_Space },
                { tag: "return", key: Qt.Key_Return },
                { tag: "enter", key: Qt.Key_Enter },
            ];
        }
        function test_keys(data) {
            const button = makeButton();
            button.forceActiveFocus();
            keyClick(data.key);
            compare(triggeredSpy.count, 1);
        }

        function test_otherKeyDoesNothing() {
            const button = makeButton();
            button.forceActiveFocus();
            keyClick(Qt.Key_A);
            compare(triggeredSpy.count, 0);
        }

        function test_accessible() {
            const button = makeButton();
            compare(button.Accessible.role, Accessible.Button);
            compare(button.Accessible.name, "Search");
            compare(button.Accessible.description, "Open Start and search");
        }

        // Two thirds of the cell, never more than 30 px: the Windows Modern
        // pack's apps/ (32 px and up) has full-colour icons under the same
        // names as the monochrome glyphs in actions/.
        function test_glyphSize_data() {
            return [
                { tag: "30px panel", cell: 30, expected: 20 },
                { tag: "36px panel", cell: 36, expected: 24 },
                { tag: "48px panel", cell: 48, expected: 30 },
                { tag: "64px panel", cell: 64, expected: 30 },
                { tag: "wide vertical panel", cell: 120, expected: 30 },
            ];
        }
        function test_glyphSize(data) {
            const button = makeButton({ width: data.cell, height: data.cell });
            compare(button.glyphSize, data.expected);
            verify(button.glyphSize < 32);
        }

        // A vertical panel gives a wide, short cell until the layout squares it;
        // the glyph follows the shorter side.
        function test_glyphFollowsShorterSide() {
            const button = makeButton({ width: 120, height: 24 });
            compare(button.glyphSize, 16);
        }

        function test_states() {
            const button = makeButton();
            verify(!button.showHovered);
            verify(!button.showPressed);
            button.forceHovered = true;
            verify(button.showHovered);
            button.forcePressed = true;
            verify(button.showPressed);
        }
    }
}
