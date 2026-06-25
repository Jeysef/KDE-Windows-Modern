import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    id: page

    property string title
    property bool switchChecked: false
    property alias listView: list
    property alias emptyText: emptyLabel.text

    signal back
    signal switchToggled

    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        Layout.bottomMargin: 8
        spacing: 6

        Item {
            width: 18
            height: 18
            Layout.alignment: Qt.AlignVCenter

            Kirigami.Icon {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: "go-previous"
                color: Kirigami.Theme.textColor
                isMask: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: page.back()
            }
        }

        PlasmaComponents3.Label {
            text: page.title
            color: Kirigami.Theme.textColor
            font.pixelSize: 12
            font.weight: Font.DemiBold
            Layout.fillWidth: true
        }

        PlasmaComponents3.Switch {
            checked: page.switchChecked
            onToggled: page.switchToggled()
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ListView {
            id: list
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds
        }
    }

    PlasmaComponents3.Label {
        id: emptyLabel
        anchors.centerIn: parent
        visible: list.count === 0
        color: Kirigami.Theme.textColor
        opacity: 0.5
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
    }
}
