/*
    SPDX-FileCopyrightText: 2013 Aurélien Gâteau <agateau@kde.org>
    SPDX-FileCopyrightText: 2014-2015 Eike Hein <hein@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: root

    property QtObject menu
    property Item visualParent
    property variant actionList
    property bool opened: menu ? (menu.visible) : false

    signal actionClicked(string actionId, variant actionArgument)
    signal closed

    onActionListChanged: refreshMenu();

    onOpenedChanged: {
        if (!opened) {
            closed();
        }
    }

    function open(x, y) {
        if (!actionList) return;
        menu.popup(visualParent, x, y);
    }

    function refreshMenu() {
        if (menu) {
            menu.destroy();
        }
        if (!actionList) return;
        menu = contextMenuComponent.createObject(root);
        fillMenu(menu, actionList);
    }

    function fillMenu(menu, items) {
        for (var i = 0; i < items.length; i++) {
            var actionItem = items[i];
            if (actionItem.subActions) {
                var submenuItem = contextSubmenuItemComponent.createObject(menu, { "actionItem": actionItem });
                fillMenu(submenuItem.submenu, actionItem.subActions);
            } else if (actionItem.type === "separator") {
                contextMenuSeparatorComponent.createObject(menu);
            } else {
                contextMenuItemComponent.createObject(menu, { "actionItem": actionItem });
            }
        }
    }

    Component {
        id: contextMenuComponent
        PlasmaComponents3.Menu {
            id: ctxMenu
        }
    }

    Component {
        id: contextSubmenuItemComponent
        PlasmaComponents3.MenuItem {
            id: submenuItem
            property variant actionItem
            text: actionItem.text ? actionItem.text : ""
            icon.name: actionItem.icon ? actionItem.icon : ""

            property PlasmaComponents3.Menu submenu: PlasmaComponents3.Menu {
            }
        }
    }

    Component {
        id: contextMenuSeparatorComponent
        PlasmaComponents3.MenuSeparator {}
    }

    Component {
        id: contextMenuItemComponent
        PlasmaComponents3.MenuItem {
            property variant actionItem

            text: actionItem.text ? actionItem.text : ""
            enabled: actionItem.type !== "title" && ("enabled" in actionItem ? actionItem.enabled : true)
            icon.name: actionItem.icon ? actionItem.icon : ""
            checkable: actionItem.checkable ? actionItem.checkable : false
            checked: actionItem.checked ? actionItem.checked : false

            onTriggered: {
                root.actionClicked(actionItem.actionId, actionItem.actionArgument);
            }
        }
    }
}
