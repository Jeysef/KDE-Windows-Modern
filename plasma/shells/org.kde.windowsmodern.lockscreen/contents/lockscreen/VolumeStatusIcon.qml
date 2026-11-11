// Live volume icon: muted / low / medium / high, as in the tray.
// Loaded through a Loader: if plasma-pa is missing, only this icon goes.
import QtQuick
import org.kde.plasma.private.volume

StatusIconButton {
    // PulseAudio's 100 % (PA_VOLUME_NORM); not exposed to QML here.
    readonly property int normalVolume: 0x10000
    readonly property var sink: PreferredDevice.sink
    readonly property real level: sink ? sink.volume / normalVolume : 0
    readonly property bool muted: !sink || sink.muted || level <= 0

    visible: sink !== null
    icon.name: muted ? "audio-volume-muted"
             : level <= 0.25 ? "audio-volume-low"
             : level <= 0.75 ? "audio-volume-medium" : "audio-volume-high"
    text: muted ? i18nd("plasma_shell_org.kde.plasma.desktop", "Volume: muted")
                : i18nd("plasma_shell_org.kde.plasma.desktop", "Volume: %1%", Math.round(level * 100))
}
