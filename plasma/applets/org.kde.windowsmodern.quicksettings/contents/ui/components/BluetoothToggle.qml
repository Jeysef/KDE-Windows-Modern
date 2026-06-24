import QtQuick
import org.kde.bluezqt as BluezQt
import "../lib" as Lib
import "../js/funcs.js" as Funcs

Lib.SplitTile {
    id: tile

    property QtObject btManager: BluezQt.Manager

    label: qsTr("Bluetooth")
    iconSource: Funcs.btStatus(btManager).icon
    active: Funcs.btStatus(btManager).active

    onClicked: Funcs.toggleBluetooth(btManager)
}
