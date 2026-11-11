/*
    Windows Modern — Alt+Tab window switcher (KWin TabBox layout)

    KWin drives the switcher: it fills tabBox.model with the windows,
    moves tabBox.currentIndex on Tab / Shift+Tab, and activates the
    current window when Alt is released. This file only hosts the view in
    a popup centered on the active screen; the visuals are SwitcherView.qml.

    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kwin as KWin

KWin.TabBoxSwitcher {
    id: tabBox

    Instantiator {
        active: tabBox.visible
        delegate: PlasmaCore.Dialog {
            location: PlasmaCore.Types.Floating
            visible: true
            flags: Qt.ToolTip | Qt.X11BypassWindowManagerHint
            x: tabBox.screenGeometry.x + Math.round((tabBox.screenGeometry.width - view.width) / 2)
            y: tabBox.screenGeometry.y + Math.round((tabBox.screenGeometry.height - view.height) / 2)

            mainItem: SwitcherView {
                id: view
                tabBox: tabBox
                screenGeometry: tabBox.screenGeometry
                closeText: i18nd("kwin", "Close")
                emptyText: i18ndc("kwin", "@info:placeholder no entries in the task switcher", "No open windows")
                focus: true
            }

            onSceneGraphError: () => {
                // Intentionally empty: without a handler QtQuick may qFatal() on a graphics reset.
            }
        }
    }
}
