/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   Shared in-dialog context menu popup for list delegates.  A single
 *   instance lives at the rootItem level; delegates call open() with
 *   their action list and position.  Avoids stacking multiple popups.
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: root

    signal actionTriggered(string actionId, var argument)
    signal closed

    // ── Click catcher ──────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        visible: popup.visible
        z: 90
        onClicked: root.close()
    }

    // ── The floating panel ─────────────────────────────────────────────
    Rectangle {
        id: popup
        visible: false
        z: 100
        width: Kirigami.Units.gridUnit * 15
        height: menuColumn.implicitHeight + Kirigami.Units.smallSpacing
        radius: Kirigami.Units.smallSpacing
        color: Kirigami.Theme.backgroundColor
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                               Kirigami.Theme.textColor.g,
                               Kirigami.Theme.textColor.b, 0.2)

        Column {
            id: menuColumn
            width: popup.width - Kirigami.Units.smallSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Kirigami.Units.smallSpacing / 2
            spacing: 0

            Repeater {
                model: root.actions

                delegate: Item {
                    width: menuColumn.width
                    height: modelData.type === "separator" ? 1 : Math.floor(Kirigami.Units.gridUnit * 1.6)

                    Rectangle {
                        anchors.fill: parent
                        visible: modelData.type !== "separator"
                        radius: Kirigami.Units.smallSpacing / 2
                        color: rowHover.containsMouse ? Kirigami.Theme.hoverColor : "transparent"
                        opacity: rowHover.containsMouse ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 80 } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: modelData.type === "separator"
                        color: Qt.rgba(Kirigami.Theme.textColor.r,
                                       Kirigami.Theme.textColor.g,
                                       Kirigami.Theme.textColor.b, 0.15)
                    }

                    RowLayout {
                        visible: modelData.type !== "separator"
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.smallSpacing

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                            source: modelData.icon || ""
                        }

                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: modelData.text || ""
                            color: Kirigami.Theme.textColor
                            font.family: "Segoe UI"
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        visible: modelData.type !== "separator"
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.actionTriggered(modelData.actionId, modelData.actionArgument || null)
                            root.close()
                        }
                    }
                }
            }
        }
    }

    property var actions: []

    // Measure the widest action text to size the popup.
    TextMetrics {
        id: widestText
        font.family: "Segoe UI"
        font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
        text: {
            var maxText = ""
            for (var i = 0; i < root.actions.length; i++) {
                var a = root.actions[i]
                if (a.type === "separator") continue
                var t = a.text || ""
                if (t.length > maxText.length) maxText = t
            }
            return maxText
        }
    }

    readonly property int popupWidth: Math.min(
        Math.max(widestText.width + Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing * 4, Kirigami.Units.gridUnit * 8),
        Kirigami.Units.gridUnit * 20
    )

    function open(actionList, globalX, globalY) {
        root.actions = actionList
        if (actionList.length === 0) return

        var popupW = root.popupWidth
        var popupH = popup.height
        var gap = Kirigami.Units.smallSpacing

        var px = Math.max(gap, Math.min(globalX, root.width - popupW - gap))
        var py = globalY + gap
        if (py + popupH > root.height) {
            py = globalY - popupH - gap
        }

        popup.x = px
        popup.y = py
        popup.width = popupW
        popup.visible = true
    }

    function close() {
        popup.visible = false
        root.actions = []
        root.closed()
    }
}
