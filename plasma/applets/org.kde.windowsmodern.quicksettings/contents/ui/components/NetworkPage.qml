import QtQuick
import QtQuick.Layouts
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import "../lib" as Lib

Lib.DetailPage {
    id: page

    title: qsTr("Wi-Fi")
    switchChecked: page.wifiOn
    emptyText: page.wifiOn ? qsTr("No available networks") : qsTr("Wi-Fi is off")

    PlasmaNM.Handler { id: handler }
    PlasmaNM.NetworkStatus { id: netStatus }
    PlasmaNM.AvailableDevices { id: availableDevices }
    PlasmaNM.EnabledConnections { id: enabledConnections }

    PlasmaNM.AppletProxyModel {
        id: appletProxyModel
        sourceModel: PlasmaNM.NetworkModel {}
    }

    readonly property bool wifiAvailable: availableDevices.wirelessDeviceAvailable
    readonly property bool wifiOn: wifiAvailable && enabledConnections.wirelessEnabled

    onSwitchToggled: {
        if (wifiAvailable) {
            handler.enableWireless(!wifiOn);
        }
    }

    listView.model: appletProxyModel
    listView.delegate: Item {
        width: listView.width
        height: 34

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 4
            color: ma.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08) : "transparent"

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (ConnectionState === PlasmaNM.Enums.Deactivated) {
                        handler.activateConnection(ConnectionPath, DevicePath, SpecificPath);
                    } else {
                        handler.deactivateConnection(ConnectionPath, DevicePath);
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Kirigami.Icon {
                    width: 16
                    height: 16
                    source: model.ConnectionIcon
                    color: Kirigami.Theme.textColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: model.ItemUniqueName
                        color: Kirigami.Theme.textColor
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    PlasmaComponents3.Label {
                        visible: ConnectionState === PlasmaNM.Enums.Activated
                        text: qsTr("Connected, secured")
                        color: Kirigami.Theme.textColor
                        opacity: 0.5
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}
