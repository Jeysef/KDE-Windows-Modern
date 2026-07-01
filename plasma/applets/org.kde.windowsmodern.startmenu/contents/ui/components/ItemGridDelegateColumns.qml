/*
    SPDX-FileCopyrightText: 2015 Eike Hein <hein@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later

    Phase 1 port — multi-column delegate. No folders, no pin buttons.
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
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Kirigami.Units.largeSpacing

        width: iconSize
        height: width
        animated: false
        source: model.decoration
    }

    Column {
        id: textBlock
        anchors.left: icon.right
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.right: parent.right
        anchors.rightMargin: Kirigami.Units.largeSpacing
        anchors.verticalCenter: icon.verticalCenter
        spacing: Kirigami.Units.smallSpacing / 2

        PlasmaComponents3.Label {
            id: label
            visible: item.showLabel
            width: parent.width
            horizontalAlignment: Text.AlignLeft
            maximumLineCount: item.labels2lines ? 2 : 1
            elide: item.labels2lines ? Text.ElideNone : Text.ElideRight
            color: Kirigami.Theme.textColor
            font.family: "Segoe UI"
            font.pointSize: Kirigami.Theme.defaultFont.pointSize
            text: ("name" in model ? model.name : model.display)
            textFormat: Text.PlainText
        }

        PlasmaComponents3.Label {
            id: desc
            visible: text.length > 0
            width: parent.width
            horizontalAlignment: Text.AlignLeft
            maximumLineCount: 1
            elide: Text.ElideRight
            color: Kirigami.Theme.disabledTextColor
            font.family: "Segoe UI"
            font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
            text: ("description" in model ? model.description : "")
            textFormat: Text.PlainText
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
