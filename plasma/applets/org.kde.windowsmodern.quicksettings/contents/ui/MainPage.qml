import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import "components" as Components

ColumnLayout {
    id: content

    property real scale: 1

    signal pushPage(string name)

    anchors.fill: parent
    spacing: 16 * content.scale

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: 12 * content.scale
        columnSpacing: 6 * content.scale

        Components.NetworkToggle {
            Layout.fillWidth: true
            onArrowClicked: content.pushPage("network")
        }

        Components.BluetoothToggle {
            Layout.fillWidth: true
            onArrowClicked: content.pushPage("bluetooth")
        }

        Components.AirplaneToggle {
            Layout.fillWidth: true
            visible: Plasmoid.configuration.showAirplane
        }

        Components.BatterySaverToggle {
            Layout.fillWidth: true
            visible: Plasmoid.configuration.showBatterySaver
        }

        Components.NightLightToggle {
            Layout.fillWidth: true
            visible: Plasmoid.configuration.showNightLight
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: 12 * content.scale
        columnSpacing: 0

        Components.BrightnessSlider {
            Layout.fillWidth: true
            Layout.columnSpan: 3
            Layout.preferredHeight: 36
            visible: Plasmoid.configuration.showBrightness
        }

        Components.VolumeSlider {
            Layout.fillWidth: true
            Layout.columnSpan: 3
            Layout.preferredHeight: 36
            visible: Plasmoid.configuration.showVolume
            onArrowClicked: content.pushPage("volume")
        }
    }

    Item { Layout.fillHeight: true }
}
