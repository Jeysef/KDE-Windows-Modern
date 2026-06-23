/*
    SPDX-FileCopyrightText: 2014 Ashish Madeti <ashishmadeti@gmail.com>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privatebroulik.de>
    SPDX-FileCopyrightText: 2019 Chris Holland <zrenfire@gmail.com>
    SPDX-FileCopyrightText: 2022 ivan (@ratijas) tkachenko <me@ratijas.tk>

    SPDX-License-Identifier: GPL-2.0-or-later

    Simplified fork of org.kde.plasma.win7showdesktop for the Windows
    Modern theme. Removes command/mousewheel/peek-on-hover features;
    keeps the thin sliver rendering and minimize-all behavior.
*/

import QtQuick 2.15
import QtQuick.Layouts 1.3

import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation
    toolTipSubText: activeController.description

    Plasmoid.icon: "transform-move"
    Plasmoid.title: activeController.title
    Plasmoid.onActivated: activeController.toggle()

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Layout.minimumWidth: Kirigami.Units.iconSizes.medium
    Layout.minimumHeight: Kirigami.Units.iconSizes.medium

    Layout.maximumWidth: vertical ? Layout.minimumWidth : Math.max(1, Plasmoid.configuration.size)
    Layout.maximumHeight: vertical ? Math.max(1, Plasmoid.configuration.size) : Layout.minimumHeight

    Layout.preferredWidth: Layout.maximumWidth
    Layout.preferredHeight: Layout.maximumHeight

    Plasmoid.constraintHints: Plasmoid.CanFillArea

    readonly property bool inPanel: [PlasmaCore.Types.TopEdge, PlasmaCore.Types.RightEdge, PlasmaCore.Types.BottomEdge, PlasmaCore.Types.LeftEdge]
            .includes(Plasmoid.location)

    readonly property bool horizontal: Plasmoid.location === PlasmaCore.Types.TopEdge || Plasmoid.location === PlasmaCore.Types.BottomEdge
    readonly property bool vertical: Plasmoid.location === PlasmaCore.Types.RightEdge || Plasmoid.location === PlasmaCore.Types.LeftEdge

    readonly property Controller activeController: minimizeAllController

    MinimizeAllController {
        id: minimizeAllController
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        anchors.rightMargin: -panelMargins.panelEdgeMargin

        activeFocusOnTab: true
        hoverEnabled: true

        PanelMargins {
            id: panelMargins
        }

        onClicked: Plasmoid.activated();

        Keys.onPressed: {
            switch (event.key) {
            case Qt.Key_Space:
            case Qt.Key_Enter:
            case Qt.Key_Return:
            case Qt.Key_Select:
                Plasmoid.activated();
                break;
            }
        }

        Accessible.name: Plasmoid.title
        Accessible.description: toolTipSubText
        Accessible.role: Accessible.Button

        Kirigami.Icon {
            anchors.fill: parent
            active: mouseArea.containsMouse || activeController.active
            visible: Plasmoid.containment.corona.editMode
            source: Plasmoid.icon
        }

        DropArea {
            anchors.fill: parent
            onEntered: activateTimer.start()
            onExited: activateTimer.stop()
        }

        Timer {
            id: activateTimer
            interval: 250
            onTriggered: Plasmoid.activated()
        }

        state: {
            if (mouseArea.containsPress) {
                return "pressed";
            } else if (mouseArea.containsMouse || mouseArea.activeFocus) {
                return "hover";
            } else {
                return "normal";
            }
        }

        component ButtonSurface : Rectangle {
            property var containerMargins: {
                let item = this;
                while (item.parent) {
                    item = item.parent;
                    if (item.isAppletContainer) {
                        return item.getMargins;
                    }
                }
                return undefined;
            }

            anchors {
                fill: parent
                property bool returnAllMargins: true
                topMargin: !vertical && containerMargins ? -containerMargins('top', returnAllMargins) : 0
                leftMargin: vertical && containerMargins ? -containerMargins('left', returnAllMargins) : 0
                rightMargin: vertical && containerMargins ? -containerMargins('right', returnAllMargins) : 0
                bottomMargin: !vertical && containerMargins ? -containerMargins('bottom', returnAllMargins) : 0
            }
            Behavior on opacity { OpacityAnimator { duration: Kirigami.Units.longDuration; easing.type: Easing.OutCubic } }
        }

        ButtonSurface {
            id: hoverSurface
            color: Plasmoid.configuration.hoveredColor || Kirigami.Theme.backgroundColor
            opacity: mouseArea.state === "hover" ? 1 : 0
        }

        ButtonSurface {
            id: pressedSurface
            color: Plasmoid.configuration.pressedColor || Kirigami.Theme.hoverColor
            opacity: mouseArea.state === "pressed" ? 1 : 0
        }

        Rectangle {
            id: edgeLine
            states: [
                State {
                    name: "desktopWidget"
                    when: !root.inPanel
                    AnchorChanges {
                        target: edgeLine
                        anchors.left: edgeLine.parent.left
                        anchors.right: edgeLine.parent.right
                        anchors.top: edgeLine.parent.top
                        anchors.bottom: edgeLine.parent.bottom
                    }
                    PropertyChanges {
                        target: edgeLine
                        color: "transparent"
                        border.color: Plasmoid.configuration.edgeColor || Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
                        border.width: 1
                    }
                },
                State {
                    name: "horizontalPanel"
                    when: root.horizontal
                    AnchorChanges {
                        target: edgeLine
                        anchors.left: edgeLine.parent.left
                        anchors.right: undefined
                        anchors.top: edgeLine.parent.top
                        anchors.bottom: edgeLine.parent.bottom
                    }
                    PropertyChanges {
                        target: edgeLine
                        color: Plasmoid.configuration.edgeColor || Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
                        width: 1
                        border.color: "transparent"
                        border.width: 0
                    }
                },
                State {
                    name: "verticalPanel"
                    when: root.vertical
                    AnchorChanges {
                        target: edgeLine
                        anchors.left: edgeLine.parent.left
                        anchors.right: edgeLine.parent.right
                        anchors.top: edgeLine.parent.top
                        anchors.bottom: undefined
                    }
                    PropertyChanges {
                        target: edgeLine
                        color: Plasmoid.configuration.edgeColor || Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
                        height: 1
                        border.color: "transparent"
                        border.width: 0
                    }
                }
            ]
        }

        PlasmaCore.ToolTipArea {
            id: toolTip
            anchors.fill: parent
            mainText: Plasmoid.title
            subText: toolTipSubText
            textFormat: Text.PlainText
        }
    }
}
