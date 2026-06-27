import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Item {
    id: root

    property string iconSource
    property int from: 0
    property int to: 100
    property int value: 0
    property int stepSize: 1
    property bool pressed: false
    property bool showArrow: false

    signal moved(int value)
    signal arrowClicked

    implicitHeight: 36

    GridLayout {
        anchors.fill: parent
        columns: 3
        columnSpacing: 12

        Kirigami.Icon {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            source: root.iconSource
            isMask: true
            color: Kirigami.Theme.textColor
        }

        PlasmaComponents3.Slider {
            id: slider
            Layout.fillWidth: true
            from: root.from
            to: root.to
            value: root.value
            stepSize: root.stepSize
            onMoved: root.moved(value)

            Binding { root.pressed: slider.pressed }
        }

        Item {
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter

            Kirigami.Icon {
                anchors.fill: parent
                visible: root.showArrow
                source: "go-next"
                isMask: true
                color: Kirigami.Theme.textColor
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: root.showArrow
                onClicked: root.arrowClicked()
            }
        }
    }

    WheelHandler {
        target: slider
        orientation: Qt.Vertical
        acceptedButtons: Qt.NoButton
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (wheel) {
            const delta = wheel.angleDelta.y;
            if (delta > 0) slider.increase();
            else if (delta < 0) slider.decrease();
            slider.moved();
        }
    }
}
