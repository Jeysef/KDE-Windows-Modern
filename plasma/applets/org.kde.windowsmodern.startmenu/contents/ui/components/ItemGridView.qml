/*
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later

    Phase 1 port — no folders, no launch tracking.
*/

import QtQuick

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

FocusScope {
    id: itemGrid

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown

    signal itemActivated(int index, string actionId, string argument)

    property bool dragEnabled: true
    property bool dropEnabled: false
    property bool showLabels: true
    property bool labels2lines: false
    property int itemColumns

    property alias currentIndex: gridView.currentIndex
    property alias currentItem: gridView.currentItem
    property alias contentItem: gridView.contentItem
    property alias count: gridView.count
    property alias model: gridView.model

    property alias cellWidth: gridView.cellWidth
    property alias cellHeight: gridView.cellHeight
    property int iconSize

    property alias contentY: gridView.contentY
    property alias contentHeight: gridView.contentHeight

    property var horizontalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff
    property var verticalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff
    property bool bypassArrowNav: false

    onDropEnabledChanged: {
        if (!dropEnabled && "dropPlaceHolderIndex" in model) {
            model.dropPlaceHolderIndex = -1;
        }
    }

    onFocusChanged: {
        if (!focus) {
            currentIndex = -1;
        }
    }

    function currentRow() {
        if (currentIndex === -1) return -1;
        return Math.floor(currentIndex / Math.floor(width / itemGrid.cellWidth));
    }

    function currentCol() {
        if (currentIndex === -1) return -1;
        return currentIndex - (currentRow() * Math.floor(width / itemGrid.cellWidth));
    }

    function lastRow() {
        var columns = Math.floor(width / itemGrid.cellWidth);
        return Math.ceil(count / columns) - 1;
    }

    function tryActivate(row, col) {
        if (count) {
            var columns = Math.floor(width / itemGrid.cellWidth);
            var rows = Math.ceil(count / columns);
            row = Math.min(row, rows - 1);
            col = Math.min(col, columns - 1);
            currentIndex = Math.min(row ? ((Math.max(1, row) * columns) + col) : col, count - 1);
            focus = true;
        }
    }

    function forceLayout() {
        gridView.forceLayout();
    }

    function positionAtIndex(idx) {
        gridView.positionViewAtIndex(idx, GridView.Beginning);
    }

    ActionMenu {
        id: actionMenu
        onActionClicked: {
            visualParent.actionTriggered(actionId, actionArgument);
        }
    }

    Component {
        id: aItemGridDelegate2
        ItemGridDelegateColumns {
            showLabel: showLabels
            labels2lines: itemGrid.labels2lines
            itemColumns: itemGrid.itemColumns
            iconSize: itemGrid.iconSize
        }
    }
    Component {
        id: aItemGridDelegate
        ItemGridDelegate {
            showLabel: itemGrid.showLabels
            labels2lines: itemGrid.labels2lines
            itemColumns: itemGrid.itemColumns
            iconSize: itemGrid.iconSize
        }
    }

    PlasmaComponents.ScrollView {
        id: scrollArea

        width: itemGrid.width
        height: itemGrid.height
        focus: true

        PlasmaComponents.ScrollBar.horizontal.policy: itemGrid.horizontalScrollBarPolicy
        PlasmaComponents.ScrollBar.vertical.policy: itemGrid.verticalScrollBarPolicy

        GridView {
            id: gridView

            width: itemGrid.width
            height: itemGrid.height

            signal itemContainsMouseChanged(bool containsMouse)

            property int iconSize: Kirigami.Units.iconSizes.huge
            property bool animating: false
            property int animationDuration: itemGrid.dropEnabled ? resetAnimationDurationTimer.interval : 0

            focus: true
            currentIndex: -1

            move: Transition {
                enabled: itemGrid.dropEnabled
                SequentialAnimation {
                    PropertyAction { target: gridView; property: "animating"; value: true }
                    NumberAnimation { duration: gridView.animationDuration; properties: "x, y"; easing.type: Easing.OutQuad }
                    PropertyAction { target: gridView; property: "animating"; value: false }
                }
            }

            moveDisplaced: Transition {
                enabled: itemGrid.dropEnabled
                SequentialAnimation {
                    PropertyAction { target: gridView; property: "animating"; value: true }
                    NumberAnimation { duration: gridView.animationDuration; properties: "x, y"; easing.type: Easing.OutQuad }
                    PropertyAction { target: gridView; property: "animating"; value: false }
                }
            }

            keyNavigationWraps: false
            boundsBehavior: Flickable.StopAtBounds

            delegate: itemColumns == 1 ? aItemGridDelegate : aItemGridDelegate2
            highlight: Rectangle {
                color: Kirigami.Theme.hoverColor
                radius: Kirigami.Units.smallSpacing
            }

            highlightFollowsCurrentItem: true
            highlightMoveDuration: 0

            onCurrentIndexChanged: {
                if (currentIndex !== -1) {
                    hoverArea.hoverEnabled = false
                    focus = true;
                }
            }

            onCountChanged: {
                animationDuration = 0;
                resetAnimationDurationTimer.start();
            }

            onModelChanged: {
                currentIndex = -1;
            }

            Keys.onLeftPressed: event => {
                if (itemGrid.currentCol() !== 0) {
                    event.accepted = true;
                    moveCurrentIndexLeft();
                } else {
                    itemGrid.keyNavLeft();
                }
            }

            Keys.onRightPressed: event => {
                var columns = Math.floor(width / cellWidth);
                if (itemGrid.currentCol() !== columns - 1 && currentIndex !== count - 1) {
                    event.accepted = true;
                    moveCurrentIndexRight();
                } else {
                    itemGrid.keyNavRight();
                }
            }

            Keys.onUpPressed: event => {
                if (bypassArrowNav) {
                    keyNavUp()
                    event.accepted = true
                } else if (currentRow() !== 0) {
                    moveCurrentIndexUp()
                    event.accepted = true
                } else {
                    keyNavUp()
                }
            }

            Keys.onDownPressed: event => {
                if (bypassArrowNav) {
                    keyNavDown()
                    event.accepted = true
                } else if (currentRow() < lastRow()) {
                    var columns = Math.floor(width / cellWidth)
                    var newIndex = currentIndex + columns
                    currentIndex = Math.min(newIndex, count - 1)
                    positionViewAtIndex(currentIndex, GridView.Contain)
                    event.accepted = true
                } else {
                    keyNavDown()
                }
            }

            onItemContainsMouseChanged: containsMouse => {
                if (!containsMouse) {
                    if (!actionMenu.opened) {
                        gridView.currentIndex = -1;
                    }
                    hoverArea.pressX = -1;
                    hoverArea.pressY = -1;
                    hoverArea.lastX = -1;
                    hoverArea.lastY = -1;
                    hoverArea.pressedItem = null;
                    hoverArea.hoverEnabled = true;
                }
            }
        }
    }

    Timer {
        id: resetAnimationDurationTimer
        interval: 120
        repeat: false
        onTriggered: {
            gridView.animationDuration = interval - 20;
        }
    }

    MouseArea {
        id: hoverArea
        cursorShape: gridView.currentIndex !== -1 ? Qt.PointingHandCursor : Qt.ArrowCursor

        width: itemGrid.width - Kirigami.Units.gridUnit
        height: itemGrid.height

        property int pressX: -1
        property int pressY: -1
        property int lastX: -1
        property int lastY: -1
        property Item pressedItem: null

        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        function updatePositionProperties(x, y) {
            if (lastX === x && lastY === y) return;
            lastX = x;
            lastY = y;
            var cPos = mapToItem(gridView.contentItem, x, y);
            var item = gridView.itemAt(cPos.x, cPos.y);
            if (!item) {
                gridView.currentIndex = -1;
                pressedItem = null;
            } else {
                itemGrid.focus = (item.itemIndex !== -1)
                itemGrid.forceActiveFocus()
                gridView.currentIndex = item.itemIndex;
            }
            return item;
        }

        onPressed: mouse => {
            mouse.accepted = true;
            updatePositionProperties(mouse.x, mouse.y);
            pressX = mouse.x;
            pressY = mouse.y;

            if (mouse.button === Qt.RightButton) {
                if (gridView.currentItem) {
                    if (gridView.currentItem.hasActionList) {
                        var mapped = mapToItem(gridView.currentItem, mouse.x, mouse.y);
                        gridView.currentItem.openActionMenu(mapped.x, mapped.y);
                    }
                } else {
                    var mapped = mapToItem(rootItem, mouse.x, mouse.y);
                    contextMenu.open(mapped.x, mapped.y);
                }
            } else {
                pressedItem = gridView.currentItem;
            }
        }

        onReleased: mouse => {
            mouse.accepted = true;
            updatePositionProperties(mouse.x, mouse.y);

            if (!dragHelper.dragging) {
                if (pressedItem) {
                    if ("trigger" in gridView.model) {
                        gridView.model.trigger(pressedItem.itemIndex, "", null);
                        root.closeMenu();
                    }
                    itemGrid.itemActivated(pressedItem.itemIndex, "", null);
                } else if (mouse.button === Qt.LeftButton) {
                    root.closeMenu();
                }
            }

            pressX = pressY = -1;
            pressedItem = null;
        }

        onPositionChanged: mouse => {
            var item = pressedItem ? pressedItem : updatePositionProperties(mouse.x, mouse.y);

            if (gridView.currentIndex !== -1) {
                if (itemGrid.dragEnabled && pressX !== -1 && dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                    if ("pluginName" in item.m) {
                        dragHelper.startDrag(kicker, item.url, item.icon,
                                             "text/x-plasmoidservicename", item.m.pluginName);
                    } else {
                        dragHelper.startDrag(kicker, item.url);
                    }
                    kicker.dragSource = item;
                    pressX = -1;
                    pressY = -1;
                }
            }
        }

        DropArea {
            id: dropArea
            width: itemGrid.width
            height: itemGrid.height

            onPositionChanged: event => {
                if (kicker.dragSource) {
                    var ez = 52
                    if (event.y < ez) {
                        dragScrollTimer.direction = -1
                        if (!dragScrollTimer.running) dragScrollTimer.start()
                    } else if (event.y > height - ez) {
                        dragScrollTimer.direction = 1
                        if (!dragScrollTimer.running) dragScrollTimer.start()
                    } else {
                        dragScrollTimer.stop()
                        dragScrollTimer.direction = 0
                    }
                }
                if (!itemGrid.dropEnabled || gridView.animating || !kicker.dragSource) return;

                var x = Math.max(0, event.x - (width % itemGrid.cellWidth));
                var cPos = mapToItem(gridView.contentItem, x, event.y);
                var item = gridView.itemAt(cPos.x, cPos.y);

                if (item) {
                    if (kicker.dragSource.parent === gridView.contentItem) {
                        if (item !== kicker.dragSource) {
                            item.GridView.view.model.moveRow(dragSource.itemIndex, item.itemIndex);
                        }
                    }
                }
            }

            onExited: {
                dragScrollTimer.stop()
                dragScrollTimer.direction = 0
                if ("dropPlaceholderIndex" in itemGrid.model) {
                    itemGrid.model.dropPlaceholderIndex = -1;
                    gridView.currentIndex = -1;
                }
            }
        }

        Timer {
            id: dragScrollTimer
            interval: 16
            repeat: true
            property int direction: 0
            onTriggered: {
                var maxY = Math.max(0, gridView.contentHeight - gridView.height)
                if (direction === -1) gridView.contentY = Math.max(0, gridView.contentY - 8)
                else if (direction === 1) gridView.contentY = Math.min(maxY, gridView.contentY + 8)
            }
        }
    }
}
