// Live network icon (the same icon the tray's network applet shows).
// Loaded through a Loader: if plasma-nm is missing, only this icon goes.
import QtQuick
import org.kde.plasma.networkmanagement as PlasmaNM

StatusIconButton {
    PlasmaNM.ConnectionIcon {
        id: connection
    }
    icon.name: connection.connectionIcon || "network-disconnect"
    text: i18nd("plasma_shell_org.kde.plasma.desktop", "Network")
}
