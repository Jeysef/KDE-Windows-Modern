import QtQuick
import org.kde.notificationmanager as NotificationManager
import "../lib" as Lib
import "../js/funcs.js" as Funcs

Lib.Tile {
    id: tile

    NotificationManager.Settings { id: notificationSettings }

    label: qsTr("Do Not Disturb")
    subLabel: ""
    iconSource: Funcs.checkInhibition(notificationSettings) ? "notifications-disabled" : "notifications"
    active: Funcs.checkInhibition(notificationSettings)

    onClicked: Funcs.toggleDnd(notificationSettings)
}
