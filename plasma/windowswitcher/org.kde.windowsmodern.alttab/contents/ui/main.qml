/*
    Windows Modern — Alt+Tab window switcher (KWin TabBox layout)

    KWin drives the switcher: it fills model with the windows,
    moves currentIndex on Tab / Shift+Tab, and activates the
    current window when Alt is released. This file only hosts the view in
    a popup centered on the active screen; the visuals are SwitcherView.qml.

    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.kwin as KWin

KWin.TabBoxSwitcher {
    // Not "tabBox": inside the Instantiator delegate, "tabBox: tabBox" on the
    // view resolves to the view's own property (undefined), not this id.
    id: switcher

    Instantiator {
        active: switcher.visible
        delegate: PlasmaCore.Dialog {
            location: PlasmaCore.Types.Floating
            visible: true
            flags: Qt.ToolTip | Qt.X11BypassWindowManagerHint
            x: switcher.screenGeometry.x + Math.round((switcher.screenGeometry.width - view.width) / 2)
            y: switcher.screenGeometry.y + Math.round((switcher.screenGeometry.height - view.height) / 2)

            mainItem: SwitcherView {
                id: view
                tabBox: switcher
                screenGeometry: switcher.screenGeometry
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
