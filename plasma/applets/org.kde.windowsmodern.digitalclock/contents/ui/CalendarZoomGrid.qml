/*
    SPDX-FileCopyrightText: 2026 Jeysef

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// The calendar's zoomed-out levels: a 4x4 grid of months (year view) or of
// years (decade view). Tiles follow the day cells: the current month/year
// is an accent circle, hover and press are rounded rectangles, and the
// neighbouring months/years are dimmed like the days of other months.
Item {
    id: zoomGrid

    // One entry per tile: { text, caption, isCurrent, isDimmed }; the
    // optional caption (the year above January) is drawn small above text.
    property var tiles: []

    signal picked(int index)

    readonly property int columns: 4
    readonly property real spacing: Kirigami.Units.smallSpacing / 2
    readonly property real cellWidth: (width - (columns - 1) * spacing) / columns
    readonly property real cellHeight: (height - (columns - 1) * spacing) / columns

    function crossfade() {
        grid.opacity = 0;
        fadeIn.restart();
    }

    Win11Palette { id: palette }

    Grid {
        id: grid
        anchors.fill: parent
        columns: zoomGrid.columns
        spacing: zoomGrid.spacing

        Repeater {
            model: zoomGrid.tiles

            delegate: MouseArea {
                id: tile

                required property var modelData
                required property int index

                width: zoomGrid.cellWidth
                height: zoomGrid.cellHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                Accessible.role: Accessible.Button
                Accessible.name: modelData.caption ? modelData.text + " " + modelData.caption : modelData.text
                Accessible.onPressAction: zoomGrid.picked(index)

                onClicked: zoomGrid.picked(index)

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 2 * Kirigami.Units.smallSpacing
                    height: width
                    radius: width / 2       // a circle in every state, like the day cells
                    color: {
                        if (tile.modelData.isCurrent) {
                            return palette.accent;
                        } else if (tile.containsPress) {
                            return palette.pressed;
                        } else if (tile.containsMouse) {
                            return palette.hover;
                        }
                        return "transparent";
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Kirigami.Units.shortDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                scale: containsPress ? 0.96 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: Kirigami.Units.shortDuration
                        easing.type: Easing.InOutQuad
                    }
                }

                readonly property color textColor: {
                    if (modelData.isCurrent) {
                        return palette.accentText;
                    } else if (modelData.isDimmed) {
                        return palette.textDisabled;
                    }
                    return palette.text;
                }

                PlasmaComponents.Label {
                    id: tileText
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: tile.modelData.text
                    color: tile.textColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                }

                PlasmaComponents.Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: tileText.top
                    visible: text.length > 0
                    textFormat: Text.PlainText
                    text: tile.modelData.caption || ""
                    color: tile.textColor
                    // Relative to the tile text: smallFont is not always smaller.
                    font.pixelSize: Math.round(tileText.font.pixelSize * 0.8)
                }
            }
        }
    }

    NumberAnimation {
        id: fadeIn
        target: grid
        property: "opacity"
        to: 1
        duration: Kirigami.Units.shortDuration
        easing.type: Easing.InOutQuad
    }
}
