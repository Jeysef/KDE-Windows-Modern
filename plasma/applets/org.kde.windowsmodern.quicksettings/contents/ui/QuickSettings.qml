import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.private.battery
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

    BatteryControlModel { id: batteryControl }

    StackView {
        id: pageStack
        anchors.fill: parent
        anchors.topMargin: 14 * flyout.scale
        anchors.leftMargin: 14 * flyout.scale
        anchors.rightMargin: 14 * flyout.scale
        anchors.bottomMargin: pageStack.depth > 1
            ? 0
            : (14 * flyout.scale + footer.implicitHeight)
        clip: true
        initialItem: mainPage
    }

    Components.Footer {
        id: footer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        anchors.bottomMargin: -8
        scale: flyout.scale
        showBattery: Plasmoid.configuration.showBattery
        hasBattery: batteryControl.hasBatteries
        visible: pageStack.depth === 1
    }

    Component {
        id: mainPage

        MainPage {
            scale: flyout.scale
            onPushPage: function(name) {
                pageStack.push(pageMap[name])
            }
        }
    }

    property var pageMap: ({
        "network": networkPage,
        "bluetooth": bluetoothPage,
        "volume": volumePage
    })

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

    Component {
        id: volumePage

        Components.VolumePage {
            anchors.fill: parent
            onBack: pageStack.pop()
        }
    }
}
