/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   Start button that creates and manages a PlasmaCore.Dialog popup.
 *   Pattern matches working plasmoids (Start.Next.Menu, menu.11.next).
 ***************************************************************************/

import QtQuick

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

    // Expose the button to screen readers and accessibility tools: without
    // these the Start button is absent from the accessibility tree.
    Accessible.role: Accessible.Button
    Accessible.name: i18nc("@action:button the Start menu button", "Start")
    Accessible.description: i18nc("@info:tooltip", "Open the Start menu")
    Accessible.onPressAction: dashWindow.visible = !dashWindow.visible

    // The Start logo follows the task icons' size instead of snapping on its
    // own: Icon Tasks draws icons at the standard size that fits the cell
    // minus tasks.svg's 2+2 px margins (22 px up to a 35 px panel, 32 px
    // from 36 px), while a cell-filling Start icon stayed at 32 px up to a
    // 47 px panel and looked too small in between. ×1.48 keeps the logo
    // (63 % of its canvas) about 10 % larger than app art (≈85 %), which is
    // exactly today's look at 34 and 48 px (docs/STYLE.md).
    readonly property int cellThickness: vertical ? width : height
    readonly property int taskIconSize: Kirigami.Units.iconSizes.roundedIconSize(Math.max(0, cellThickness - 4))
    readonly property int startIconSize: inPanel ? Math.min(cellThickness, Math.round(taskIconSize * 1.48))
                                                 : Math.min(width, height)

    Kirigami.Icon {
        id: buttonIcon

        anchors.centerIn: parent
        width: root.startIconSize
        height: root.startIconSize
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
