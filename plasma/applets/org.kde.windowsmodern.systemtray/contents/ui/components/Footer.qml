/*
    Quick Settings footer, as in Windows 11: battery level on the left
    (laptops only; opens the battery page) and a Settings gear on the right
    (System Settings; right-click for the common pages). No power button:
    that lives in Start, as on Windows.
*/
import QtQuick
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.kcmutils
import "../lib" as Lib
import "." as Components

Rectangle {
    id: footer

    property real uiScale: 1

    signal batteryClicked

    // Only a divider: a filled strip would show the popup frame's inset
    // (Windows 11's strip runs edge to edge, which the theme frame does not allow).
    color: "transparent"
    implicitHeight: Math.round(48 * uiScale)

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
    }

    Components.Battery {
        id: battery
        anchors.left: parent.left
        anchors.leftMargin: Math.round(20 * footer.uiScale)
        anchors.verticalCenter: parent.verticalCenter
        visible: battery.hasBattery
        opacity: batteryMouse.containsMouse ? 1 : 0.85

        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Battery %1%").arg(battery.percent)

        MouseArea {
            id: batteryMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: footer.batteryClicked()
        }
    }

    Lib.FooterButton {
        id: settingsBtn
        anchors.right: parent.right
        anchors.rightMargin: Math.round(20 * footer.uiScale)
        anchors.verticalCenter: parent.verticalCenter
        buttonSize: Math.round(18 * footer.uiScale)
        iconSource: "configure"
        tooltipText: qsTr("All settings")
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("All settings")
        onClicked: KCMLauncher.openSystemSettings("")
        onRightClicked: gearMenu.popup()
    }

    PlasmaComponents3.Menu {
        id: gearMenu

        PlasmaComponents3.MenuItem {
            text: qsTr("Display settings")
            icon.name: "preferences-desktop-display"
            onClicked: KCMLauncher.openSystemSettings("kcm_kscreen")
        }
        PlasmaComponents3.MenuItem {
            text: qsTr("Sound settings")
            icon.name: "audio-volume-high"
            onClicked: KCMLauncher.openSystemSettings("kcm_pulseaudio")
        }
        PlasmaComponents3.MenuItem {
            text: qsTr("Network settings")
            icon.name: "network-wireless"
            onClicked: KCMLauncher.openSystemSettings("kcm_networkmanagement")
        }
        PlasmaComponents3.MenuItem {
            text: qsTr("Power settings")
            icon.name: "battery"
            onClicked: KCMLauncher.openSystemSettings("kcm_powerdevilprofilesconfig")
        }
        PlasmaComponents3.MenuItem {
            text: qsTr("Notification settings")
            icon.name: "notifications"
            onClicked: KCMLauncher.openSystemSettings("kcm_notifications")
        }
    }
}
