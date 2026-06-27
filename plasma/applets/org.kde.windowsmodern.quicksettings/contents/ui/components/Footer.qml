import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils

Rectangle {
    id: footer

    property real scale: 1
    property int footerHeight: 36 * scale
    property bool showBattery: false
    property bool hasBattery: false

    color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03)

    implicitHeight: footerHeight + 8

    Item {
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.leftMargin: 22
        anchors.rightMargin: 22

        Battery {
            id: battery
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: 16
            visible: footer.showBattery && footer.hasBattery
        }

        Kirigami.Icon {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            source: "configure"
            color: Kirigami.Theme.textColor
            isMask: true
            opacity: settingsMouse.containsMouse ? 1 : 0.7

            MouseArea {
                id: settingsMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: KCMLauncher.openSystemSettings("")
            }
        }
    }
}
