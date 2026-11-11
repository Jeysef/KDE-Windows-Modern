// Mock of KWin.WindowThumbnail for previews. wId is "<width>x<height>:<color>";
// the implicit size reports the window's aspect ratio like the real item.
import QtQuick

Rectangle {
    property string wId
    readonly property var parts: wId.split(":")
    implicitWidth: parseInt(parts[0].split("x")[0])
    implicitHeight: parseInt(parts[0].split("x")[1])
    gradient: Gradient {
        GradientStop { position: 0; color: parts[1] }
        GradientStop { position: 1; color: Qt.darker(parts[1], 1.8) }
    }
    // A lighter strip standing in for the window's title bar.
    Rectangle { width: parent.width; height: Math.max(6, parent.height * 0.08); color: Qt.lighter(parts[1], 1.3) }
}
