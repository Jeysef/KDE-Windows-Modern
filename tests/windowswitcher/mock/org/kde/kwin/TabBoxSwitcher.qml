// Mock of KWin.TabBoxSwitcher: the object KWin hands to a switcher layout.
import QtQuick

Item {
    property var model
    property int currentIndex: 0
    property rect screenGeometry: Qt.rect(0, 0, 1920, 1080)
    visible: false
}
