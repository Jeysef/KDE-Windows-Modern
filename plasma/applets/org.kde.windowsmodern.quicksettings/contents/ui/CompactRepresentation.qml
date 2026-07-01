import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.private.volume as Vol
import org.kde.plasma.private.battery
import org.kde.bluezqt as BluezQt
import org.kde.notificationmanager as NotificationManager
import org.kde.kirigami as Kirigami
import "js/funcs.js" as Funcs

MouseArea {
    id: compact

    property bool wasExpanded

    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

    Layout.minimumWidth: row.implicitWidth + 4
    Layout.maximumWidth: Layout.minimumWidth
    Layout.preferredWidth: Layout.minimumWidth
    Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium
    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
    Layout.maximumHeight: Kirigami.Units.iconSizes.smallMedium

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onPressed: function (mouse) {
        if (mouse.button === Qt.LeftButton)
            wasExpanded = root.expanded;
    }
    onClicked: function (mouse) {
        if (mouse.button === Qt.LeftButton)
            root.expanded = !wasExpanded;
        else if (mouse.button === Qt.MiddleButton && compact.sinkAvailable)
            compact.sink.muted = !compact.sink.muted;
    }

    PlasmaNM.ConnectionIcon {
        id: connectionIcon
    }
    PlasmaNM.NetworkStatus {
        id: netStatus
    }

    readonly property var sink: Vol.PreferredDevice.sink
    readonly property bool sinkAvailable: sink && !(sink.name === "auto_null")

    BatteryControlModel {
        id: batteryControl
    }

    property QtObject btManager: BluezQt.Manager

    NotificationManager.Settings {
        id: notificationSettings
    }

    readonly property string tooltipMain: {
        var parts = [];
        parts.push(i18n("Quick Settings"));
        var wifiPart = netStatus.networkStatus === PlasmaNM.NetworkStatus.Active ? i18n("Wi-Fi: Connected") : i18n("Wi-Fi: Off");
        parts.push(wifiPart);
        var btPart = btManager.bluetoothOperational ? i18n("BT: On") : i18n("BT: Off");
        parts.push(btPart);
        if (batteryControl.hasBatteries)
            parts.push(batteryControl.percent + "%");
        if (Funcs.checkInhibition(notificationSettings))
            parts.push(i18n("DnD on"));
        return parts.join(" \u00B7 ");
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        mainText: compact.tooltipMain
        subText: ""
        textFormat: Text.PlainText
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22

            Kirigami.Icon {
                width: 22; height: 22
                anchors.centerIn: parent
                source: connectionIcon.connectionIcon
            }
        }

        Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22

            Kirigami.Icon {
                width: 22; height: 22
                anchors.centerIn: parent
                source: Funcs.volIconName(compact.sinkAvailable ? compact.sink.volume : 0, compact.sinkAvailable ? compact.sink.muted : true)
                color: Kirigami.Theme.textColor
                isMask: true
            }
        }

        Item {
            visible: btManager.bluetoothOperational
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22

            Kirigami.Icon {
                width: 22; height: 22
                anchors.centerIn: parent
                source: "network-bluetooth-symbolic"
                color: Kirigami.Theme.textColor
                isMask: true
            }
        }

        Item {
            visible: Funcs.checkInhibition(notificationSettings)
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22

            Kirigami.Icon {
                width: 22; height: 22
                anchors.centerIn: parent
                source: "notifications-disabled"
                color: Kirigami.Theme.textColor
                isMask: true
            }
        }
    }

    WheelHandler {
        orientation: Qt.Vertical
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (wheel) {
            if (!compact.sinkAvailable)
                return;
            const delta = wheel.angleDelta.y;
            const step = Math.round(65536 / 100);
            var vol = compact.sink.volume;
            if (delta > 0)
                vol = Math.min(65536, vol + step);
            else if (delta < 0)
                vol = Math.max(0, vol - step);
            compact.sink.volume = vol;
            compact.sink.muted = vol === 0;
        }
    }
}
