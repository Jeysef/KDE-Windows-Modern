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
            if (ma.containsPress) return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.10);
            if (ma.containsMouse) return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06);
            return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04);
        }

        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            width: 20
            height: 20
            source: tile.iconSource
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
