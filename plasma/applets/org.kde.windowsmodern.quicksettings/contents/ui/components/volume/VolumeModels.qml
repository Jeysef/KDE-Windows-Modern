import QtQuick
import org.kde.plasma.private.volume as Vol

QtObject {
    id: root

    readonly property var sink: Vol.PreferredDevice.sink
    readonly property bool sinkAvailable: sink && !(sink.name === "auto_null")

    readonly property var sinkFilterModel: Vol.PulseObjectFilterModel {
        sourceModel: Vol.SinkModel {}
        filterOutInactiveDevices: true
    }

    readonly property var sinkInputFilterModel: Vol.PulseObjectFilterModel {
        sourceModel: Vol.SinkInputModel {}
        filters: [{ role: "VirtualStream", value: false }]
    }

    readonly property var feedback: Vol.VolumeFeedback {}

    function playFeedback(sinkIndex) {
        feedback.play(sinkIndex)
    }

    function setDefaultSink(pulseObject) {
        pulseObject.default = true
    }
}
