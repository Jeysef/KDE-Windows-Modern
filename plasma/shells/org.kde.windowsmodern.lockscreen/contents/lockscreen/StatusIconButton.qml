// A white, icon-only button for the lock screen's status row.
import QtQuick
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmaComponents3.ToolButton {
    width: 32
    height: 32
    icon.color: "#FFFFFF"
    display: AbstractButton.IconOnly
    flat: true
    focusPolicy: Qt.NoFocus
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Accessible.name: text
    PlasmaComponents3.ToolTip.text: text
    PlasmaComponents3.ToolTip.visible: hovered && text.length > 0
    PlasmaComponents3.ToolTip.delay: 500
}
