/*
    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later

    Windows 11 taskbar Search button (optional; not on the default panel).
    Opens the Start menu, which focuses its search field, so typing
    searches straight away. It asks Plasma for "the launcher" exactly as
    the Meta key does (org.kde.PlasmaShell.activateLauncherMenu, see
    plasma-workspace shell/shellcorona.cpp), so it works with the Windows
    Modern Start menu, Kickoff, or any applet that provides
    org.kde.plasma.launchermenu on the active screen.

    This applet must not provide org.kde.plasma.launchermenu itself, or
    Plasma would "activate the launcher" by activating this button.
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

    function openSearch(): void {
        DBus.SessionBus.asyncCall({
            service: "org.kde.plasmashell",
            path: "/PlasmaShell",
            iface: "org.kde.PlasmaShell",
            member: "activateLauncherMenu",
        });
    }

    preferredRepresentation: fullRepresentation
    Plasmoid.icon: "edit-find"
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.onActivated: openSearch()

    // A square cell, like the task buttons: as wide as a horizontal panel
    // is thick, as tall as a vertical panel is wide.
    // On the desktop it is a plain large-icon-sized button.
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
        iconName: "edit-find"
        fallbackIconName: "system-search-symbolic"
        text: i18nc("@action:button taskbar button", "Search")
        description: i18nc("@info:tooltip", "Open Start and search")
        onTriggered: root.openSearch()

        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: i18nc("@info:tooltip", "Search")
            textFormat: Text.PlainText
        }
    }
    // qmllint enable unqualified
}
