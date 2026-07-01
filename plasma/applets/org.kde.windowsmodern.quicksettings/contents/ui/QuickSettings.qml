import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.private.battery
import org.kde.kirigami as Kirigami
import "components" as Components

Item {
    id: flyout

    focus: true
    Keys.onEscapePressed: {
        if (pageStack.depth > 1)
            pageStack.pop();
        else
            root.expanded = false;
    }

    onVisibleChanged: {
        if (visible && pageStack.depth > 1)
            pageStack.pop(pageStack.get(0));
    }

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded && pageStack.depth > 1)
                pageStack.pop(pageStack.get(0));
        }
    }

    readonly property real scale: Plasmoid.configuration.scale / 100

    Layout.preferredWidth: 360 * scale
    Layout.minimumWidth: Layout.preferredWidth
    Layout.maximumWidth: Layout.preferredWidth
    Layout.preferredHeight: 400 * scale
    Layout.minimumHeight: Layout.preferredHeight
    Layout.maximumHeight: Layout.preferredHeight

    BatteryControlModel {
        id: batteryControl
    }

    StackView {
        id: pageStack
        anchors.fill: parent
        anchors.topMargin: 14 * flyout.scale
        anchors.leftMargin: 14 * flyout.scale
        anchors.rightMargin: 14 * flyout.scale
        anchors.bottomMargin: pageStack.depth > 1 ? (detailFooter.visible ? detailFooter.height : 0) : (8 * flyout.scale + footer.implicitHeight)
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
        onBatteryClicked: pageStack.push(pageMap["battery"])
    }

    Rectangle {
        id: detailFooter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        anchors.bottomMargin: -8
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.03)
        visible: pageStack.depth > 1 && pageStack.currentItem && pageStack.currentItem.footer !== null
        implicitHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0

        Loader {
            id: contentLoader
            anchors.fill: parent
            sourceComponent: pageStack.currentItem ? pageStack.currentItem.footer : null
        }
    }

    Component {
        id: mainPage

        MainPage {
            scale: flyout.scale
            onPushPage: function (name) {
                pageStack.push(pageMap[name]);
            }
        }
    }

    property var pageMap: ({
            "network": networkPage,
            "bluetooth": bluetoothPage,
            "volume": volumePage,
            "powerprofile": powerProfilePage,
            "battery": batteryPage,
            "brightness": brightnessPage
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

    Component {
        id: powerProfilePage

        Components.PowerProfilePage {
            anchors.fill: parent
            onBack: pageStack.pop()
        }
    }

    Component {
        id: batteryPage

        Components.BatteryPage {
            anchors.fill: parent
            onBack: pageStack.pop()
        }
    }

    Component {
        id: brightnessPage

        Components.BrightnessPage {
            anchors.fill: parent
            onBack: pageStack.pop()
        }
    }
}
