/*
    Show desktop through KWin's own show-desktop mode — the same state that
    Win+D (Meta+D) toggles, as on Windows. Clicking again restores the
    windows; activating any window also leaves the mode.

    It replaces a minimize-all controller that minimized windows one by one:
    while doing so KWin focused the next not-yet-minimized window, which the
    controller took as "the user picked a window", so the second click never
    restored anything.

    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQml

import org.kde.kwindowsystem

Controller {
    titleActive: i18ndc("plasma_applet_org.kde.plasma.showdesktop", "@action:button", "Show desktop")
    titleInactive: i18ndc("plasma_applet_org.kde.plasma.showdesktop", "@action:button", "Show desktop")

    descriptionActive: ""
    descriptionInactive: ""

    active: KWindowSystem.showingDesktop

    function toggle() {
        KWindowSystem.showingDesktop = !KWindowSystem.showingDesktop;
    }
}
