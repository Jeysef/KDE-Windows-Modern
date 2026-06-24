import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.private.volume as Vol
import org.kde.plasma.private.battery
import org.kde.kirigami as Kirigami
import "js/funcs.js" as Funcs

MouseArea {
    id: compact

    property bool wasExpanded

    Layout.minimumWidth: row.implicitWidth + 4
    Layout.maximumWidth: Layout.minimumWidth
    Layout.preferredWidth: Layout.minimumWidth
    Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium
    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
    Layout.maximumHeight: Kirigami.Units.iconSizes.smallMedium

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: wasExpanded = root.expanded
    onClicked: root.expanded = !wasExpanded

    PlasmaNM.ConnectionIcon { id: connectionIcon }
    PlasmaNM.NetworkStatus { id: netStatus }

    readonly property var sink: Vol.PreferredDevice.sink
    readonly property bool sinkAvailable: sink && !(sink.name === "auto_null")

    BatteryControlModel { id: batteryControl }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Kirigami.Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            source: connectionIcon.connectionIcon
            color: Kirigami.Theme.textColor
            isMask: true
            roundToIconSize: false
        }

        Kirigami.Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            source: Funcs.volIconName(compact.sinkAvailable ? compact.sink.volume : 0, compact.sinkAvailable ? compact.sink.muted : true)
            color: Kirigami.Theme.textColor
            isMask: true
            roundToIconSize: false
        }

        Kirigami.Icon {
            visible: batteryControl.hasBatteries
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            source: Funcs.batteryIconName(batteryControl.percent, batteryControl.state === BatteryControlModel.Charging)
            color: Kirigami.Theme.textColor
            isMask: true
            roundToIconSize: false
        }
    }
}
