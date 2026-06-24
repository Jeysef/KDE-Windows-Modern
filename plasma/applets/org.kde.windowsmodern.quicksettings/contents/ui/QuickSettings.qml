import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils
import "lib" as Lib
import "components" as Components

Item {
    id: flyout

    readonly property real scale: Plasmoid.configuration.scale / 100

    Layout.preferredWidth: 360 * scale
    Layout.minimumWidth: Layout.preferredWidth
    Layout.maximumWidth: Layout.preferredWidth
    Layout.preferredHeight: 400 * scale
    Layout.minimumHeight: Layout.preferredHeight
    Layout.maximumHeight: Layout.preferredHeight

    StackView {
        id: pageStack
        anchors.fill: parent
        initialItem: mainPage
        clip: true
    }

    Component {
        id: mainPage

        ColumnLayout {
            id: content
            anchors.fill: parent
            spacing: 0

            ColumnLayout {
                id: mainContent
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 14 * flyout.scale
                spacing: 16 * flyout.scale

                GridLayout {
                    id: toggleGrid
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 12 * flyout.scale
                    columnSpacing: 6 * flyout.scale

                    Components.NetworkToggle {
                        Layout.fillWidth: true
                        onArrowClicked: pageStack.push(networkPage)
                    }

                    Components.BluetoothToggle {
                        Layout.fillWidth: true
                        onArrowClicked: pageStack.push(bluetoothPage)
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

                Components.BrightnessSlider {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    visible: Plasmoid.configuration.showBrightness
                }

                Components.VolumeSlider {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    visible: Plasmoid.configuration.showVolume
                }

                Item { Layout.fillHeight: true }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36 * flyout.scale
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03)

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: 14 * flyout.scale
                    anchors.rightMargin: 14 * flyout.scale

                    Components.Battery {
                        id: battery
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        height: 16
                        visible: Plasmoid.configuration.showBattery && battery.hasBattery
                    }

                    Kirigami.Icon {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        source: "configure"
                        color: Kirigami.Theme.textColor
                        isMask: true
                        opacity: 0.7

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: KCMLauncher.openSystemSettings("")
                        }
                    }
                }
            }
        }
    }

    Component {
        id: networkPage

        Components.NetworkPage {
            anchors.fill: parent
            onBack: pageStack.pop()
        }
    }

    Component {
        id: bluetoothPage

        Components.BluetoothPage {
            anchors.fill: parent
            onBack: pageStack.pop()
        }
    }
}
