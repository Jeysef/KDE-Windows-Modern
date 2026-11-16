/*
    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later

    Windows 11 taskbar Task View button (optional; not on the default
    panel). Task View is KWin's Overview here, the effect Win+Tab opens
    (scripts/windows-shortcuts.py). The button invokes that global
    shortcut action, "Overview" of the "kwin" component (KWin
    src/plugins/overview/overvieweffect.cpp), so it does what the key does
    whatever key the user bound to it.
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.workspace.dbus as DBus
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool horizontal: Plasmoid.formFactor === PlasmaCore.Types.Horizontal

    function openTaskView(): void {
        // invokeShortcut has a default "context" argument, so D-Bus offers
        // both (s) and (ss); name the overload rather than let the D-Bus
        // module guess it from introspection.
        DBus.SessionBus.asyncCall({
            service: "org.kde.kglobalaccel",
            path: "/component/kwin",
            iface: "org.kde.kglobalaccel.Component",
            member: "invokeShortcut",
            arguments: ["Overview", "default"],
            signature: "(ss)",
        });
    }

    preferredRepresentation: fullRepresentation
    Plasmoid.icon: "window-duplicate"
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.onActivated: openTaskView()

    // A square cell, like the task buttons: as wide as a horizontal panel
    // is thick, as tall as a vertical panel is wide. On the desktop it is
    // a plain large-icon-sized button.
    Layout.minimumWidth: horizontal ? height : (vertical ? 0 : Kirigami.Units.iconSizes.large)
    Layout.maximumWidth: horizontal ? height : Number.POSITIVE_INFINITY
    Layout.preferredWidth: Layout.minimumWidth
    Layout.minimumHeight: vertical ? width : (horizontal ? 0 : Kirigami.Units.iconSizes.large)
    Layout.maximumHeight: vertical ? width : Number.POSITIVE_INFINITY
    Layout.preferredHeight: Layout.minimumHeight

    // i18nc() is put into the applet's context by Plasma, where qmllint
    // cannot see it.
    // qmllint disable unqualified
    TaskbarButton {
        anchors.fill: parent
        iconName: "window-duplicate"
        fallbackIconName: "window-duplicate-symbolic"
        text: i18nc("@action:button taskbar button", "Task View")
        description: i18nc("@info:tooltip", "Show all windows and desktops")
        onTriggered: root.openTaskView()

        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: i18nc("@info:tooltip", "Task View")
            textFormat: Text.PlainText
        }
    }
    // qmllint enable unqualified
}
