/*
    SPDX-FileCopyrightText: 2026 Windows Modern contributors
    SPDX-License-Identifier: GPL-2.0-or-later
*/

// Tells whether the pointer has left this screen's lock window for another
// screen's, using kscreenlocker's ActiveScreenMonitor (new in Plasma 6.8).
// LockScreenUi loads this file through a Loader: on an older kscreenlocker
// the type does not exist, the Loader fails quietly, and the lock screen
// still works (the prompt then stays shown on every screen).

import QtQuick
import org.kde.kscreenlocker as ScreenLocker

Item {
    id: wrapper

    signal leftScreen()

    ScreenLocker.ActiveScreenMonitor {
        lockscreenState: ScreenLocker.LockscreenState
        window: wrapper.Window.window
        onActiveChanged: {
            if (!active) {
                wrapper.leftScreen();
            }
        }
    }
}
