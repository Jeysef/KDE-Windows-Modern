/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   Start button that creates and manages a PlasmaCore.Dialog popup.
 *   Pattern matches working plasmoids (Start.Next.Menu, menu.11.next).
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: root

    readonly property var screenGeometry: Plasmoid.screenGeometry
    readonly property bool inPanel: (Plasmoid.location == PlasmaCore.Types.TopEdge
                                     || Plasmoid.location == PlasmaCore.Types.RightEdge
                                     || Plasmoid.location == PlasmaCore.Types.BottomEdge
                                     || Plasmoid.location == PlasmaCore.Types.LeftEdge)
    readonly property bool vertical: (Plasmoid.formFactor == PlasmaCore.Types.Vertical)
    readonly property bool useCustomButtonImage: (Plasmoid.configuration.useCustomButtonImage
                                                  && Plasmoid.configuration.customButtonImage.length != 0)
    property QtObject dashWindow: null

    Plasmoid.status: dashWindow && dashWindow.visible ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.PassiveStatus

    // Square button that follows the panel thickness; the icon is inset slightly and not
    // snapped to fixed icon sizes, so Start matches the task manager's icons at any height.
    Layout.minimumWidth: vertical ? -1 : height
    Layout.minimumHeight: vertical ? width : -1
    Layout.preferredWidth: vertical ? -1 : height
    Layout.preferredHeight: vertical ? width : -1

    Kirigami.Icon {
        id: buttonIcon

        // Same visual size as the icon task manager's icons (about 80% of the panel cell).
        anchors.centerIn: parent
        width: inPanel ? Math.round(Math.min(root.width, root.height) * 0.8) : root.width
        height: width
        roundToIconSize: false
        source: useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon
        active: mouseArea.containsMouse
        smooth: true
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            dashWindow.visible = !dashWindow.visible;
        }
    }

    Component.onCompleted: {
        dashWindow = menuRepComponent.createObject(root);
        Plasmoid.activated.connect(function() {
            dashWindow.visible = !dashWindow.visible;
        });
    }

    Component {
        id: menuRepComponent
        MenuRepresentation {}
    }
}
