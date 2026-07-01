/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   StartAllBack-style two-column start menu shell:
 *     ┌──────────────────────────────┬─────────────────┐
 *     │  Pinned / All apps (left)    │  User avatar    │
 *     │                              ├─────────────────┤
 *     │  vertical list of apps       │  System         │
 *     │                              │  locations      │
 *     ├──────────────────────────────┴─────────────────┤
 *     │  [Search programs and files...]  [Shut down >] │
 *     └────────────────────────────────────────────────┘
 *
 *   Pages live in pages/, shared components in components/.
 *   Positioning matches working Start.Next.Menu pattern.
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.kicker 0.1 as Kicker

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.coreaddons as KCoreAddons

import "components"
import "pages"

Item {
    id: main

    onVisibleChanged: {
        root.visible = !root.visible
    }

    Plasmoid.status: root.visible ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.PassiveStatus

    PlasmaCore.Dialog {
        id: root

        objectName: "popupWindow"
        flags: Qt.WindowStaysOnTopHint
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: true

        property int iconSize: {
            switch (Plasmoid.configuration.appsIconSize) {
            case 0: return Kirigami.Units.iconSizes.smallMedium;
            case 1: return Kirigami.Units.iconSizes.medium;
            case 2: return Kirigami.Units.iconSizes.large;
            case 3: return Kirigami.Units.iconSizes.huge;
            default: return Kirigami.Units.iconSizes.medium;
            }
        }

        property int docsIconSize: {
            switch (Plasmoid.configuration.docsIconSize) {
            case 0: return Kirigami.Units.iconSizes.smallMedium;
            case 1: return Kirigami.Units.iconSizes.medium;
            case 2: return Kirigami.Units.iconSizes.large;
            case 3: return Kirigami.Units.iconSizes.huge;
            default: return Kirigami.Units.iconSizes.medium;
            }
        }

        property bool searching: (bottomBarContent.searchText != "")

        // Left-column state: 0 = pinned, 1 = all apps, 2 = search results
        property int leftColumnState: 0

        onSearchingChanged: {
            if (searching) {
                leftColumnState = 2;
                kicker.searchRunnerFilter = "all";
                // Reset scroll position when entering search mode.
                searchPage.resultsView.contentY = 0;
                searchPage.resultsView.currentIndex = 0;
            } else {
                leftColumnState = 0;
            }
        }

        onVisibleChanged: {
            if (visible) {
                var pos = popupPosition(width, height);
                x = pos.x;
                y = pos.y;
                reset();
            } else {
                leftColumnState = 0;
            }
        }

        onHeightChanged: {
            if (visible) {
                var pos = popupPosition(width, height);
                x = pos.x;
                y = pos.y;
            }
        }

        onWidthChanged: {
            if (visible) {
                var pos = popupPosition(width, height);
                x = pos.x;
                y = pos.y;
            }
        }

        function toggle() {
            main.visible = !main.visible
        }

        function reset() {
            bottomBarContent.searchText = "";
            bottomBarContent.focusSearch();
            leftColumnState = 0;
            kicker.searchRunnerFilter = "all";
        }

        function closeMenu() {
            root.visible = false;
        }

        function popupPosition(width, height) {
            var screenAvail = kicker.availableScreenRect;
            var screen = kicker.screenGeometry;
            var appletTopLeft = parent.mapToGlobal(0, 0);
            var horizMidPoint = screen.x + (screen.width / 2);
            var vertMidPoint = screen.y + (screen.height / 2);
            var offset = Kirigami.Units.smallSpacing;

            var menuPos = Plasmoid.configuration.displayPosition;

            if (menuPos === 1) {
                // Center of screen
                return Qt.point(horizMidPoint - width / 2, vertMidPoint - height / 2);
            } else if (menuPos === 2) {
                // Center-bottom (above panel)
                return Qt.point(horizMidPoint - width / 2,
                                screenAvail.y + screenAvail.height - height - offset);
            } else if (menuPos === 3) {
                // Left-bottom (above panel, left-aligned)
                return Qt.point(screen.x + offset,
                                screenAvail.y + screenAvail.height - height - offset);
            } else {
                // menuPos 0 — follow panel: center horizontally over the
                // start button, sit flush against the panel edge.
                var centerX = appletTopLeft.x + (kicker.width / 2) - (width / 2);
                centerX = Math.max(screen.x + offset,
                                   Math.min(centerX, screen.x + screen.width - width - offset));
                switch (plasmoid.location) {
                case PlasmaCore.Types.BottomEdge:
                    return Qt.point(centerX, screenAvail.y + screenAvail.height - height - offset);
                case PlasmaCore.Types.TopEdge:
                    return Qt.point(centerX, screen.y + kicker.height + offset);
                case PlasmaCore.Types.LeftEdge:
                    return Qt.point(appletTopLeft.x + kicker.width + offset,
                                    Math.max(screen.y + offset,
                                             Math.min(appletTopLeft.y + (kicker.height / 2) - (height / 2),
                                                      screen.y + screen.height - height - offset)));
                case PlasmaCore.Types.RightEdge:
                    return Qt.point(appletTopLeft.x - width - offset,
                                    Math.max(screen.y + offset,
                                             Math.min(appletTopLeft.y + (kicker.height / 2) - (height / 2),
                                                      screen.y + screen.height - height - offset)));
                default:
                    return Qt.point(centerX, screenAvail.y + screenAvail.height - height - offset);
                }
            }
        }

        FocusScope {
            id: rootItem

            readonly property int leftColumnWidth: Kirigami.Units.gridUnit * 14
            readonly property int rightColumnWidth: Kirigami.Units.gridUnit * 10
            // Height derived from ~10 list rows + header + padding rather
            // than a fixed grid-unit count.
            readonly property int rowHeight: Kirigami.Units.gridUnit * 2
            readonly property int mainContentHeight: rowHeight * 12 + Kirigami.Units.gridUnit * 2

            Layout.minimumWidth: leftColumnWidth + rightColumnWidth + Kirigami.Units.gridUnit * 3
            Layout.maximumWidth: Layout.minimumWidth
            Layout.minimumHeight: mainContentHeight + bottomBar.height + Kirigami.Units.gridUnit * 3
            Layout.maximumHeight: Layout.minimumHeight

            focus: true
            onFocusChanged: if (focus) bottomBarContent.focusSearch()

            Plasma5Support.DataSource {
                id: executable
                engine: "executable"
                connectedSources: []

                onNewData: function (source, data) {
                    disconnectSource(source);
                }

                function exec(cmd) {
                    connectSource(cmd);
                }
            }

            KCoreAddons.KUser { id: kuser }

            KItemModels.KSortFilterProxyModel {
                id: sortedAppsModel

                sortRoleName: {
                    var m = Plasmoid.configuration.allAppsSortMode;
                    if (m === 4) return "description";
                    if (m === 2 || m === 3) return "url";
                    return "display";
                }
                sortOrder: {
                    var m = Plasmoid.configuration.allAppsSortMode;
                    return (m === 1 || m === 3) ? Qt.DescendingOrder : Qt.AscendingOrder;
                }

                property var favoritesModel: sourceModel ? sourceModel.favoritesModel : null
            }

            // ── Two-column main content area ──────────────────────────────
            RowLayout {
                id: mainColumns
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: bottomBar.top
                anchors.topMargin: Kirigami.Units.gridUnit
                anchors.bottomMargin: Kirigami.Units.gridUnit
                anchors.leftMargin: Kirigami.Units.gridUnit
                anchors.rightMargin: Kirigami.Units.gridUnit
                spacing: 0

                // ── Left column: pinned / all-apps / search ─────────────────
                ColumnLayout {
                    id: leftColumn
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: rootItem.leftColumnWidth
                    Layout.rightMargin: Kirigami.Units.mediumSpacing
                    spacing: Kirigami.Units.smallSpacing

                    PinnedPage {
                        id: pinnedPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.leftColumnState === 0
                        onShowAllAppsRequested: {
                            root.leftColumnState = 1;
                            allAppsPage.tryActivate(0);
                        }
                        onKeyNavUpFromList: bottomBarContent.focusSearch()
                    }

                    AllAppsPage {
                        id: allAppsPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.leftColumnState === 1
                        onBackRequested: {
                            root.leftColumnState = 0;
                            pinnedPage.tryActivate(0);
                        }
                        onKeyNavUpFromList: bottomBarContent.focusSearch()
                    }

                    SearchPage {
                        id: searchPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.leftColumnState === 2
                    }
                }

                // ── Vertical separator ───────────────────────────────────────
                Rectangle {
                    id: columnSeparator
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Kirigami.Theme.textColor
                    opacity: 0.12
                }

                // ── Right column: avatar + system locations ────────────────
                ColumnLayout {
                    id: rightColumn
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: rootItem.rightColumnWidth
                    Layout.rightMargin: Kirigami.Units.mediumSpacing
                    spacing: Kirigami.Units.smallSpacing
                    visible: Plasmoid.configuration.showRightColumn

                    // ── User avatar (circular) ──────────────────────────────
                    Item {
                        id: avatarArea
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                        width: Kirigami.Units.iconSizes.medium
                        height: width

                        Image {
                            id: userAvatar
                            anchors.fill: parent
                            source: {
                                var faceUrl = kuser.faceIconUrl.toString()
                                if (faceUrl !== "") return faceUrl
                                return "file://usr/share/icons/breeze/apps/48/kuser.svg"
                            }
                            cache: false
                            fillMode: Image.PreserveAspectCrop
                            visible: source !== ""
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: avatarArea.width
                                    height: avatarArea.height
                                    radius: avatarArea.width / 2
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                                   Kirigami.Theme.textColor.g,
                                                   Kirigami.Theme.textColor.b, 0.15)
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: executable.exec("systemsettings kcm_users")
                        }
                    }

                    PlasmaComponents3.Label {
                        text: i18n("Places")
                        color: Kirigami.Theme.textColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
                        font.weight: Font.DemiBold
                        font.family: "Segoe UI"
                        Layout.leftMargin: Kirigami.Units.largeSpacing
                    }

                    SystemLocationsColumn {
                        id: systemLocations
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        executable: executable
                    }
                }
            }

            // ── Compound bottom bar: [Search field] + [Shut down >] ────────
            Rectangle {
                id: bottomBar
                width: parent.width
                height: bottomBarContent.implicitHeight + Kirigami.Units.gridUnit
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Kirigami.Units.gridUnit
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.gridUnit
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.gridUnit
                Kirigami.Theme.colorSet: Kirigami.Theme.Header
                Kirigami.Theme.inherit: false
                color: "transparent"

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: Kirigami.Theme.textColor
                    opacity: 0.15
                }

                BottomBar {
                    id: bottomBarContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    onSearchTextChanged: {
                        // Explicitly push the query to Milou ResultsView.
                        searchPage.resultsView.queryString = bottomBarContent.searchText;
                        // Reset scroll to top on new query.
                        searchPage.resultsView.contentY = 0;
                        searchPage.resultsView.currentIndex = 0;
                    }
                    onSearchFocusResults: {
                        if (root.leftColumnState === 0) {
                            pinnedPage.tryActivate(0);
                        } else if (root.leftColumnState === 1) {
                            allAppsPage.tryActivate(0);
                        } else {
                            searchPage.tryActivate(0, 0);
                        }
                    }
                    onSearchActivateFirstResult: {
                        if (root.leftColumnState === 2) {
                            searchPage.activateFirstResult();
                        }
                    }
                    onSearchEscapePressed: {
                        if (bottomBarContent.searchText !== "") {
                            bottomBarContent.searchText = "";
                        } else {
                            root.closeMenu();
                        }
                    }
                    onTabOut: {
                        if (root.leftColumnState === 0) {
                            pinnedPage.tryActivate(0);
                        } else if (root.leftColumnState === 1) {
                            allAppsPage.tryActivate(0);
                        }
                    }
                    onPowerMenuRequested: {
                        powerMenu.visualParent = bottomBarContent.splitButton;
                        powerMenu.open();
                    }
                    onPowerShutdownRequested: {
                        powerMenu.triggerShutdown();
                    }
                }
            }

            // ── Power options popup (in-dialog, not a separate window) ────
            ShutdownMenu {
                id: powerMenu
                anchors.fill: parent
                onClosed: {
                    bottomBarContent.focusSearch();
                }
            }

            Keys.onPressed: event => {
                if (event.modifiers === Qt.ControlModifier) {
                    var digit = event.key - Qt.Key_1;
                    if (digit >= 0 && digit <= 8) {
                        var count = globalFavorites.count;
                        if (digit < count) {
                            event.accepted = true;
                            globalFavorites.trigger(digit, "", null);
                            root.closeMenu();
                        }
                        return;
                    }
                }
                if (event.modifiers & Qt.ShiftModifier && event.text !== "") {
                    bottomBarContent.focusSearch();
                    return;
                }
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    if (root.searching) {
                        reset();
                    } else if (root.leftColumnState === 1) {
                        root.leftColumnState = 0;
                        bottomBarContent.focusSearch();
                    } else {
                        root.closeMenu();
                    }
                    return;
                }

                // Let Tab/Backtab navigate the focus chain normally.
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    return;
                }

                if (bottomBarContent.activeFocus) {
                    return;
                }

                if (event.key === Qt.Key_Backspace) {
                    event.accepted = true;
                    bottomBarContent.searchText = bottomBarContent.searchText.slice(0, -1);
                    bottomBarContent.focusSearch();
                } else if (event.text !== "" && event.text !== "\t") {
                    event.accepted = true;
                    bottomBarContent.searchText = bottomBarContent.searchText + event.text;
                    bottomBarContent.focusSearch();
                }
            }
        }

        function setModels() {
            pinnedPage.favoritesList.model = globalFavorites;
            var allAppsRow = Plasmoid.configuration.showRecentDocs ? 2 : 1;
            sortedAppsModel.sourceModel = rootModel.modelForRow(allAppsRow);
            allAppsPage.allAppsList.model = sortedAppsModel;
        }

        Component.onCompleted: {
            rootModel.refreshed.connect(setModels);
            reset();
            rootModel.refresh();
        }
    }
}
