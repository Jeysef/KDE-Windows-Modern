// The shared Search / Task View taskbar button (TaskbarButton.qml) and the
// Search applet's search box (SearchBox.qml): activation by mouse and
// keyboard, accessible names, the glyph size (Icon Tasks' rule), the hover
// tile and the search box's geometry.

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
                glyph: "<rect width='24' height='24' fill='currentColor'/>"
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

        // Icon Tasks' rule: the cell minus the frame's borders, rounded down
        // to a standard icon size; 32 px on a 48 px taskbar, like app icons.
        function test_glyphSize_data() {
            return [
                { tag: "30px panel", cell: 30, expected: 22 },
                { tag: "36px panel", cell: 36, expected: 32 },
                { tag: "48px panel", cell: 48, expected: 32 },
                { tag: "64px panel", cell: 64, expected: 48 },
            ];
        }
        function test_glyphSize(data) {
            const button = makeButton({ width: data.cell, height: data.cell });
            compare(button.glyphSize, data.expected);
        }

        // The hover tile is tasks.svg's hover frame: inset by its 2 px
        // borders at every cell size, square, centred.
        function test_tile_data() {
            return [
                { tag: "36px", cell: 36, size: 32 },
                { tag: "48px", cell: 48, size: 44 },
                { tag: "64px", cell: 64, size: 60 },
            ];
        }
        function test_tile(data) {
            const button = makeButton({ width: data.cell, height: data.cell });
            compare(button.tileInset, 2);
            compare(button.tileSize, data.size);
        }

        // A vertical panel gives a wide, short cell until the layout squares it;
        // the glyph follows the shorter side.
        function test_glyphFollowsShorterSide() {
            const button = makeButton({ width: 120, height: 30 });
            compare(button.glyphSize, 22);
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

        Component {
            id: boxComponent
            SearchBox {
                height: 48
                width: preferredWidth
                glyph: "<rect width='24' height='24' fill='currentColor'/>"
                text: "Search"
                placeholder: "Search"
                description: "Open Start and search"
            }
        }

        function makeBox(props) {
            const box = createTemporaryObject(boxComponent, root, props || {});
            verify(box);
            triggeredSpy.clear();
            triggeredSpy.target = box;
            return box;
        }

        // 220 x 32 in a 48 px taskbar, fully rounded, scaled with the panel.
        function test_boxGeometry_data() {
            return [
                { tag: "48px panel", thickness: 48, boxHeight: 32, boxWidth: 220, margin: 4 },
                { tag: "36px panel", thickness: 36, boxHeight: 24, boxWidth: 165, margin: 3 },
                { tag: "64px panel", thickness: 64, boxHeight: 43, boxWidth: 296, margin: 5 },
            ];
        }
        function test_boxGeometry(data) {
            const box = makeBox({ height: data.thickness });
            compare(box.boxHeight, data.boxHeight);
            compare(box.boxWidth, data.boxWidth);
            compare(box.sideMargin, data.margin);
            compare(box.preferredWidth, data.boxWidth + 2 * data.margin);
        }

        function test_boxClick() {
            const box = makeBox();
            mouseClick(box);
            compare(triggeredSpy.count, 1);
        }

        function test_boxKeys_data() {
            return [
                { tag: "space", key: Qt.Key_Space },
                { tag: "return", key: Qt.Key_Return },
            ];
        }
        function test_boxKeys(data) {
            const box = makeBox();
            box.forceActiveFocus();
            keyClick(data.key);
            compare(triggeredSpy.count, 1);
        }

        function test_boxAccessible() {
            const box = makeBox();
            compare(box.Accessible.role, Accessible.Button);
            compare(box.Accessible.name, "Search");
            compare(box.Accessible.description, "Open Start and search");
        }
    }
}
