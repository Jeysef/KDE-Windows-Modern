// Network, volume and battery, kept up to date (they were fixed icons).
// Each icon is loaded separately so a missing Plasma module can only hide
// that icon, never break the lock screen.
import QtQuick

Row {
    spacing: 4
    Loader { source: "NetworkStatusIcon.qml"; anchors.verticalCenter: parent.verticalCenter }
    Loader { source: "VolumeStatusIcon.qml"; anchors.verticalCenter: parent.verticalCenter }
    Loader { source: "BatteryStatusIcon.qml"; anchors.verticalCenter: parent.verticalCenter }
}
