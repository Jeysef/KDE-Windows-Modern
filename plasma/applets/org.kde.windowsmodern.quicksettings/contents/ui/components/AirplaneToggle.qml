import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM
import "../lib" as Lib

Lib.Tile {
    id: tile

    label: qsTr("Airplane")
    iconSource: "network-flightmode-on-symbolic"
    active: PlasmaNM.Configuration.airplaneModeEnabled

    onClicked: {
        var enable = !PlasmaNM.Configuration.airplaneModeEnabled;
        var handler = handler;
        if (enable) {
            handler.enableAirplaneMode(true);
        } else {
            handler.enableAirplaneMode(false);
        }
        PlasmaNM.Configuration.airplaneModeEnabled = enable;
    }

    PlasmaNM.Handler { id: handler }
}
