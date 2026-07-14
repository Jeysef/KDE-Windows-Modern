/*
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2014 Martin Gräßlin <mgraesslin@kde.org>
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2017 Roman Gilg <subdiff@gmail.com>
    SPDX-FileCopyrightText: 2020-2024 Nate Graham <nate@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kwindowsystem

Item {
    id: root

    required property var model
    required property int index
    required property /*QModelIndex*/ var submodelIndex
    required property int appPid
    required property string display
    required property bool isMinimized
    required property bool isOnAllVirtualDesktops
    required property /*list<var>*/ var virtualDesktops
    required property list<string> activities
    required property rect windowGeometry

    property bool hasTrackInATitle: false
    property int orientation: ListView.Vertical

    readonly property bool thumbnailMode: toolTipDelegate.isWin && Plasmoid.configuration.showToolTips

    implicitWidth: root.thumbnailMode
        ? toolTipDelegate.tooltipInstanceMaximumWidth
        : contentColumn.implicitWidth
    implicitHeight: contentColumn.implicitHeight

    ListView.onPooled: width = height = 0
    ListView.onReused: width = height = undefined

    readonly property string title: {
        if (!toolTipDelegate.isWin) {
            return toolTipDelegate.genericName;
        }

        let text = display;
        if (toolTipDelegate.isGroup && text === "") {
            return "";
        }

        if (!text.match(/\s+(—|-|–)/)) {
            return text;
        }

        text = `${(text.match(/.*(?=\s+(—|-|–))/) || [""])[0]}${(text.match(/<\d+>/) || [""]).pop()}`;

        if (text === "") {
            text = "—";
        }
        return text;
    }

    readonly property bool titleIncludesTrack: toolTipDelegate.playerData !== null && title.includes(toolTipDelegate.playerData.track)

    // Tile-wide hover tracker — passive (no button grabbing), so the existing
    // ToolTipWindowMouseArea clicks/hover pass through untouched. Drives the
    // close button visibility so the X only shows when hovering this tile.
    HoverHandler { id: tileHover }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        spacing: root.thumbnailMode ? 0 : Kirigami.Units.smallSpacing

        // ── Header: title spans full width, icon/close buttons positioned inside it ──
        RowLayout {
            id: headerItem
            Layout.fillWidth: true
            Layout.maximumWidth: toolTipDelegate.tooltipInstanceMaximumWidth
            Layout.alignment: Qt.AlignVCenter
            Layout.margins: root.thumbnailMode ? 0 : Kirigami.Units.gridUnit / 2
            Layout.minimumHeight: root.thumbnailMode ? Kirigami.Units.iconSizes.smallMedium : 0
            spacing: root.thumbnailMode ? Kirigami.Units.smallSpacing : 0

            // App icon — shown in thumbnail mode
            Kirigami.Icon {
                id: appIcon
                source: toolTipDelegate.icon
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                Layout.alignment: Qt.AlignVCenter
                visible: root.thumbnailMode
            }

            // Full-width text wrapper: title spans the whole available width,
            // icon and close button are anchored on top of it.
            Item {
                id: textWrapper
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: textColumn.implicitHeight

                ColumnLayout {
                    id: textColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: (closeButton.visible ? closeButton.width : (countBadge.visible ? countBadge.width : 0))
                                    + ((closeButton.visible || countBadge.visible) ? Kirigami.Units.smallSpacing : 0)
                    }
                    spacing: 0

                    // app name — hidden in thumbnail mode
                    PlasmaComponents3.Label {
                        id: appNameHeading
                        maximumLineCount: 1
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: toolTipDelegate.appName
                        color: Kirigami.Theme.textColor
                        opacity: root.index === 0 ? 1 : 0
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize
                        visible: (text.length !== 0)
                            && (root.orientation === ListView.Horizontal || root.index === 0)
                            && !root.thumbnailMode
                        textFormat: Text.PlainText
                    }
                    // window title
                    PlasmaComponents3.Label {
                        id: winTitle
                        Layout.fillWidth: true
                        Layout.topMargin: root.thumbnailMode ? 0 : Kirigami.Units.smallSpacing
                        Layout.bottomMargin: root.thumbnailMode ? 0 : Kirigami.Units.smallSpacing
                        Layout.preferredHeight: root.thumbnailMode
                            ? implicitHeight
                            : (root.orientation === ListView.Horizontal && lineCount === 1
                                ? implicitHeight * 2
                                : implicitHeight)
                        maximumLineCount: root.thumbnailMode ? 1 : 2
                        wrapMode: root.thumbnailMode ? Text.NoWrap : Text.Wrap
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize
                        property bool somethingVisible: (thumbnailSourceItem.visible ||
                            appNameHeading.visible || subtext.visible)
                        text: (!root.thumbnailMode && root.title === appNameHeading.text && somethingVisible)
                              ? "" : root.title
                        color: Kirigami.Theme.textColor
                        font.bold: toolTipDelegate.isGroup && toolTipDelegate.parentTask.model.IsActive && root.index == tasksModel.activeTask.row
                        visible: root.orientation === ListView.Horizontal || text.length !== 0
                        textFormat: Text.PlainText
                    }
                    // subtext
                    PlasmaComponents3.Label {
                        id: subtext
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.orientation === ListView.Horizontal && lineCount === 1
                            ? implicitHeight * 2
                            : implicitHeight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        text: toolTipDelegate.isWin ? root.generateSubText() : ""
                        color: Kirigami.Theme.textColor
                        opacity: 0.7
                        visible: !root.thumbnailMode && text.length !== 0 && text !== appNameHeading.text
                        textFormat: Text.PlainText
                    }
                }

                // Count badge — only in non-thumbnail mode
                Item {
                    id: countBadge
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: Kirigami.Units.iconSizes.smallMedium
                    visible: !root.thumbnailMode && root.index === 0 && toolTipDelegate.smartLauncherCountVisible

                    Kirigami.Badge {
                        anchors.centerIn: parent
                        text: toolTipDelegate.smartLauncherCount
                    }
                }

                // Win11 close button: collapses to width 0 when idle (title
                // spans full width); expands + fades in at the far right on
                // tile hover. Bg transparent by default, red on hover, darker
                // red on press.
                Item {
                    id: closeButton
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    width: tileHover.hovered ? Kirigami.Units.iconSizes.smallMedium : 0
                    height: Kirigami.Units.iconSizes.smallMedium
                    visible: root.thumbnailMode
                    opacity: tileHover.hovered ? 1 : 0
                    enabled: tileHover.hovered
                    clip: true

                    Behavior on opacity {
                        NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
                    }
                    Behavior on width {
                        NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutQuad }
                    }

                    property bool hovered: closeMouseArea.containsMouse
                    property bool pressed: closeMouseArea.containsPress

                    MouseArea {
                        id: closeMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: {
                            tasks.cancelHighlightWindows();
                            tasksModel.requestClose(root.submodelIndex);
                        }
                        PlasmaComponents3.ToolTip.text: i18nc("@info:tooltip Close this window", "Close window")
                        PlasmaComponents3.ToolTip.visible: closeMouseArea.containsMouse
                        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.smallSpacing
                        color: closeButton.pressed
                            ? "#9E1B1B"
                            : closeButton.hovered
                                ? "#C42B1C"
                                : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.small
                        height: Kirigami.Units.iconSizes.small
                        source: "window-close"
                        color: closeButton.hovered || closeButton.pressed
                            ? "white"
                            : Kirigami.Theme.textColor
                    }
                }
            }
        }

        // make the header clickable if image tooltips are disabled
        Loader {
            id: headerHoverHandler
            active: (root.index !== -1) && !Plasmoid.configuration.showToolTips
            z: -2
            anchors.fill: headerItem
            sourceComponent: ToolTipWindowMouseArea {
                rootTask: toolTipDelegate.parentTask
                modelIndex: root.submodelIndex
                winId: thumbnailSourceItem.winId
            }
        }

        PlasmaExtras.Highlight {
            id: headerHoverHighlight
            anchors.fill: headerHoverHandler
            z: -1
            visible: (headerHoverHandler.item as MouseArea)?.containsMouse ?? false
            pressed: (headerHoverHandler.item as MouseArea)?.containsPress ?? false
            hovered: true
        }

        // ── Thumbnail container ──
        Item {
            id: thumbnailSourceItem

            readonly property real thumbnailImplicitWidth: {
                if (!root.thumbnailMode) return 0
                return toolTipDelegate.tooltipInstanceMaximumWidth
            }

            Layout.preferredWidth: toolTipDelegate.tooltipInstanceMaximumWidth
            Layout.preferredHeight: Kirigami.Units.gridUnit * 8
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 0

            clip: true
            visible: root.thumbnailMode

            readonly property /*undefined|WId where WId = int|string*/ var winId:
                toolTipDelegate.isWin ? toolTipDelegate.windows[root.index] : undefined

            Rectangle {
                id: thumbnailClip
                anchors.fill: parent
                radius: Kirigami.Units.smallSpacing * 2
                color: "transparent"
                visible: false
            }

            PlasmaExtras.Highlight {
                anchors.fill: hoverHandler
                visible: (hoverHandler.item as MouseArea)?.containsMouse ?? false
                pressed: (hoverHandler.item as MouseArea)?.containsPress ?? false
                hovered: true
            }

            Loader {
                id: pipeWireLoader
                anchors.fill: hoverHandler
                anchors.margins: 0

                active: Plasmoid.configuration.showToolTips
                    && !toolTipDelegate.isLauncher
                    && !albumArtImage.visible
                    && root.index !== -1
                asynchronous: true
                source: "PipeWireThumbnail.qml"
            }

            Loader {
                active: Plasmoid.configuration.showToolTips
                    && albumArtImage.visible
                    && albumArtImage.status === Image.Ready
                    && root.index !== -1
                asynchronous: true
                visible: active
                anchors.centerIn: hoverHandler

                sourceComponent: ShaderEffect {
                    id: albumArtBackground
                    readonly property Image source: albumArtImage

                    readonly property real scaleFactor: Math.max(hoverHandler.width / source.paintedWidth, hoverHandler.height / source.paintedHeight)
                    width: Math.round(source.paintedWidth * scaleFactor)
                    height: Math.round(source.paintedHeight * scaleFactor)
                    layer.enabled: true
                    opacity: 0.25
                    layer.effect: GE.FastBlur {
                        source: albumArtBackground
                        anchors.fill: source
                        radius: 30
                    }
                }
            }

            Image {
                id: albumArtImage
                readonly property bool available: (status === Image.Ready || status === Image.Loading)
                    && (!(toolTipDelegate.isGroup || backend.applicationCategories(launcherUrl).includes("WebBrowser")) || root.titleIncludesTrack)

                anchors.fill: hoverHandler
                anchors.margins: 1
                sourceSize: Qt.size(parent.width, parent.height)

                asynchronous: true
                retainWhileLoading: true
                source: toolTipDelegate.playerData?.artUrl ?? ""
                fillMode: Image.PreserveAspectFit
                visible: available
            }

            Loader {
                id: hoverHandler
                active: root.index !== -1
                anchors.fill: parent
                sourceComponent: ToolTipWindowMouseArea {
                    rootTask: toolTipDelegate.parentTask
                    modelIndex: root.submodelIndex
                    winId: thumbnailSourceItem.winId
                }
            }
        }


    }

    function generateSubText(): string {
        const subTextEntries = [];

        if (!Plasmoid.configuration.showOnlyCurrentDesktop && virtualDesktopInfo.numberOfDesktops > 1) {
            if (!isOnAllVirtualDesktops && virtualDesktops.length > 0) {
                const virtualDesktopNameList = virtualDesktops.map(virtualDesktop => {
                    const index = virtualDesktopInfo.desktopIds.indexOf(virtualDesktop);
                    return virtualDesktopInfo.desktopNames[index];
                });

                subTextEntries.push(i18nc("Comma-separated list of desktops", "On %1",
                    virtualDesktopNameList.join(", ")));
            } else if (isOnAllVirtualDesktops) {
                subTextEntries.push(i18nc("Comma-separated list of desktops", "Pinned to all desktops"));
            }
        }

        if (activities.length === 0 && activityInfo.numberOfRunningActivities > 1) {
            subTextEntries.push(i18nc("Which virtual desktop a window is currently on",
                "Available on all activities"));
        } else if (activities.length > 0) {
            const activityNames = activities
                .filter(activity => activity !== activityInfo.currentActivity)
                .map(activity => activityInfo.activityName(activity))
                .filter(activityName => activityName !== "");

            if (Plasmoid.configuration.showOnlyCurrentActivity) {
                if (activityNames.length > 0) {
                    subTextEntries.push(i18nc("Activities a window is currently on (apart from the current one)",
                        "Also available on %1", activityNames.join(", ")));
                }
            } else if (activityNames.length > 0) {
                subTextEntries.push(i18nc("Which activities a window is currently on",
                    "Available on %1", activityNames.join(", ")));
            }
        }

        return subTextEntries.join("\n");
    }
}
