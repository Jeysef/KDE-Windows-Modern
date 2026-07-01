/***************************************************************************
 *   Ported from com.jeysef.windowsmodernstartmenu
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 ***************************************************************************/

import QtQuick

import org.kde.plasma.plasmoid

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3

import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.ksvg as KSvg

PlasmoidItem {

    id: kicker

    anchors.fill: parent

    signal reset

    preferredRepresentation: compactRep
    compactRepresentation: compactRep
    fullRepresentation: compactRep

    property Item dragSource: null
    property string searchRunnerFilter: "all"

    function action_menuedit() {
        processRunner.runMenuEditor();
    }

    Component {
        id: compactRep
        CompactRepresentation {}
    }

    property QtObject globalFavorites: rootModel.favoritesModel
    property QtObject systemFavorites: rootModel.systemFavoritesModel

    Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon

    onSystemFavoritesChanged: {
        if (systemFavorites) {
            systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
        }
    }

    Kicker.RootModel {
        id: rootModel

        autoPopulate: false

        appNameFormat: 0
        flat: true
        sorted: true
        showAllAppsCategorized: false
        showSeparators: false
        appletInterface: kicker
        showAllApps: true
        showRecentApps: Plasmoid.configuration.showRecentApps
        showRecentDocs: Plasmoid.configuration.showRecentDocs
        showPowerSession: false

        onShowRecentAppsChanged: {
            Plasmoid.configuration.showRecentApps = showRecentApps;
        }

        onShowRecentDocsChanged: {
            Plasmoid.configuration.showRecentDocs = showRecentDocs;
        }

        Component.onCompleted: {
            favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)

            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favoriteApps);
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true;
            }
        }
    }

    Connections {
        target: globalFavorites

        function onFavoritesChanged() {
            Plasmoid.configuration.favoriteApps = target.favorites;
        }
    }

    Connections {
        target: systemFavorites

        function onFavoritesChanged() {
            if (Plasmoid.configuration && target)
                Plasmoid.configuration.favoriteSystemActions = target.favorites;
        }
    }

    Kicker.RootModel {
        id: categoryRootModel

        autoPopulate: false
        appNameFormat: 0
        flat: false
        sorted: true
        showSeparators: false
        showAllApps: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
    }

    Connections {
        target: Plasmoid.configuration

        function onFavoriteAppsChanged () {
            globalFavorites.favorites = Plasmoid.configuration.favoriteApps;
        }

        function onFavoriteSystemActionsChanged () {
            systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
        }

        function onHiddenApplicationsChanged(){
            rootModel.refresh();
            categoryRootModel.refresh();
        }
    }

    Kicker.RunnerModel {
         id: runnerModel

         appletInterface: kicker

         favoritesModel: globalFavorites

         runners: {
             const blacklist = ["krunner_webshortcuts", "webshortcuts"];
             function clean(list) {
                 return list.filter(function(r) { return blacklist.indexOf(r) === -1; });
             }
             if (kicker.searchRunnerFilter === "apps")
                 return ["krunner_services"];
             if (kicker.searchRunnerFilter === "files")
                 return ["baloosearch", "bookmarks"];
             if (kicker.searchRunnerFilter === "settings")
                 return ["krunner_systemsettings"];
             if (kicker.searchRunnerFilter === "actions")
                 return ["krunner_sessions", "krunner_powerdevil", "calculator", "unitconverter"];

             const results = ["krunner_services",
                               "krunner_systemsettings",
                               "krunner_sessions",
                               "krunner_powerdevil",
                               "calculator",
                               "unitconverter"];
             return results;
         }
     }

    Kicker.DragHelper {
        id: dragHelper
    }

    Kicker.ProcessRunner {
        id: processRunner;
    }

    Kicker.WindowSystem {
        id: windowSystem
    }

    KSvg.FrameSvgItem {
        id : panelSvg

        visible: false

        imagePath: "widgets/panel-background"
    }

    PlasmaComponents3.Label {
        id: toolTipDelegate

        width: contentWidth
        height: undefined

        property Item toolTip

        text: toolTip ? toolTip.text : ""
        textFormat: Text.PlainText
    }

    function resetDragSource() {
        dragSource = null;
    }

    function enableHideOnWindowDeactivate() {
        kicker.hideOnWindowDeactivate = true;
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Applications…")
            icon.name: "kmenuedit"
            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
            onTriggered: processRunner.runMenuEditor()
        }
    ]

    Component.onCompleted: {
        if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            Plasmoid.activationTogglesExpanded = !kicker.isDash
        }

        windowSystem.focusIn.connect(enableHideOnWindowDeactivate);
        kicker.hideOnWindowDeactivate = true;

        dragHelper.dropped.connect(resetDragSource);
    }
}
