import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.workspace.dbus as DBus
import org.kde.kirigami as Kirigami
import org.kde.kcmutils
import "js/funcs.js" as Funcs

PlasmoidItem {
    id: root

    Plasmoid.icon: "preferences-system-windows"
    Plasmoid.title: i18n("Quick Settings")
    Plasmoid.backgroundHints: PlasmaCore.Types.StandardBackground

    toolTipMainText: Plasmoid.title
    toolTipSubText: ""

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: QuickSettings {}

    // --- Contextual actions (right-click on tray icon) ------------------

    PlasmaCore.Action {
        id: ctxAction1
        onTriggered: root._runAction(0)
    }
    PlasmaCore.Action {
        id: ctxAction2
        onTriggered: root._runAction(1)
    }
    PlasmaCore.Action {
        id: ctxAction3
        onTriggered: root._runAction(2)
    }
    PlasmaCore.Action {
        id: ctxAction4
        onTriggered: root._runAction(3)
    }
    PlasmaCore.Action {
        id: ctxAction5
        onTriggered: root._runAction(4)
    }
    PlasmaCore.Action {
        id: ctxAction6
        onTriggered: root._runAction(5)
    }
    PlasmaCore.Action {
        id: ctxAction7
        onTriggered: root._runAction(6)
    }

    Plasmoid.contextualActions: [ctxAction1, ctxAction2, ctxAction3, ctxAction4, ctxAction5, ctxAction6, ctxAction7]

    Connections {
        target: Plasmoid
        function onContextualActionsAboutToShow() {
            root._rebuildActions();
        }
    }

    property var _currentActions: []

    function _rebuildActions() {
        var actions = [
            {
                text: i18n("Configure Quick Settings…"),
                icon: "configure",
                action: function () {
                    KCMLauncher.openSystemSettings("");
                }
            },
            {
                text: i18n("Open System Settings"),
                icon: "settings-configure",
                action: function () {
                    KCMLauncher.openSystemSettings("");
                }
            },
            {
                text: i18n("Lock Screen"),
                icon: "system-lock-screen",
                action: function () {
                    root._lockScreen();
                }
            },
            {
                text: i18n("Suspend"),
                icon: "system-suspend",
                action: function () {
                    root._suspend();
                }
            },
            {
                text: i18n("Hibernate"),
                icon: "system-hibernate",
                action: function () {
                    root._hibernate();
                }
            },
            {
                text: i18n("Log Out"),
                icon: "system-log-out",
                action: function () {
                    root._logOut();
                }
            },
            {
                text: i18n("Restart"),
                icon: "system-restart",
                action: function () {
                    root._restart();
                }
            },
            {
                text: i18n("Shut Down"),
                icon: "system-shutdown",
                action: function () {
                    root._shutDown();
                }
            },
            {
                text: i18n("Do Not Disturb"),
                icon: "notifications-disabled",
                action: function () {
                    Funcs.toggleDnd(null);
                }
            }
        ];

        var allActions = [ctxAction1, ctxAction2, ctxAction3, ctxAction4, ctxAction5, ctxAction6, ctxAction7];
        for (var i = 0; i < allActions.length; ++i) {
            if (i < actions.length) {
                allActions[i].text = actions[i].text;
                allActions[i].icon.name = actions[i].icon;
                allActions[i].visible = true;
                allActions[i].enabled = true;
            } else {
                allActions[i].visible = false;
            }
        }
        root._currentActions = actions;
    }

    function _runAction(index) {
        if (index < root._currentActions.length && root._currentActions[index].action) {
            root._currentActions[index].action();
        }
    }

    // --- DBus helpers ---------------------------------------------------

    function _lockScreen() {
        DBus.SessionBus.asyncCall({
            service: "org.freedesktop.ScreenSaver",
            path: "/org/freedesktop/ScreenSaver",
            iface: "org.freedesktop.ScreenSaver",
            member: "Lock"
        });
    }

    function _suspend() {
        DBus.SystemBus.asyncCall({
            service: "org.freedesktop.login1",
            path: "/org/freedesktop/login1",
            iface: "org.freedesktop.login1.Manager",
            member: "Suspend",
            arguments: [false]
        });
    }

    function _hibernate() {
        DBus.SystemBus.asyncCall({
            service: "org.freedesktop.login1",
            path: "/org/freedesktop/login1",
            iface: "org.freedesktop.login1.Manager",
            member: "Hibernate",
            arguments: [false]
        });
    }

    function _logOut() {
        DBus.SystemBus.asyncCall({
            service: "org.freedesktop.login1",
            path: "/org/freedesktop/login1",
            iface: "org.freedesktop.login1.Manager",
            member: "TerminateSession",
            arguments: ["", false]
        });
    }

    function _restart() {
        DBus.SystemBus.asyncCall({
            service: "org.freedesktop.login1",
            path: "/org/freedesktop/login1",
            iface: "org.freedesktop.login1.Manager",
            member: "Reboot",
            arguments: [false]
        });
    }

    function _shutDown() {
        DBus.SystemBus.asyncCall({
            service: "org.freedesktop.login1",
            path: "/org/freedesktop/login1",
            iface: "org.freedesktop.login1.Manager",
            member: "PowerOff",
            arguments: [false]
        });
    }
}
