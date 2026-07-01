/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   Compact vertical-list row delegate for the StartAllBack-style
 *   pinned / all-apps left column.  Icon + name + optional submenu arrow,
 *   hover highlight, keyboard activation.  Right-click uses a shared
 *   in-dialog ContextMenu (declared at rootItem level) to avoid stacking.
 ***************************************************************************/

import QtQuick

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

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
    property bool showDescription: false

    Accessible.role: Accessible.MenuItem
    Accessible.name: model.display !== undefined ? model.display : ""

    signal activated(int index, string actionId, string actionArgument)

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

    // ── Mouse handling ─────────────────────────────────────────────────
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        z: 10

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                openContextMenu(mouse.x, mouse.y);
                return;
            }
            // Left click — trigger the app
            var view = item.ListView.view
            if (view && view.model && typeof view.model.trigger === "function") {
                view.model.trigger(item.itemIndex, "", null);
                root.closeMenu();
            }
            item.activated(item.itemIndex, "", null);
        }
    }

    function openContextMenu(localX, localY) {
        var acts = []

        // App-specific actions from the model
        var modelActions = (model.actionList !== undefined) ? model.actionList : []
        for (var i = 0; i < modelActions.length; i++) {
            acts.push(modelActions[i])
        }

        // Add pin/unpin favorite action
        var favModel = (typeof kicker !== "undefined" && kicker.globalFavorites) ? kicker.globalFavorites : null
        if (favModel && favModel.enabled && item.favoriteId !== "") {
            if (acts.length > 0) {
                acts.push({ type: "separator" })
            }
            if (favModel.isFavorite(item.favoriteId)) {
                acts.push({
                    text: i18n("Remove from Favorites"),
                    icon: "bookmark-remove",
                    actionId: "_kicker_favorite_remove",
                    actionArgument: item.favoriteId
                })
            } else {
                acts.push({
                    text: i18n("Add to Favorites"),
                    icon: "bookmark-new",
                    actionId: "_kicker_favorite_add",
                    actionArgument: item.favoriteId
                })
            }
        }

        if (acts.length === 0) return

        // Map position to rootItem coordinate space
        var pos = item.mapToItem(sharedContextMenu, localX, localY)

        // Suppress dialog auto-hide
        if (typeof root !== "undefined") {
            root.hideOnWindowDeactivate = false
        }

        sharedContextMenu.open(acts, pos.x, pos.y)
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            event.accepted = true;
            var view = item.ListView.view
            if (view && view.model && typeof view.model.trigger === "function") {
                view.model.trigger(index, "", null);
                root.closeMenu();
            }
            item.activated(index, "", null);
        }
    }
}
