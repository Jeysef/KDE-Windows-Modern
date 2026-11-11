// Rendered by check-switch.py: every switch state on a plain background.
import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3

Rectangle {
    id: root

    readonly property var args: Qt.application.arguments
    property var plasmaTheme: PlasmaCore.Theme // loads the Plasma theme into KSvg

    width: 4 * 52 + 12
    height: 32
    color: args[args.length - 1]

    Row {
        x: 6
        y: 6
        spacing: 12
        PC3.Switch { focusPolicy: Qt.NoFocus; hoverEnabled: false; checked: false }
        PC3.Switch { focusPolicy: Qt.NoFocus; hoverEnabled: false; checked: true }
        PC3.Switch { focusPolicy: Qt.NoFocus; hoverEnabled: false; checked: false; down: true }
        PC3.Switch { focusPolicy: Qt.NoFocus; hoverEnabled: false; checked: true; down: true }
    }

    Timer {
        interval: 1200
        running: true
        onTriggered: root.grabToImage(result => {
            result.saveToFile(root.args[root.args.length - 2]);
            Qt.quit();
        })
    }
}
