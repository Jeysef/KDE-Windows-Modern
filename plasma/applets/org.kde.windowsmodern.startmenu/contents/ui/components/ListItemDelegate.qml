/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   Compact vertical-list row delegate for the StartAllBack-style
 *   pinned / all-apps left column.  Icon + name + optional submenu arrow,
 *   hover highlight, keyboard activation, right-click action menu.
 ***************************************************************************/

import QtQuick

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import "../code/tools.js" as Tools

Item {
    id: item

    width: ListView.view ? ListView.view.width : parent.width
    height: showDescription ? Kirigami.Units.gridUnit * 2 : Math.floor(Kirigami.Units.gridUnit * 1.5)

    clip: true

    enabled: !model.disabled

    property int itemIndex: model.index
    property string favoriteId: model.favoriteId !== undefined ? model.favoriteId : ""
    property url url: model.url !== undefined ? model.url : ""
    property variant icon: model.decoration !== undefined ? model.decoration : ""
    property var m: model

    property bool hasActionList: {
        return (model.favoriteId !== null) || (("hasActionList" in model) && (model.hasActionList === true));
    }

    property bool hasSubmenu: (("hasSubmenu" in model) && (model.hasSubmenu === true))

    property int iconSize: Kirigami.Units.iconSizes.smallMedium

    // StartAllBack rows are single-line by default; enable for a two-line
    // (name + description) layout.
    property bool showDescription: false

    Accessible.role: Accessible.MenuItem
    Accessible.name: model.display !== undefined ? model.display : ""

    signal activated(int index, string actionId, string actionArgument)
    signal contextMenuRequested(int index)

    function openActionMenu(x, y) {
        var actionList = (model.actionList !== undefined) ? model.actionList : [];
        var favModel = ListView.view && ListView.view.model ? (ListView.view.model.favoritesModel || null) : null;
        Tools.fillActionMenu(i18n, actionMenu, actionList, favModel, model.favoriteId);
        actionMenu.visualParent = item;
        actionMenu.open(x, y);
    }

    function actionTriggered(actionId, actionArgument) {
        var close = (Tools.triggerAction(ListView.view.model, model.index, actionId, actionArgument) === true);
        if (close) {
            root.closeMenu();
        }
    }

    ActionMenu {
        id: actionMenu
        onActionClicked: {
            visualParent.actionTriggered(actionId, actionArgument);
        }
    }

    Rectangle {
        id: hoverBackground
        anchors.fill: parent
        anchors.margins: 0
        radius: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.hoverColor
        opacity: {
            if (mouseArea.containsMouse) return 1.0;
            if (item.ListView.isCurrentItem && item.activeFocus) return 0.5;
            return 0.0;
        }
        Behavior on opacity { NumberAnimation { duration: 90 } }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Kirigami.Units.largeSpacing
        anchors.right: parent.right
        anchors.rightMargin: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            width: item.iconSize
            height: width
            animated: false
            source: model.decoration !== undefined ? model.decoration : ""
        }

        Column {
            id: textBlock
            anchors.verticalCenter: parent.verticalCenter
            width: row.width - icon.width - row.spacing - (arrowIndicator.visible ? arrowIndicator.width + row.spacing : 0)
            spacing: Kirigami.Units.smallSpacing / 2

            PlasmaComponents3.Label {
                id: label
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                maximumLineCount: 1
                elide: Text.ElideRight
                color: Kirigami.Theme.textColor
                font.family: "Segoe UI"
                font.pointSize: Kirigami.Theme.defaultFont.pointSize
                text: ("name" in model ? model.name : (model.display !== undefined ? model.display : ""))
                textFormat: Text.PlainText
            }

            PlasmaComponents3.Label {
                id: desc
                visible: item.showDescription && text.length > 0
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                maximumLineCount: 1
                elide: Text.ElideRight
                color: Kirigami.Theme.disabledTextColor
                font.family: "Segoe UI"
                font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
                text: ("description" in model ? (model.description !== undefined ? model.description : "") : "")
                textFormat: Text.PlainText
            }
        }

        Kirigami.Icon {
            id: arrowIndicator
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            width: Kirigami.Units.iconSizes.small
            height: width
            source: "go-next"
            visible: item.hasSubmenu
            opacity: 0.6
        }
    }

    PlasmaCore.ToolTipArea {
        id: toolTip
        property string text: model.display !== undefined ? model.display : ""
        anchors.fill: parent
        active: root.visible && label.truncated
        mainItem: toolTipDelegate
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (item.hasActionList) {
                    item.openActionMenu(mouse.x, mouse.y);
                }
                return;
            }
            if ("trigger" in ListView.view.model) {
                ListView.view.model.trigger(item.itemIndex, "", null);
                root.closeMenu();
            }
            item.activated(item.itemIndex, "", null);
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu && hasActionList) {
            event.accepted = true;
            openActionMenu(item);
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            event.accepted = true;
            if ("trigger" in ListView.view.model) {
                ListView.view.model.trigger(index, "", null);
                root.closeMenu();
            }
            item.activated(index, "", null);
        }
    }
}
