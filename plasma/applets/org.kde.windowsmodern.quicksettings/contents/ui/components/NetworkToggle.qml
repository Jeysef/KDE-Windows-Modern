import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM
import "../lib" as Lib

Lib.SplitTile {
    id: tile

    PlasmaNM.Handler { id: handler }
    PlasmaNM.EnabledConnections { id: enabledConnections }
    PlasmaNM.AvailableDevices { id: availableDevices }
    PlasmaNM.ConnectionIcon { id: activeConnectionIcon }
    PlasmaNM.NetworkStatus { id: netStatus }

    readonly property bool wifiAvailable: availableDevices.wirelessDeviceAvailable
    readonly property bool wifiOn: wifiAvailable && enabledConnections.wirelessEnabled
    label: qsTr("Wi-Fi")
    iconSource: activeConnectionIcon.connectionIcon

    onClicked: {
        if (wifiAvailable) {
            handler.enableWireless(!wifiOn);
        }
    }
}
