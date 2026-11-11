/*
    Windows 11 Snap Layouts. Drag a window towards the top edge: a bar of
    layouts slides in at the top centre. Hover a cell to preview where the
    window goes, release to snap it there. Releasing anywhere else leaves
    KWin's own behaviour (e.g. maximize at the top edge) alone.

    KWin keeps the pointer during a move, so the bar gets no hover events:
    the hovered cell is worked out from the cursor on every move step.

    SPDX-FileCopyrightText: 2026 Jeysef
    SPDX-License-Identifier: GPL-3.0-or-later
*/
import QtQuick
import org.kde.kwin

import "layouts.js" as Layouts

Item {
    id: root

    // How close to the top of the screen the pointer must come.
    readonly property int triggerDistance: 48

    property var movingWindow: null
    property var target: null // { layout, cell, rect } while a cell is hovered

    function track(win) {
        if (!win || !win.normalWindow) {
            return;
        }
        win.interactiveMoveResizeStarted.connect(() => {
            if (win.move && win.resizeable) {
                root.movingWindow = win;
            }
        });
        win.interactiveMoveResizeStepped.connect(() => {
            if (root.movingWindow === win) {
                root.update(win);
            }
        });
        win.interactiveMoveResizeFinished.connect(() => {
            if (root.movingWindow === win) {
                root.finish(win);
            }
        });
    }

    function update(win) {
        const cursor = Workspace.cursorPos;
        const screen = Workspace.clientArea(KWin.FullScreenArea, win);
        const nearTop = cursor.y - screen.y <= triggerDistance;
        if (!bar.visible && !nearTop) {
            return;
        }
        if (!bar.visible) {
            bar.showOn(screen, Workspace.clientArea(KWin.MaximizeArea, win));
        }
        const hit = bar.cellAt(cursor.x, cursor.y);
        if (hit) {
            const rect = Layouts.cellRect(bar.workArea, Layouts.layouts[hit.layout][hit.cell]);
            if (!target || target.layout !== hit.layout || target.cell !== hit.cell) {
                target = { layout: hit.layout, cell: hit.cell, rect: rect };
                Workspace.showOutline(Qt.rect(rect.x, rect.y, rect.width, rect.height));
            }
        } else {
            if (target) {
                Workspace.hideOutline();
            }
            target = null;
            // Leave the bar once the pointer is well below it.
            if (cursor.y > bar.y + bar.height + triggerDistance) {
                bar.visible = false;
            }
        }
    }

    function finish(win) {
        const chosen = target;
        target = null;
        movingWindow = null;
        bar.visible = false;
        Workspace.hideOutline();
        if (!chosen) {
            return;
        }
        // After KWin has handled the release (it may maximize at the top edge).
        snapTimer.win = win;
        snapTimer.rect = chosen.rect;
        snapTimer.restart();
    }

    Timer {
        id: snapTimer
        property var win: null
        property var rect: null
        interval: 50
        onTriggered: {
            if (!win || win.deleted) {
                return;
            }
            if (typeof win.setMaximize === "function") {
                win.setMaximize(false, false);
            }
            win.frameGeometry = Qt.rect(rect.x, rect.y, rect.width, rect.height);
            win = null;
        }
    }

    SnapBar {
        id: bar
        hovered: root.target
    }

    Component.onCompleted: {
        Workspace.windows.forEach(track);
    }

    Connections {
        target: Workspace
        function onWindowAdded(win) {
            root.track(win);
        }
    }
}
