/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   StartAllBack-style pinned page: a vertical list of favorite apps using
 *   ListItemDelegate.  The "All apps >" header toggle asks the shell to
 *   swap the left column to the full alphabetical list.
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "../components"

Column {
    id: pinnedPage

    width: parent.width
    spacing: Kirigami.Units.largeSpacing

    property alias favoritesList: favoritesListView

    signal showAllAppsRequested
    signal keyNavUpFromList

    function tryActivate(row) {
        if (favoritesListView.count > 0) {
            favoritesListView.currentIndex = Math.min(row, favoritesListView.count - 1);
            favoritesListView.forceActiveFocus();
        }
    }

    // ── Header row: "Pinned" + spacer + "All apps >" ─────────────────────
    RowLayout {
        id: headerRow
        width: parent.width
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            text: i18n("Pinned")
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
            font.weight: Font.DemiBold
            font.family: "Segoe UI"
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        AToolButton {
            buttonHeight: 25
            flat: true
            iconName: "go-next"
            text: i18n("All apps")
            Layout.rightMargin: Kirigami.Units.mediumSpacing
            onClicked: pinnedPage.showAllAppsRequested()
        }
    }

    // ── Pinned favorites vertical list ──────────────────────────────────
    PlasmaComponents3.ScrollView {
        id: favScroll
        width: parent.width
        height: pinnedPage.height - headerRow.height - pinnedPage.spacing
        PlasmaComponents3.ScrollBar.horizontal.policy: PlasmaComponents3.ScrollBar.AlwaysOff

        ListView {
            id: favoritesListView
            anchors.fill: parent
            clip: true
            spacing: Kirigami.Units.smallSpacing / 2
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: -1

            delegate: ListItemDelegate {
                iconSize: Kirigami.Units.iconSizes.smallMedium
                onActivated: function(idx, actionId, actionArgument) {
                    favoritesListView.currentIndex = idx;
                }
            }

            highlightMoveDuration: 0

            Keys.onUpPressed: event => {
                if (currentIndex <= 0) {
                    event.accepted = true;
                    pinnedPage.keyNavUpFromList();
                }
            }
        }
    }
}
