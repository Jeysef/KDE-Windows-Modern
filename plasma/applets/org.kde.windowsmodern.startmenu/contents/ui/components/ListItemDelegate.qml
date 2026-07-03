/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   Compact vertical-list row delegate for the pinned / all-apps left
 *   column.  Icon + name, hover highlight, keyboard activation.
 *   Right-click uses the shared in-dialog ContextMenu (declared at
 *   rootItem level) via Tools.buildAppActions so the menu is identical
 *   to what search results show.
 ***************************************************************************/

import QtQuick

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "../code/tools.js" as Tools

Item {
    id: item

    width: ListView.view ? ListView.view.width : parent.width
    height: showDescription ? Kirigami.Units.gridUnit * 2 : Math.floor(Kirigami.Units.gridUnit * 1.5)

    clip: true

    enabled: !model.disabled

    property int itemIndex: model.index
    property int iconSize: Kirigami.Units.iconSizes.smallMedium
    property bool showDescription: false

    Accessible.role: Accessible.MenuItem
    Accessible.name: model.display !== undefined ? model.display : ""

    // ── Hover background ───────────────────────────────────────────────
    Rectangle {
        id: hoverBackground
        anchors.fill: parent
        radius: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.hoverColor
        opacity: {
            if (mouseArea.containsMouse) return 1.0;
            if (item.ListView.isCurrentItem && item.activeFocus) return 0.5;
            return 0.0;
        }
        Behavior on opacity { NumberAnimation { duration: 90 } }
    }

    // ── Content row ────────────────────────────────────────────────────
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
            width: row.width - icon.width - row.spacing
            spacing: Kirigami.Units.smallSpacing / 2

            PlasmaComponents3.Label {
                id: label
                width: parent.width
                horizontalAlignment: Text.AlignLeft
                maximumLineCount: 1
                elide: Text.ElideRight
                color: Kirigami.Theme.textColor
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
                font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
                text: ("description" in model ? (model.description !== undefined ? model.description : "") : "")
                textFormat: Text.PlainText
            }
        }
    }

    // ── Mouse handling ─────────────────────────────────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        z: 10

        onClicked: mouse => {
            var view = item.ListView.view
            if (view) view.forceActiveFocus();
            if (mouse.button === Qt.RightButton) {
                openContextMenu(mouse.x, mouse.y);
                return;
            }
            launchApp();
        }
    }

    function launchApp() {
        var view = item.ListView.view
        if (view && view.model && typeof view.model.trigger === "function") {
            view.model.trigger(item.itemIndex, "", null);
            root.closeMenu();
        }
    }

    function openContextMenu(localX, localY) {
        var favModel = (typeof kicker !== "undefined" && kicker.globalFavorites)
                       ? kicker.globalFavorites : null
        var favId = (model.favoriteId !== undefined) ? model.favoriteId : ""
        var url = (model.url !== undefined) ? model.url : ""
        var actionList = (model.actionList !== undefined) ? model.actionList : null
        var acts = Tools.buildAppActions(i18n, favModel, favId, url, actionList)
        if (acts.length === 0) return

        var pos = item.mapToItem(sharedContextMenu, localX, localY)
        var view = item.ListView.view
        sharedContextMenu.open(acts, pos.x, pos.y, {
            model: view ? view.model : null,
            index: item.itemIndex
        })
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            event.accepted = true;
            launchApp();
        }
    }
}
