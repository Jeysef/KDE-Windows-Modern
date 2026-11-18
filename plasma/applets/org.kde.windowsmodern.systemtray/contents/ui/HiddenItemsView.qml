/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2020 Konrad Materka <materka@gmail.com>
    SPDX-FileCopyrightText: 2020 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras

PlasmaComponents3.ScrollView {
    id: hiddenTasksView

    property alias layout: hiddenTasks

    // Shows up to this many rows; more hidden items scroll.
    readonly property int maximumRows: 3
    readonly property int rows: Math.ceil(hiddenTasks.count / hiddenTasks.columns)
    // Decided from the item count, never from geometry: the view's height
    // follows its content, so a geometry-based scrollbar would change the
    // width, the cell size, the height, and loop.
    readonly property bool scrolls: rows > maximumRows
    // Height of the tiles actually present, so the Quick Settings flyout fits
    // its content instead of padding it with empty space.
    readonly property int contentRowsHeight: Math.min(rows, maximumRows) * hiddenTasks.cellHeight

    hoverEnabled: true
    background: null
    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
    QQC2.ScrollBar.vertical.policy: scrolls ? QQC2.ScrollBar.AlwaysOn : QQC2.ScrollBar.AlwaysOff

    GridView {
        id: hiddenTasks

        readonly property int columns: 3

        // Same gap as the Quick Settings toggles below (ActionPanel.qml).
        readonly property int cellSpacing: Math.round(6 * Plasmoid.configuration.scale / 100)

        // From the full width (not availableWidth, which changes with the
        // scrollbar) so cell size cannot feed back into the view's height.
        // Not floored: flooring loses a pixel per column and leaves the grid's
        // right edge short of the toggles below (pixelAligned rounds anyway).
        cellWidth: (hiddenTasksView.width
                    - (hiddenTasksView.scrolls ? hiddenTasksView.QQC2.ScrollBar.vertical.width : 0)) / columns
        cellHeight: Math.round(cellWidth / 1.4)

        currentIndex: -1
        // The popup gives this grid focus when it opens, which makes the
        // first icon current (upstream, for keyboard users). Windows shows no
        // selection until you use the keyboard: draw the highlight only after
        // a key press in the grid.
        property bool keyboardUsed: false
        highlight: PlasmaExtras.Highlight { visible: hiddenTasks.keyboardUsed }
        highlightMoveDuration: 0

        pixelAligned: true

        readonly property int itemCount: model.count

        model: root.hiddenModel
        delegate: ItemLoader {
            // GridView places each delegate at its cell origin; the spacing is
            // the unused right/bottom strip of the cell.
            width: hiddenTasks.cellWidth - hiddenTasks.cellSpacing
            height: hiddenTasks.cellHeight - hiddenTasks.cellSpacing
            Accessible.role: Accessible.ListItem
        }

        keyNavigationEnabled: true
        activeFocusOnTab: true

        KeyNavigation.up: hiddenTasksView.KeyNavigation.up

        onActiveFocusChanged: {
            if (activeFocus && currentIndex === -1) {
                currentIndex = 0
            } else if (!activeFocus && currentIndex >= 0) {
                currentIndex = -1
            }
            // Hidden again until the next key press (GridView has no
            // focusReason, so a Tab into the grid is not told apart from the
            // popup opening: the first arrow key then shows the highlight).
            hiddenTasks.keyboardUsed = false
        }

        // The first arrow key only reveals the highlight on the current
        // (first) icon instead of moving past it.
        Keys.onPressed: event => {
            const arrow = [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(event.key)
            if (arrow && !hiddenTasks.keyboardUsed) {
                hiddenTasks.keyboardUsed = true
                event.accepted = true
                return
            }
            hiddenTasks.keyboardUsed = true
            event.accepted = false
        }
    }
}
