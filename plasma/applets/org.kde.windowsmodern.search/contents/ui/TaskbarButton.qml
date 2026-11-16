/*
    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later

    A Windows 11 taskbar button: a square cell with a centred monochrome
    glyph that gets the task buttons' hover tile (widgets/tasks.svg: 6 %
    white / 3.5 % black, 3 % border, 4 px corners). Pressed uses WinUI's
    tertiary subtle fill and shrinks the glyph, as the Windows taskbar does.

    tasks.svg itself can't be reused: its hover and focus tiles carry the
    running-app indicator bar, and these buttons are not apps.

    Shared by the Search and Task View applets. Each package carries an
    identical copy (verify-all.sh checks that they don't drift); the file
    has no Plasma imports so tests can render it headless.
*/

import QtQuick

import org.kde.kirigami as Kirigami

MouseArea {
    id: button

    // Theme icon name, and the one to use if the icon theme lacks it.
    property string iconName
    property string fallbackIconName
    // Accessible name ("Search"); also what screen readers announce.
    property string text
    property string description

    // Preview/test hooks: draw a state without a pointer.
    property bool forceHovered: false
    property bool forcePressed: false

    signal triggered()

    readonly property bool showPressed: forcePressed || containsPress
    readonly property bool showHovered: forceHovered || containsMouse || activeFocus

    // The colour scheme decides: light text means a dark taskbar.
    readonly property bool darkTheme: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.textColor)
                                      === Kirigami.ColorUtils.Light

    // Glyph size: two thirds of the cell, at most 30 px (the app icons'
    // size on a 48 px taskbar), so the magnifier is about 22 px across
    // beside the 30 px Start logo, as Windows draws 20 px glyphs beside
    // 24 px icons. The cap also keeps the icon theme on its small action
    // glyphs: the Windows Modern pack has full-colour icons with some of
    // the same names (window-duplicate) in apps/, which starts at 32 px.
    readonly property int glyphSize: Math.max(Kirigami.Units.iconSizes.small,
                                              Math.min(30, Math.round(Math.min(width, height) * 2 / 3)))

    hoverEnabled: true
    activeFocusOnTab: true

    onClicked: button.triggered()

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Enter:
        case Qt.Key_Return:
        case Qt.Key_Select:
            button.triggered();
            event.accepted = true;
            break;
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.description: description
    Accessible.onPressAction: button.triggered()

    Rectangle {
        id: tile

        anchors.fill: parent
        radius: 4
        color: {
            const c = Kirigami.Theme.textColor;
            if (button.showPressed) {
                // WinUI SubtleFillColorTertiary.
                return Qt.rgba(c.r, c.g, c.b, button.darkTheme ? 0.042 : 0.024);
            }
            return Qt.rgba(c.r, c.g, c.b, button.darkTheme ? 0.06 : 0.035);
        }
        border.width: 1
        border.color: {
            const c = Kirigami.Theme.textColor;
            return Qt.rgba(c.r, c.g, c.b, 0.03);
        }
        opacity: button.showHovered || button.showPressed ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
        }
    }

    Kirigami.Icon {
        id: glyph

        anchors.centerIn: parent
        width: button.glyphSize
        height: button.glyphSize
        source: button.iconName
        fallback: button.fallbackIconName
        scale: button.showPressed ? 0.9 : 1

        Behavior on scale {
            NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
        }
    }
}
