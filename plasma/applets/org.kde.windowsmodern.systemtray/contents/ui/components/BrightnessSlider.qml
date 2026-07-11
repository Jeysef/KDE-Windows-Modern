import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.brightnesscontrolplugin
import org.kde.kitemmodels as KItemModels
import "../lib" as Lib

Lib.Slider {
    id: root

    property var mainScreen: null

    iconSource: "brightness-high-symbolic"
    iconSize: Kirigami.Units.iconSizes.smallMedium
    showArrow: true

    ScreenBrightnessControl {
        id: sbControl
        isSilent: false
    }

    function refreshDisplays() {
        const model = sbControl.displays;
        if (!model || model.rowCount() === 0) {
            root.mainScreen = null;
            return;
        }
        const labelRole = model.KItemModels.KRoleNames.role("label");
        const brightnessRole = model.KItemModels.KRoleNames.role("brightness");
        const maxBrightnessRole = model.KItemModels.KRoleNames.role("maxBrightness");
        const displayNameRole = model.KItemModels.KRoleNames.role("displayName");
        const idx = model.index(0, 0);
        root.mainScreen = {
            displayName: model.data(idx, displayNameRole),
            label: model.data(idx, labelRole),
            brightness: model.data(idx, brightnessRole),
            maxBrightness: model.data(idx, maxBrightnessRole)
        };
    }

    Connections {
        target: sbControl.displays
        function onDataChanged() {
            root.refreshDisplays();
        }
        function onModelReset() {
            root.refreshDisplays();
        }
        function onRowsInserted() {
            root.refreshDisplays();
        }
        function onRowsRemoved() {
            root.refreshDisplays();
        }
    }

    Component.onCompleted: root.refreshDisplays()

    visible: sbControl.isBrightnessAvailable && mainScreen !== null
    from: mainScreen ? (mainScreen.maxBrightness > 100 ? 1 : 0) : 0
    to: mainScreen ? mainScreen.maxBrightness : 100
    value: mainScreen ? mainScreen.brightness : 0
    stepSize: mainScreen ? Math.max(1, Math.floor(mainScreen.maxBrightness / 100)) : 1

    onMoved: function (v) {
        if (mainScreen) {
            sbControl.setBrightness(mainScreen.displayName, v);
        }
    }

    onIconClicked: NightLightInhibitor.toggleInhibition()
}
