import QtQuick
import org.kde.plasma.private.volume as Vol
import org.kde.kcmutils
import "../lib" as Lib
import "../js/funcs.js" as Funcs

Lib.Slider {
    id: root

    property var sink: Vol.PreferredDevice.sink
    readonly property bool sinkAvailable: sink && !(sink.name === "auto_null")

    iconSource: Funcs.volIconName(sinkAvailable ? sink.volume : 0, sinkAvailable ? sink.muted : true)
    showArrow: true

    visible: sinkAvailable
    from: 0
    to: 65536
    value: sinkAvailable ? sink.volume : 0
    stepSize: Math.round(65536 / 100)

    onMoved: function (v) {
        sink.volume = v;
        sink.muted = v === 0;
    }

    onArrowClicked: KCMLauncher.openSystemSettings("kcm_pulseaudio")
}
