import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    id: tile

    property string iconSource
    property string label
    property bool active: false

    signal clicked
    signal arrowClicked

    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color fg: active ? "#FFFFFF" : Kirigami.Theme.textColor

    spacing: 4
    Layout.fillWidth: true
    Layout.preferredWidth: 0

    Rectangle {
        id: bg
        Layout.fillWidth: true
        Layout.preferredHeight: width / 2
        radius: 4
        border.width: 1
        border.color: active ? "transparent" : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
        color: {
            if (active) return accent;
            if (toggleMA.containsPress) return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10);
            if (toggleMA.containsMouse || arrowMA.containsMouse) return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06);
            return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04);
        }

        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

        MouseArea {
            id: toggleMA
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.70
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }

        MouseArea {
            id: arrowMA
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * 0.30
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.arrowClicked()
        }

        Kirigami.Icon {
            x: parent.width * 0.35 - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            source: tile.iconSource
            color: tile.fg
            isMask: true
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width * 0.70
            width: 1
            height: parent.height * 0.5
            color: active ? Qt.rgba(1, 1, 1, 0.4) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
        }

        Kirigami.Icon {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            source: "go-next"
            color: tile.fg
            isMask: true
        }
    }

    PlasmaComponents3.Label {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        text: tile.label
        color: Kirigami.Theme.textColor
        font.pixelSize: 10
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }
}
