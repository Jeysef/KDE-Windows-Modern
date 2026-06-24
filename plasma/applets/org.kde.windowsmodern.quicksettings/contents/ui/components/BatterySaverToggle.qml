import QtQuick
import org.kde.plasma.private.batterymonitor
import "../lib" as Lib

Lib.Tile {
    id: tile

    PowerProfilesControl {
        id: powerProfiles
    }

    readonly property bool saverOn: powerProfiles.activeProfile === "power-saver"
    readonly property bool available: powerProfiles.isPowerProfileDaemonInstalled
                           && powerProfiles.profiles.indexOf("power-saver") >= 0

    visible: available
    label: qsTr("Battery Saver")
    iconSource: Qt.resolvedUrl("../icons/battery-saver-symbolic.svg")
    active: saverOn

    onClicked: {
        if (saverOn) {
            powerProfiles.setProfile(powerProfiles.configuredProfile || "balanced");
        } else {
            powerProfiles.setProfile("power-saver");
        }
    }
}
