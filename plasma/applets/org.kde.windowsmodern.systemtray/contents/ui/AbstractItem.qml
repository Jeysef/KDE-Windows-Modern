/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>
    SPDX-FileCopyrightText: 2020 Konrad Materka <materka@gmail.com>
    SPDX-FileCopyrightText: 2020 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmaCore.ToolTipArea {
    id: abstractItem

    required property int index
    required property var model
    required property int status
    required property int effectiveStatus

    required property string itemId
    /*required*/ property alias text: label.text

    // subclasses need to bind these tooltip properties
    required mainText
    required subText
    required textFormat

    readonly property alias iconContainer: iconContainer
    readonly property bool inHiddenLayout: effectiveStatus === PlasmaCore.Types.PassiveStatus
    readonly property bool inVisibleLayout: effectiveStatus === PlasmaCore.Types.ActiveStatus

    property bool effectivePressed: false

    // Keep these in sync with HiddenItems.qml
    readonly property int margins: Kirigami.Units.smallSpacing
    readonly property int maxTextLines: 2

    // input agnostic way to trigger the main action
    signal activated(var pos)

    // proxy signals for MouseArea
    signal clicked(var mouse)
    signal pressed(var mouse)
    signal wheel(var wheel)
    signal contextMenu(var mouse)

    PulseAnimation {
        targetItem: iconContainer
        running: (abstractItem.status === PlasmaCore.Types.NeedsAttentionStatus
                || abstractItem.status === PlasmaCore.Types.RequiresAttentionStatus)
            && Kirigami.Units.longDuration > 0
    }

    MouseArea {
        id: mouseArea
        propagateComposedEvents: true
        // This needs to be above applets when it's in the grid hidden area
        // so that it can receive hover events while the mouse is over an applet,
        // but below them on regular systray, so collapsing works
        z: abstractItem.inHiddenLayout ? 1 : 0
        anchors.fill: abstractItem
        hoverEnabled: true
        drag.filterChildren: true
        // Necessary to make the whole delegate area forward all mouse events
        acceptedButtons: Qt.AllButtons
        // Using onPositionChanged instead of onEntered because changing the
        // index in a scrollable view also changes the view position.
        // onEntered will change the index while the items are scrolling,
        // making it harder to scroll.
        onPositionChanged: if (abstractItem.inHiddenLayout) {
            root.hiddenLayout.currentIndex = abstractItem.index
        }
        onClicked: mouse => { abstractItem.clicked(mouse) }
        onPressed: mouse => {
            if (abstractItem.inHiddenLayout) {
                root.hiddenLayout.currentIndex = abstractItem.index
            }
            abstractItem.hideImmediately()
            abstractItem.pressed(mouse)
        }
        onPressAndHold: mouse => {
            if (mouse.button === Qt.LeftButton) {
                abstractItem.contextMenu(mouse)
            }
        }
        onWheel: wheel => {
            // Only icons in the panel act on the wheel (scrolling over volume
            // or brightness adjusts it). In the flyout the cards are just
            // content: a touchpad scroll over "Brightness & Color" must not
            // change the brightness. Passing the event on would hand it to
            // the applet's own icon underneath (which does), so it is taken
            // here and scrolls the grid instead.
            if (abstractItem.inHiddenLayout) {
                const view = root.hiddenLayout;
                const dy = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y
                                                    : wheel.angleDelta.y / 120 * view.cellHeight / 2;
                const bottom = view.originY + view.contentHeight - view.height;
                view.contentY = Math.max(view.originY, Math.min(view.contentY - dy, bottom));
                wheel.accepted = true;
                return;
            }
            abstractItem.wheel(wheel);
            //Don't accept the event in order to make the scrolling by mouse wheel working
            //for the parent scrollview this icon is in.
            wheel.accepted = false;
        }
    }

    // Behind the chevron the items open pages, so they are drawn as plain
    // launchers (icon over name, as Windows 11's overflow draws icons), not
    // as tiles like the Quick Settings toggles below: a background shows
    // only on hover and press.
    Rectangle {
        visible: abstractItem.inHiddenLayout
        anchors.fill: parent
        radius: 4
        border.width: mouseArea.containsMouse ? 1 : 0
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
        color: {
            if (mouseArea.containsPress)
                return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10);
            if (mouseArea.containsMouse)
                return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06);
            return "transparent";
        }
        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
        z: -1
    }

    ColumnLayout {
        anchors.fill: abstractItem
        // A flyout cell is ~75 px tall: 6 + 28 (icon) + 4 + 2 lines of name
        // (26) + 6 fits; larger margins or icon push two-line names out.
        anchors.leftMargin: abstractItem.inHiddenLayout ? 8 : 0
        anchors.rightMargin: abstractItem.inHiddenLayout ? 8 : 0
        anchors.topMargin: abstractItem.inHiddenLayout ? 6 : 0
        anchors.bottomMargin: abstractItem.inHiddenLayout ? 6 : 0
        spacing: 0

        Item { // centers icon and name in a flyout cell
            Layout.fillHeight: true
            visible: abstractItem.inHiddenLayout
        }

        FocusScope {
            id: iconContainer
            scale: (abstractItem.effectivePressed || mouseArea.containsPress) ? 0.8 : 1

            activeFocusOnTab: !abstractItem.inHiddenLayout
            focus: true // Required in HiddenItemsView so keyboard events can be forwarded to this item
            Accessible.name: abstractItem.text
            Accessible.description: abstractItem.subText
            Accessible.role: Accessible.Button
            Accessible.onPressAction: abstractItem.activated(Plasmoid.popupPosition(iconContainer, iconContainer.width/2, iconContainer.height/2));

            Behavior on scale {
                ScaleAnimator {
                    duration: Kirigami.Units.longDuration
                    easing.type: (abstractItem.effectivePressed || mouseArea.containsPress) ? Easing.OutCubic : Easing.InCubic
                }
            }

            Keys.onPressed: event => {
                switch (event.key) {
                    case Qt.Key_Space:
                    case Qt.Key_Enter:
                    case Qt.Key_Return:
                    case Qt.Key_Select:
                        abstractItem.activated(Qt.point(width/2, height/2));
                        break;
                    case Qt.Key_Menu:
                        abstractItem.contextMenu(null);
                        event.accepted = true;
                        break;
                }
            }

            property alias container: abstractItem
            property alias inVisibleLayout: abstractItem.inVisibleLayout
            readonly property int size: abstractItem.inVisibleLayout ? root.itemSize : 28

            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            implicitWidth: root.vertical && abstractItem.inVisibleLayout ? abstractItem.width : size
            implicitHeight: !root.vertical && abstractItem.inVisibleLayout ? abstractItem.height : size
        }

        Item {
            Layout.preferredHeight: 4
            visible: abstractItem.inHiddenLayout
        }

        PlasmaComponents3.Label {
            id: label

            Layout.fillWidth: true
            maximumLineCount: abstractItem.maxTextLines

            visible: abstractItem.inHiddenLayout

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            elide: Text.ElideRight
            textFormat: Text.PlainText
            wrapMode: Text.Wrap

            font.pixelSize: 10

            opacity: visible ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Item {
            Layout.fillHeight: true
            visible: abstractItem.inHiddenLayout
        }
    }
}
