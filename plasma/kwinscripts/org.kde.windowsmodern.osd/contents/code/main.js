/*
    On-screen displays (volume, brightness, keyboard layout...) bottom-centre,
    just above the taskbar, as on Windows 11. KWin places them two-thirds of
    the way down the screen; this moves each one when it appears and keeps
    it anchored there when its size changes.

    SPDX-FileCopyrightText: 2026 Jeysef
    SPDX-License-Identifier: GPL-3.0-or-later
*/

const GAP = 12; // px between the OSD and the taskbar (or screen edge)

function place(win) {
    const area = workspace.clientArea(KWin.MaximizeArea, win);
    const g = win.frameGeometry;
    const x = Math.round(area.x + (area.width - g.width) / 2);
    const y = Math.round(area.y + area.height - g.height - GAP);
    if (g.x !== x || g.y !== y) {
        win.frameGeometry = { x: x, y: y, width: g.width, height: g.height };
    }
}

function watch(win) {
    if (!win || !win.onScreenDisplay) return;
    place(win);
    win.frameGeometryChanged.connect(() => place(win));
}

workspace.windowAdded.connect(watch);
workspace.windowList().forEach(watch);
