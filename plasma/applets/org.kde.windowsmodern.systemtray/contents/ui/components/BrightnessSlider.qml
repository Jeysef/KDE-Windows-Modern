import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.brightnesscontrolplugin
import org.kde.kitemmodels as KItemModels
import "../lib" as Lib

Lib.Slider {
    id: root

    property var mainScreen: null
    property rect panelScreenGeometry: Qt.rect(0, 0, 0, 0)
    property int panelScreenIndex: -1

    iconSource: "brightness-high-symbolic"
    iconSize: Kirigami.Units.iconSizes.smallMedium
    showArrow: true

    ScreenBrightnessControl {
        id: sbControl
        isSilent: false
    }

    function displayForPanel() {
        const model = sbControl.displays;
        if (!model || model.rowCount() === 0) {
            return null;
        }
        if (model.rowCount() === 1) {
            return model.index(0, 0);
        }

        // Match panel screen geometry to a QScreen, then match QScreen name
        // to the backend displayName. Some Qt/Plasma versions do not expose
        // QScreen::geometry to QML, so guard every access and fall back to
        // internal/first display if geometry matching is unavailable.
        const panelRect = root.panelScreenGeometry;
        const screens = Qt.application.screens;
        let matchedScreen = null;
        if (screens && screens.length > 0 && panelRect.width > 0 && panelRect.height > 0) {
            for (let i = 0; i < screens.length; ++i) {
                const s = screens[i];
                if (!s) {
                    continue;
                }
                const geom = s.geometry || s.virtualGeometry;
                if (!geom) {
                    continue;
                }
                if (Math.round(geom.x) === Math.round(panelRect.x) &&
                    Math.round(geom.y) === Math.round(panelRect.y) &&
                    Math.round(geom.width) === Math.round(panelRect.width) &&
                    Math.round(geom.height) === Math.round(panelRect.height)) {
                    matchedScreen = s;
                    break;
                }
            }
        }

        if (!matchedScreen && root.panelScreenIndex >= 0 && screens.length > root.panelScreenIndex) {
            const s = screens[root.panelScreenIndex];
            if (s && s.name) {
                matchedScreen = s;
            }
        }

        if (matchedScreen && matchedScreen.name) {
            const displayNameRole = model.KItemModels.KRoleNames.role("displayName");
            for (let i = 0; i < model.rowCount(); ++i) {
                const idx = model.index(i, 0);
                if (model.data(idx, displayNameRole) === matchedScreen.name) {
                    return idx;
                }
            }
        }

        // Fallback to the internal display (e.g. laptop panel)
        const isInternalRole = model.KItemModels.KRoleNames.role("isInternal");
        for (let i = 0; i < model.rowCount(); ++i) {
            const idx = model.index(i, 0);
            if (model.data(idx, isInternalRole)) {
                return idx;
            }
        }

        // Final fallback to the first display
        return model.index(0, 0);
    }

    function refreshDisplays() {
        const model = sbControl.displays;
        const idx = root.displayForPanel();
        if (!model || !idx) {
            root.mainScreen = null;
            return;
        }
        const labelRole = model.KItemModels.KRoleNames.role("label");
        const brightnessRole = model.KItemModels.KRoleNames.role("brightness");
        const maxBrightnessRole = model.KItemModels.KRoleNames.role("maxBrightness");
        const displayNameRole = model.KItemModels.KRoleNames.role("displayName");
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

    onPanelScreenGeometryChanged: root.refreshDisplays()
    onPanelScreenIndexChanged: root.refreshDisplays()

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
