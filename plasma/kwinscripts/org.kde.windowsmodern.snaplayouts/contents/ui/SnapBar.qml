/*
    The layout picker: a row of small layout diagrams in the Plasma theme's
    popup frame, like the bar Windows 11 shows at the top of the screen.
    Colours follow the colour scheme (light and dark).

    The bar is placed so the diagram row sits at a fixed spot (centred,
    rowTop px below the screen's top), whatever padding the theme's frame
    has; cellAt() accounts for that padding.

    SPDX-FileCopyrightText: 2026 Jeysef
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "layouts.js" as Layouts

PlasmaCore.Window {
    id: bar

    property var hovered: null    // { layout, cell } or null
    property var workArea: Qt.rect(0, 0, 1, 1)

    readonly property int diagramWidth: 72
    readonly property int diagramHeight: 44
    readonly property int gap: 10
    readonly property int rowTop: 20
    readonly property int cellGap: 3
    readonly property int rowWidth: Layouts.layouts.length * diagramWidth + (Layouts.layouts.length - 1) * gap

    visible: false
    flags: Qt.X11BypassWindowManagerHint | Qt.FramelessWindowHint | Qt.WindowDoesNotAcceptFocus

    width: rowWidth + leftPadding + rightPadding
    height: diagramHeight + topPadding + bottomPadding

    function showOn(screen, area) {
        workArea = area;
        x = Math.round(screen.x + (screen.width - rowWidth) / 2) - leftPadding;
        y = screen.y + rowTop - topPadding;
        visible = true;
    }

    // The layout cell under a point in screen coordinates, or null.
    function cellAt(px, py) {
        return Layouts.cellAt(px - x - leftPadding, py - y - topPadding, diagramWidth, diagramHeight, gap);
    }

    mainItem: Row {
        Kirigami.Theme.colorSet: Kirigami.Theme.Window
        Kirigami.Theme.inherit: false
        spacing: bar.gap
        Repeater {
            model: Layouts.layouts.length
            Item {
                id: diagram
                required property int index
                width: bar.diagramWidth
                height: bar.diagramHeight
                Repeater {
                    model: Layouts.layouts[diagram.index]
                    Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool isHovered: bar.hovered !== null
                            && bar.hovered.layout === diagram.index && bar.hovered.cell === index
                        x: modelData[0] * bar.diagramWidth + bar.cellGap / 2
                        y: modelData[1] * bar.diagramHeight + bar.cellGap / 2
                        width: modelData[2] * bar.diagramWidth - bar.cellGap
                        height: modelData[3] * bar.diagramHeight - bar.cellGap
                        radius: 3
                        color: isHovered ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.10)
                        border.width: 1
                        border.color: isHovered ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.35)
                    }
                }
            }
        }
    }
}
