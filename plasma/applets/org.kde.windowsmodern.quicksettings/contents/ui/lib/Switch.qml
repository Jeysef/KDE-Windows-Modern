import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: control

    property bool checked: false
    signal toggled

    implicitWidth: 36
    implicitHeight: 18

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: control.checked ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
        Behavior on color { ColorAnimation { duration: 100 } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                control.checked = !control.checked;
                control.toggled();
            }
        }

        Rectangle {
            x: control.checked ? parent.width - width - 2 : 2
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: "#FFFFFF"
            Behavior on x { NumberAnimation { duration: 100; easing.type: Easing.InOutQuad } }
        }
    }
}
