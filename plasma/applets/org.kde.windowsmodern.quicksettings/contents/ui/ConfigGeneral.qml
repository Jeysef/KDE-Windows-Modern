import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

ColumnLayout {
    spacing: Kirigami.Units.largeSpacing

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Scale:")
        }

        PlasmaComponents3.SpinBox {
            from: 80
            to: 150
            value: Plasmoid.configuration.scale
            onValueModified: Plasmoid.configuration.scale = value
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Show Wi-Fi:")
        }

        PlasmaComponents3.Switch {
            checked: true
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Show Bluetooth:")
        }

        PlasmaComponents3.Switch {
            checked: true
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Show Airplane Mode:")
        }

        PlasmaComponents3.Switch {
            checked: Plasmoid.configuration.showAirplane
            onToggled: Plasmoid.configuration.showAirplane = checked
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Show Battery Saver:")
        }

        PlasmaComponents3.Switch {
            checked: Plasmoid.configuration.showBatterySaver
            onToggled: Plasmoid.configuration.showBatterySaver = checked
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Show Night Light:")
        }

        PlasmaComponents3.Switch {
            checked: Plasmoid.configuration.showNightLight
            onToggled: Plasmoid.configuration.showNightLight = checked
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Show Color Scheme:")
        }

        PlasmaComponents3.Switch {
            checked: Plasmoid.configuration.showColorScheme
            onToggled: Plasmoid.configuration.showColorScheme = checked
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Show Do Not Disturb:")
        }

        PlasmaComponents3.Switch {
            checked: Plasmoid.configuration.showDnd
            onToggled: Plasmoid.configuration.showDnd = checked
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Show Inhibit Sleep:")
        }

        PlasmaComponents3.Switch {
            checked: Plasmoid.configuration.showInhibitSleep
            onToggled: Plasmoid.configuration.showInhibitSleep = checked
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Show Microphone:")
        }

        PlasmaComponents3.Switch {
            checked: Plasmoid.configuration.showMicMute
            onToggled: Plasmoid.configuration.showMicMute = checked
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            text: i18n("Dark theme:")
            Layout.minimumWidth: 80
        }

        PlasmaComponents3.TextField {
            Layout.fillWidth: true
            text: Plasmoid.configuration.darkTheme
            onTextChanged: Plasmoid.configuration.darkTheme = text
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            text: i18n("Light theme:")
            Layout.minimumWidth: 80
        }

        PlasmaComponents3.TextField {
            Layout.fillWidth: true
            text: Plasmoid.configuration.lightTheme
            onTextChanged: Plasmoid.configuration.lightTheme = text
        }
    }
}
