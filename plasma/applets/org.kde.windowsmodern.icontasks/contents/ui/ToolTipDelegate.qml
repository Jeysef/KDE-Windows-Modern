/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2014 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2017 Roman Gilg <subdiff@gmail.com>
    SPDX-FileCopyrightText: 2024 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.mpris as Mpris
import org.kde.kirigami as Kirigami

import org.kde.plasma.plasmoid

Loader {
    id: toolTipDelegate

    property Task parentTask
    property /*QModelIndex*/var rootIndex

    property string appName
    property int pidParent
    property bool isGroup

    property /*list<WId> where WId = int|string*/ var windows: []
    readonly property bool isWin: windows.length > 0

    property /*QIcon*/ var icon
    property url launcherUrl
    property bool isLauncher
    property bool isMinimized

    // Needed for generateSubtext()
    property string display
    property string genericName
    property /*list<var>*/ var virtualDesktops: [] // Can't use list<var> because of QTBUG-127600
    property bool isOnAllVirtualDesktops
    property list<string> activities: []

    property bool smartLauncherCountVisible
    property int smartLauncherCount

    property bool blockingUpdates: false
    property rect windowGeometry: Qt.rect(0, 0, 0, 0)

    readonly property bool isVerticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    // Thumbnail cards (Windows 11): one height, the window's width up to 16:9,
    // and the same padding on every side of the hover highlight.
    readonly property int thumbnailHeight: Kirigami.Units.gridUnit * 7
    readonly property int thumbnailMaximumWidth: Math.round(thumbnailHeight * 16 / 9)
    readonly property int thumbnailMinimumWidth: Kirigami.Units.gridUnit * 6   // room for a short title
    readonly property int cardPadding: Kirigami.Units.smallSpacing * 2
    // Widest card; also the width of text-only tooltips (no thumbnails)
    readonly property int tooltipInstanceMaximumWidth: Plasmoid.configuration.showToolTips
        ? thumbnailMaximumWidth + 2 * cardPadding
        : Kirigami.Units.gridUnit * 13
    // No gap between thumbnail cards: each card has cardPadding inside, so
    // two thumbnails are 2 × cardPadding apart, the same as a thumbnail and
    // the popup's edge (the popup's own margin is about cardPadding too).
    readonly property int tileSpacing: 0

    // These properties are required to make tooltip interactive when there is a player but no window is present.
    readonly property Mpris.PlayerContainer playerData: mpris2Source.playerForLauncherUrl(launcherUrl, pidParent)

    LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    active: !blockingUpdates && rootIndex !== undefined && ((parentTask && parentTask.containsMouse) || Window.visibility !== Window.Hidden)
    asynchronous: true

    sourceComponent: isGroup ? groupToolTip : singleTooltip

    Component {
        id: singleTooltip

        ToolTipInstance {
            index: 0 // TODO: maybe set to -1, because that's what the component checks against?
            submodelIndex: toolTipDelegate.rootIndex
            appPid: toolTipDelegate.pidParent
            display: toolTipDelegate.display
            isMinimized: toolTipDelegate.isMinimized
            isOnAllVirtualDesktops: toolTipDelegate.isOnAllVirtualDesktops
            virtualDesktops: toolTipDelegate.virtualDesktops
            activities: toolTipDelegate.activities
            windowGeometry: toolTipDelegate.windowGeometry
            model: null
        }
    }

    Component {
        id: groupToolTip

        PlasmaComponents3.ScrollView {
            // 2 * Kirigami.Units.smallSpacing is for the margin of tooltipDialog
            readonly property real maximumWidth: Screen.desktopAvailableWidth - 2 * Kirigami.Units.smallSpacing
            readonly property real maximumHeight: Screen.desktopAvailableWidth - 2 * Kirigami.Units.smallSpacing

            implicitWidth: {
                // when vertical, all delegates have the same fixed width, but with an extra
                // gridUnit when thumbnails are disabled to match the default tooltip margins
                let listContentWidth = groupToolTipListView.orientation == ListView.Vertical
                   ? toolTipDelegate.tooltipInstanceMaximumWidth + (toolTipDelegate.isWin && Plasmoid.configuration.showToolTips ? 0 : Kirigami.Units.gridUnit)
                   : groupToolTipListView.contentWidth

                // Thumbnail cards follow their window's shape, so the estimate
                // (every card at its widest) is only a stand-in until the
                // cards exist; a floor would leave empty space at the end.
                const width = (groupToolTipListView.orientation == ListView.Horizontal && listContentWidth > 0)
                    ? listContentWidth
                    : Math.max(delegateModel.estimatedWidth, listContentWidth)
                return leftPadding + rightPadding + Math.min(maximumWidth, width)
            }

            implicitHeight: {
                // not using bottomPadding; in PC3 it's either 0 or the scrollbar height, and here
                // this causes binding loops when turning it off - manually computing the width
                // avoids this.
                let scrollBarRequired = groupToolTipListView.contentWidth > maximumWidth
                let scrollBarHeight = scrollBarRequired ? PlasmaComponents3.ScrollBar.horizontal.height : 0
                // currentItem is never unloaded, so we use it for sizing. Default to the same value
                // that estimatedHeight while it's not available
                let listContentHeight = groupToolTipListView.orientation == ListView.Vertical
                    ? groupToolTipListView.contentHeight
                    : groupToolTipListView.currentItem?.implicitHeight ?? toolTipDelegate.tooltipInstanceMaximumWidth

                return Math.min(maximumHeight, Math.max(delegateModel.estimatedHeight, listContentHeight + scrollBarHeight))
            }

            ListView {
                id: groupToolTipListView

                model: delegateModel

                orientation: toolTipDelegate.isVerticalPanel || !Plasmoid.configuration.showToolTips ? ListView.Vertical : ListView.Horizontal
                reuseItems: true

                // Win11: spacing between tiles matches tooltip SVG margin
                spacing: Plasmoid.configuration.showToolTips ? toolTipDelegate.tileSpacing : 0

                // Required to know whether to display the media player buttons on the first window or not
                property bool hasTrackInATitle: {
                    // An empty track (Chromium's idle player) matches every title.
                    const track = toolTipDelegate.playerData?.track ?? ""
                    if (track.length === 0) {
                        return false
                    }
                    var found = false
                    for (var i=0; i<model.items.count && !found; i++) {
                        found = model.items.get(i).model.display.includes(track)
                    }
                    return found
                }

                Component.onCompleted: if (parentTask.model.IsActive) {
                    groupToolTipListView.positionViewAtIndex(tasksModel.activeTask.row, ListView.Center)
                }
            }

            DelegateModel {
                id: delegateModel

                // On Wayland, a tooltip has a significant resizing process, so estimate the size first.
                readonly property real estimatedWidth: (toolTipDelegate.isVerticalPanel || !Plasmoid.configuration.showToolTips ? 1 : count) * (toolTipDelegate.tooltipInstanceMaximumWidth + toolTipDelegate.tileSpacing) - toolTipDelegate.tileSpacing
                readonly property real estimatedHeight: (toolTipDelegate.isVerticalPanel || !Plasmoid.configuration.showToolTips ? count : 1) * (Plasmoid.configuration.showToolTips ? (toolTipDelegate.tooltipInstanceMaximumWidth / 2 + toolTipDelegate.tileSpacing) : Kirigami.Units.gridUnit * 2) - toolTipDelegate.tileSpacing

                model: tasksModel

                rootIndex: toolTipDelegate.rootIndex
                onRootIndexChanged: {
                    if (parentTask.model.IsActive) {
                            groupToolTipListView.positionViewAtIndex(tasksModel.activeTask.row, ListView.Center)
                    } else {
                        groupToolTipListView.positionViewAtBeginning() // Fix a visual glitch (when the mouse moves from a tooltip with a moved scrollbar to another tooltip without a scrollbar)
                    }
                }

                delegate: ToolTipInstance {
                    submodelIndex: tasksModel.makeModelIndex(toolTipDelegate.rootIndex.row, index)
                    appPid: model.AppPid
                    // 'display' is required already
                    isMinimized: model.IsMinimized
                    isOnAllVirtualDesktops: model.IsOnAllVirtualDesktops
                    virtualDesktops: model.VirtualDesktops
                    activities: model.Activities
                    hasTrackInATitle: groupToolTipListView.hasTrackInATitle
                    orientation: groupToolTipListView.orientation
                    windowGeometry: model.Geometry
                }
            }
        }
    }
}
