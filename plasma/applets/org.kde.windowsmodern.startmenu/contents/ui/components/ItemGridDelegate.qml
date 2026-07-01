/*
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later

    Phase 1 port — single-column delegate. No folders, no tracking.
*/

import QtQuick

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../code/tools.js" as Tools

Item {
    id: item

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight
    clip: true

    enabled: !model.disabled

    property int iconSize
    property bool showLabel: true

    property int itemIndex: model.index
    property string favoriteId: model.favoriteId !== undefined ? model.favoriteId : ""
    property url url: model.url !== undefined ? model.url : ""
    property variant icon: model.decoration !== undefined ? model.decoration : ""
    property var m: model

    property bool hasActionList: {
        return (model.favoriteId !== null) || (("hasActionList" in model) && (model.hasActionList === true));
    }

    property int itemColumns
    property bool labels2lines: false
    Accessible.role: Accessible.MenuItem
    Accessible.name: model.display

    function openActionMenu(x, y) {
        var actionList = (model.actionList !== undefined) ? model.actionList : [];
        Tools.fillActionMenu(i18n, actionMenu, actionList, GridView.view.model.favoritesModel, model.favoriteId);
        actionMenu.visualParent = item;
        actionMenu.open(x, y);
    }

    function actionTriggered(actionId, actionArgument) {
        var close = (Tools.triggerAction(GridView.view.model, model.index, actionId, actionArgument) === true);
        if (close) {
            root.closeMenu();
        }
    }

    Kirigami.Icon {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        width: iconSize
        height: width
        animated: false
        source: model.decoration
    }

    PlasmaComponents3.Label {
        id: label

        visible: item.showLabel

        anchors {
            top: icon.bottom
            topMargin: Kirigami.Units.smallSpacing
            left: parent.left
            leftMargin: Kirigami.Units.smallSpacing
            right: parent.right
            rightMargin: Kirigami.Units.smallSpacing
        }

        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: item.labels2lines ? 2 : 1
        elide: Text.ElideRight
        wrapMode: Text.Wrap

        color: Kirigami.Theme.textColor
        font.pointSize: Kirigami.Theme.defaultFont.pointSize
        font.family: "Segoe UI"
        text: ("name" in model ? model.name : model.display)
        textFormat: Text.PlainText
    }

    // ── Ctrl+number keyboard shortcut badge ────────────────────────────
    Rectangle {
        visible: typeof rootItem !== "undefined" && rootItem.ctrlHeld && model.index < 9
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        width: Kirigami.Units.gridUnit * 1.4
        height: width
        radius: width / 2
        color: Kirigami.Theme.highlightColor
        z: 3

        Text {
            anchors.centerIn: parent
            text: model.index + 1
            color: Kirigami.Theme.highlightedTextColor
            font.bold: true
            font.pixelSize: parent.width * 0.52
        }
    }

    PlasmaCore.ToolTipArea {
        id: toolTip
        property string text: model.display
        anchors.fill: parent
        active: root.visible && label.truncated
        mainItem: toolTipDelegate
        onContainsMouseChanged: item.GridView.view.itemContainsMouseChanged(containsMouse)
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu && hasActionList) {
            event.accepted = true;
            openActionMenu(item);
        } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
            event.accepted = true;
            if ("trigger" in GridView.view.model) {
                GridView.view.model.trigger(index, "", null);
                root.closeMenu();
            }
            itemGrid.itemActivated(index, "", null);
        }
    }
}
