/*
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later

    Phase 1 port — sectioned grid for search/category results.
*/

import QtQuick

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmaComponents.ScrollView {
    id: itemMultiGrid

    width: parent.width
    implicitHeight: itemColumn.implicitHeight

    signal keyNavUp
    signal keyNavDown

    property bool grabFocus: false

    property alias model: repeater.model
    property alias count: repeater.count
    property alias flickableItem: flickable

    property int itemColumns
    property int cellWidth
    property int cellHeight

    function subGridAt(index) {
        return repeater.itemAt(index).itemGrid;
    }

    function tryActivate(row, col) {
        if (flickable.contentY > 0) row = 0;

        var target = null;
        var rows = 0;

        for (var i = 0; i < repeater.count; i++) {
            var grid = subGridAt(i);
            if (grid.count > 0) {
                if (rows <= row) {
                    target = grid;
                    rows += grid.lastRow() + 2;
                } else {
                    break;
                }
            }
        }

        if (target) {
            rows -= (target.lastRow() + 2);
            target.tryActivate(row - rows, col);
        }
    }

    onFocusChanged: {
        if (!focus) {
            for (var i = 0; i < repeater.count; i++) {
                subGridAt(i).focus = false;
            }
        }
    }

    Flickable {
        id: flickable
        width: itemMultiGrid.availableWidth
        height: itemMultiGrid.availableHeight
        clip: true
        flickableDirection: Flickable.VerticalFlick
        contentHeight: itemColumn.implicitHeight
        contentWidth: width

        WheelHandler {
            onWheel: function(event) {
                var maxY = Math.max(0, flickable.contentHeight - flickable.height)
                flickable.contentY = Math.max(0, Math.min(maxY, flickable.contentY - event.angleDelta.y))
            }
        }

        Column {
            id: itemColumn
            width: flickable.width

            Repeater {
                id: repeater
                delegate: Item {
                    width: itemColumn.width
                    height: visible ? sectionLayout.implicitHeight : 0
                    visible: gridView.count > 0

                    property Item itemGrid: gridView
                    property bool sectionCollapsed: false

                    Column {
                        id: sectionLayout
                        width: parent.width
                        spacing: 0

                        Item {
                            id: sectionHeader
                            width: parent.width
                            height: categoryLabel.implicitHeight + Kirigami.Units.smallSpacing * 2

                            Text {
                                id: categoryLabel
                                anchors.left: parent.left
                                anchors.leftMargin: Kirigami.Units.smallSpacing
                                anchors.top: parent.top
                                anchors.topMargin: Kirigami.Units.smallSpacing
                                anchors.right: collapseChevron.left
                                anchors.rightMargin: Kirigami.Units.smallSpacing

                                text: {
                                    if (!repeater.model) return ""
                                    var idx = repeater.model.index(index, 0)
                                    var name = repeater.model.data(idx, Qt.DisplayRole)
                                    if (name) return name
                                    var sub = repeater.model.modelForRow(index)
                                    return sub ? sub.description : ""
                                }
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                                font.family: "Segoe UI"
                                font.weight: Font.DemiBold
                                color: Kirigami.Theme.disabledTextColor
                                elide: Text.ElideRight
                            }

                            Kirigami.Icon {
                                id: collapseChevron
                                anchors.right: parent.right
                                anchors.rightMargin: Kirigami.Units.smallSpacing * 2
                                anchors.verticalCenter: categoryLabel.verticalCenter
                                width: Kirigami.Units.iconSizes.small
                                height: width
                                source: sectionCollapsed ? "arrow-right" : "arrow-down"
                                opacity: headerHover.containsMouse ? 0.9 : 0.45
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: Kirigami.Units.smallSpacing
                                anchors.rightMargin: Kirigami.Units.smallSpacing
                                anchors.bottom: parent.bottom
                                height: 1
                                color: Kirigami.Theme.textColor
                                opacity: 0.08
                            }

                            MouseArea {
                                id: headerHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: sectionCollapsed = !sectionCollapsed
                            }
                        }

                        Item {
                            width: parent.width
                            height: Kirigami.Units.smallSpacing
                            visible: !sectionCollapsed
                        }

                        ItemGridView {
                            id: gridView
                            visible: !sectionCollapsed

                            Connections {
                                target: gridView
                                onKeyNavDown: {
                                    if (gridView.currentIndex < gridView.count - 1) {
                                        gridView.currentIndex += 1
                                        return
                                    }
                                    var i = index
                                    for (var j = i + 1; j < repeater.count; j++) {
                                        var nextDelegate = repeater.itemAt(j)
                                        var next = nextDelegate.itemGrid
                                        if (next.count > 0 && !nextDelegate.sectionCollapsed) {
                                            next.currentIndex = 0
                                            next.focus = true
                                            return
                                        }
                                    }
                                }
                                onKeyNavUp: {
                                    if (gridView.currentIndex > 0) {
                                        gridView.currentIndex -= 1
                                        return
                                    }
                                    var i = index
                                    for (var j = i - 1; j >= 0; j--) {
                                        var prevDelegate = repeater.itemAt(j)
                                        var prev = prevDelegate.itemGrid
                                        if (prev.count > 0 && !prevDelegate.sectionCollapsed) {
                                            prev.currentIndex = prev.count - 1
                                            prev.focus = true
                                            return
                                        }
                                    }
                                    if (i === 0 && gridView.currentIndex === 0) {
                                        searchField.forceActiveFocus()
                                    }
                                }
                            }

                            width: parent.width
                            height: {
                                var cols = Math.max(1, Math.floor(width / itemMultiGrid.cellWidth))
                                return Math.ceil(count / cols) * itemMultiGrid.cellHeight
                            }
                            itemColumns: itemMultiGrid.itemColumns

                            cellWidth: itemMultiGrid.cellWidth
                            cellHeight: itemMultiGrid.cellHeight
                            iconSize: root.iconSize

                            verticalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff
                            bypassArrowNav: true
                            model: repeater.model.modelForRow(index)

                            onFocusChanged: {
                                if (focus) itemMultiGrid.focus = true;
                            }

                            onCountChanged: {
                                if (itemMultiGrid.grabFocus && index == 0 && count > 0) {
                                    currentIndex = 0;
                                    focus = true;
                                }
                            }

                            onCurrentItemChanged: {
                                if (!currentItem) return;
                                if (index == 0 && currentRow() === 0) {
                                    flickable.contentY = 0;
                                    return;
                                }
                                var y = currentItem.y;
                                y = contentItem.mapToItem(flickable.contentItem, 0, y).y;
                                if (y < flickable.contentY) {
                                    flickable.contentY = y;
                                } else {
                                    y += itemMultiGrid.cellHeight;
                                    y -= flickable.contentY;
                                    y -= itemMultiGrid.height;
                                    if (y > 0) flickable.contentY += y;
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: sectionCollapsed
                                    ? Kirigami.Units.smallSpacing
                                    : Kirigami.Units.largeSpacing * 2
                        }
                    }
                }
            }
        }
    }
}
