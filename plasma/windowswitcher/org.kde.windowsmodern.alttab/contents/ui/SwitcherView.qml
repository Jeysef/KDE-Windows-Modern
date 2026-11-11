/*
    Windows Modern — Alt+Tab switcher view

    Windows 11 behaviour:
    - every preview has the same height and keeps its window's aspect
      ratio, so cards have different widths;
    - cards wrap into rows, and each row is centered;
    - each card has an icon + title header and shows a close button on
      hover or when selected;
    - the selected card gets a rounded focus ring; clicking a card
      switches to it.

    Colours come from the active colour scheme (Kirigami.Theme), so the
    same file serves the dark and light variants.

    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kwin as KWin

FocusScope {
    id: root

    // The KWin.TabBoxSwitcher: provides model, currentIndex.
    required property var tabBox
    property rect screenGeometry
    // Translated by main.qml, so this file has no i18n dependency and can be
    // previewed outside KWin (see tests/windowswitcher/).
    property string closeText: "Close"
    property string emptyText: "No open windows"

    // ── Metrics (Windows 11 at 100% scale, scaled by Kirigami units) ──
    readonly property real unit: Kirigami.Units.gridUnit / 18
    readonly property int outerPadding: Math.round(12 * unit)
    readonly property int cardSpacing: Math.round(4 * unit)
    readonly property int cardPadding: Math.round(6 * unit)
    readonly property int cardRadius: Math.round(8 * unit)
    readonly property int thumbnailRadius: Math.round(4 * unit)
    readonly property int ringWidth: Math.max(2, Math.round(3 * unit))
    readonly property int headerHeight: Math.round(30 * unit)
    readonly property int headerIconSize: Kirigami.Units.iconSizes.small
    readonly property int thumbnailHeight: Math.round(Math.max(110 * unit,
        Math.min(220 * unit, screenGeometry.height * 0.17)))
    readonly property int cardHeight: cardPadding * 2 + headerHeight + thumbnailHeight

    readonly property int maxContentWidth: Math.max(cardHeight, screenGeometry.width * 0.9 - outerPadding * 2)
    readonly property int maxContentHeight: Math.max(cardHeight, screenGeometry.height * 0.8 - outerPadding * 2)

    // ── Colours ──
    readonly property color textColor: Kirigami.Theme.textColor
    readonly property color hoverFill: Qt.alpha(textColor, 0.06)
    readonly property color selectedFill: Qt.alpha(textColor, 0.09)
    readonly property color closeHoverFill: "#C42B1C"

    // ── Row layout (computed in relayout()) ──
    property int contentWidth: 0
    property int contentHeight: 0
    property var rows: []           // rows[r] = [card indices]
    property var rowOfIndex: []     // rowOfIndex[i] = r

    readonly property int count: cards.count
    readonly property int currentIndex: tabBox.currentIndex

    width: (count === 0 ? Kirigami.Units.gridUnit * 16 : Math.max(contentWidth, cardHeight)) + outerPadding * 2
    height: (count === 0 ? Kirigami.Units.gridUnit * 6 : flick.height) + outerPadding * 2

    function relayout() {
        const newRows = [];
        const newRowOf = [];
        let row = [];
        let rowWidth = 0;
        for (let i = 0; i < cards.count; ++i) {
            const card = cards.itemAt(i);
            if (!card) {
                continue;
            }
            const w = card.width;
            if (row.length > 0 && rowWidth + cardSpacing + w > maxContentWidth) {
                newRows.push({ items: row, width: rowWidth });
                row = [];
                rowWidth = 0;
            }
            rowWidth += (row.length > 0 ? cardSpacing : 0) + w;
            row.push(i);
        }
        if (row.length > 0) {
            newRows.push({ items: row, width: rowWidth });
        }

        let widest = 0;
        for (const r of newRows) {
            widest = Math.max(widest, r.width);
        }
        for (let r = 0; r < newRows.length; ++r) {
            let x = Math.round((widest - newRows[r].width) / 2);
            const y = r * (cardHeight + cardSpacing);
            for (const i of newRows[r].items) {
                const card = cards.itemAt(i);
                card.x = x;
                card.y = y;
                x += card.width + cardSpacing;
                newRowOf[i] = r;
            }
        }
        rows = newRows.map(r => r.items);
        rowOfIndex = newRowOf;
        contentWidth = widest;
        contentHeight = newRows.length > 0 ? newRows.length * cardHeight + (newRows.length - 1) * cardSpacing : 0;
        ensureCurrentVisible();
    }

    // Coalesces relayout requests. A Timer (unlike Qt.callLater) is destroyed
    // with the view, so a pending relayout never runs after KWin closes it.
    Timer {
        id: relayoutTimer
        interval: 0
        onTriggered: root.relayout()
    }

    function scheduleRelayout() {
        relayoutTimer.restart();
    }

    function ensureCurrentVisible() {
        const card = cards.itemAt(currentIndex);
        if (!card) {
            return;
        }
        if (card.y < flick.contentY) {
            flick.contentY = card.y;
        } else if (card.y + card.height > flick.contentY + flick.height) {
            flick.contentY = card.y + card.height - flick.height;
        }
    }

    // Up/Down: move to the card in the neighbouring row whose centre is
    // closest to the current card's centre (rows wrap around).
    function moveVertically(step) {
        if (rows.length < 2) {
            return;
        }
        const current = cards.itemAt(currentIndex);
        const r = rowOfIndex[currentIndex];
        if (current === null || r === undefined) {
            return;
        }
        const target = rows[(r + step + rows.length) % rows.length];
        const centre = current.x + current.width / 2;
        let best = target[0];
        let bestDistance = Infinity;
        for (const i of target) {
            const card = cards.itemAt(i);
            const distance = Math.abs(card.x + card.width / 2 - centre);
            if (distance < bestDistance) {
                bestDistance = distance;
                best = i;
            }
        }
        tabBox.currentIndex = best;
    }

    onMaxContentWidthChanged: scheduleRelayout()
    onCurrentIndexChanged: ensureCurrentVisible()

    Keys.onPressed: event => {
        if (count === 0) {
            return;
        }
        if (event.key === Qt.Key_Left) {
            tabBox.currentIndex = (currentIndex - 1 + count) % count;
        } else if (event.key === Qt.Key_Right) {
            tabBox.currentIndex = (currentIndex + 1) % count;
        } else if (event.key === Qt.Key_Up) {
            moveVertically(-1);
        } else if (event.key === Qt.Key_Down) {
            moveVertically(1);
        } else {
            return;
        }
        event.accepted = true;
    }

    Flickable {
        id: flick
        x: root.outerPadding
        y: root.outerPadding
        width: root.contentWidth
        height: Math.min(root.contentHeight, root.maxContentHeight)
        contentWidth: root.contentWidth
        contentHeight: root.contentHeight
        interactive: contentHeight > height
        clip: interactive
        boundsBehavior: Flickable.StopAtBounds

        Repeater {
            id: cards
            model: root.tabBox.model

            onCountChanged: root.scheduleRelayout()
            onItemAdded: root.scheduleRelayout()
            onItemRemoved: root.scheduleRelayout()

            delegate: Item {
                id: card

                required property int index
                required property var model

                readonly property bool isCurrent: index === root.currentIndex
                readonly property bool showClose: (model.closeable ?? false)
                    && typeof root.tabBox.model.close !== "undefined"
                    && (cardHover.hovered || isCurrent)

                // Preview width follows the window's aspect ratio, clamped so
                // very tall or very wide windows stay usable.
                readonly property real ratio: (thumbnail.implicitWidth > 0 && thumbnail.implicitHeight > 0)
                    ? thumbnail.implicitWidth / thumbnail.implicitHeight : 16 / 9
                readonly property int previewWidth: Math.round(root.thumbnailHeight
                    * Math.max(0.75, Math.min(2.2, ratio)))

                width: previewWidth + root.cardPadding * 2
                height: root.cardHeight
                onWidthChanged: root.scheduleRelayout()

                Accessible.name: model.caption ?? ""
                Accessible.role: Accessible.ListItem
                Accessible.selected: isCurrent

                Rectangle {
                    anchors.fill: parent
                    radius: root.cardRadius
                    color: card.isCurrent ? root.selectedFill
                         : cardHover.hovered ? root.hoverFill : "transparent"
                }

                // Focus ring of the selected window.
                Rectangle {
                    anchors.fill: parent
                    radius: root.cardRadius
                    color: "transparent"
                    border.width: root.ringWidth
                    border.color: root.textColor
                    visible: card.isCurrent
                }

                // Hover state for the whole card. A HoverHandler (unlike a
                // MouseArea) stays hovered while the pointer is over the
                // card's children, so the close button does not flicker away
                // when the pointer moves onto it.
                HoverHandler {
                    id: cardHover
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton && card.showClose) {
                            root.tabBox.model.close(card.index);
                        } else if (mouse.button === Qt.LeftButton) {
                            root.tabBox.model.activate(card.index);
                        }
                    }
                }

                // ── Header: icon + title, close button on the right ──
                Item {
                    id: header
                    x: root.cardPadding
                    y: root.cardPadding
                    width: card.previewWidth
                    height: root.headerHeight

                    Kirigami.Icon {
                        id: headerIcon
                        anchors.left: parent.left
                        anchors.leftMargin: Math.round(2 * root.unit)
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.headerIconSize
                        height: root.headerIconSize
                        source: card.model.icon
                    }

                    PlasmaComponents3.Label {
                        anchors.left: headerIcon.right
                        anchors.leftMargin: Math.round(8 * root.unit)
                        anchors.right: closeButton.visible ? closeButton.left : parent.right
                        anchors.rightMargin: Math.round(4 * root.unit)
                        anchors.verticalCenter: parent.verticalCenter
                        text: card.model.caption ?? ""
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        color: root.textColor
                    }

                    Rectangle {
                        id: closeButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.round(26 * root.unit)
                        height: width
                        radius: Math.round(4 * root.unit)
                        visible: card.showClose
                        color: closeMouse.containsMouse ? root.closeHoverFill : "transparent"

                        Kirigami.Icon {
                            anchors.centerIn: parent
                            width: Kirigami.Units.iconSizes.small
                            height: width
                            source: "window-close-symbolic"
                            color: closeMouse.containsMouse ? "white" : root.textColor
                            isMask: true
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.tabBox.model.close(card.index)
                        }

                        Accessible.role: Accessible.Button
                        Accessible.name: root.closeText
                    }
                }

                // ── Live preview with rounded corners ──
                Item {
                    id: preview
                    x: root.cardPadding
                    y: root.cardPadding + root.headerHeight
                    width: card.previewWidth
                    height: root.thumbnailHeight

                    // Shown until (or instead of) the live preview, e.g. for
                    // windows KWin cannot render a thumbnail for.
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.huge
                        height: width
                        source: card.model.icon
                    }

                    KWin.WindowThumbnail {
                        id: thumbnail
                        anchors.fill: parent
                        wId: card.model.windowId
                        // Rounded corners need a shader. On the software
                        // renderer MultiEffect draws nothing, which would hide
                        // the preview entirely, so fall back to square corners.
                        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: previewMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }
                    }

                    Rectangle {
                        id: previewMask
                        anchors.fill: parent
                        radius: root.thumbnailRadius
                        visible: false
                        layer.enabled: true
                    }
                }
            }
        }
    }

    PlasmaComponents3.Label {
        anchors.centerIn: parent
        visible: root.count === 0
        text: root.emptyText
        color: root.textColor
    }
}
