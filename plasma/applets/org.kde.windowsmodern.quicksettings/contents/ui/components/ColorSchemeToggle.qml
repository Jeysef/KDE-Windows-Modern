import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import "../lib" as Lib
import "../js/colorType.js" as ColorType

Lib.Tile {
    id: tile

    label: ColorType.isDark(Kirigami.Theme.backgroundColor) ? qsTr("Light Mode") : qsTr("Dark Mode")
    subLabel: ""
    iconSource: "color-mode"
    active: ColorType.isDark(Kirigami.Theme.backgroundColor)

    onClicked: {
        var dark = ColorType.isDark(Kirigami.Theme.backgroundColor);
        var target = dark ? Plasmoid.configuration.lightTheme : Plasmoid.configuration.darkTheme;
        executable.exec("plasma-apply-colorscheme \"" + target + "\"");
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: disconnectSource(sourceName)
        function exec(cmd) { connectSource(cmd) }
    }
}
