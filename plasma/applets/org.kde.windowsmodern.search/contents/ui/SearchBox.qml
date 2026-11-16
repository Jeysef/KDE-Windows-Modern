/*
    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later

    The Windows 11 taskbar search box: a pill with a magnifier and the
    placeholder "Search". Clicking it opens Start with its search field
    focused; it takes no typing itself.

    Geometry, in a 48 px taskbar (scaled with the panel's thickness):
    - 220 x 32 px. The width is the stock box's: Windhawk taskbar themes
      select the default box as SearchButtonRootGrid[Width=220]
      (github.com/ramensoftware/windows-11-taskbar-styling-guide). The
      height is the 32 px they give the matching search background; 2026
      Insider builds (26300.8935) add 4 px to it, not shipped yet.
    - Fully rounded ends, as the guide's "pill-shaped" search background.
    - Glyph 16 px, 12 px in from the left edge, 8 px before the text.
    Colours are WinUI's (microsoft-ui-xaml Common_themeresources_any.xaml):
    fill ControlFillColorDefault, hover ControlFillColorSecondary, pressed
    ControlFillColorTertiary; 1 px ControlStrokeColorDefault border;
    placeholder TextFillColorSecondary.

    No Plasma imports, so tests can render it headless.
*/

import QtQuick

import org.kde.kirigami as Kirigami

MouseArea {
    id: box

    // The magnifier: markup of a 24 x 24 SVG drawing in currentColor.
    property string glyph
    property string text
    property string description
    property string placeholder

    // Preview/test hooks: draw a state without a pointer.
    property bool forceHovered: false
    property bool forcePressed: false

    signal triggered()

    readonly property bool showPressed: forcePressed || containsPress
    readonly property bool showHovered: forceHovered || containsMouse || activeFocus

    readonly property bool darkTheme: Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.textColor)
                                      === Kirigami.ColorUtils.Light

    // Everything follows the panel's thickness; 48 px is the reference.
    readonly property real thickness: height
    readonly property int boxHeight: Math.max(16, Math.round(thickness * 32 / 48))
    readonly property int boxWidth: Math.round(boxHeight * 220 / 32)
    // The gap to the neighbouring buttons on each side.
    readonly property int sideMargin: Math.round((thickness - boxHeight) / 4)
    // What the applet asks the panel for.
    readonly property int preferredWidth: boxWidth + 2 * sideMargin

    hoverEnabled: true
    activeFocusOnTab: true

    onClicked: box.triggered()

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Enter:
        case Qt.Key_Return:
        case Qt.Key_Select:
            box.triggered();
            event.accepted = true;
            break;
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.description: description
    Accessible.onPressAction: box.triggered()

    Rectangle {
        id: pill

        // WinUI ControlFillColor{Default,Secondary,Tertiary} and
        // ControlStrokeColorDefault, dark / light.
        readonly property color restFill: box.darkTheme ? Qt.rgba(1, 1, 1, 0x0F / 255) : Qt.rgba(1, 1, 1, 0xB3 / 255)
        readonly property color hoverFill: box.darkTheme ? Qt.rgba(1, 1, 1, 0x15 / 255)
                                                         : Qt.rgba(0xF9 / 255, 0xF9 / 255, 0xF9 / 255, 0x80 / 255)
        readonly property color pressedFill: box.darkTheme ? Qt.rgba(1, 1, 1, 0x08 / 255)
                                                           : Qt.rgba(0xF9 / 255, 0xF9 / 255, 0xF9 / 255, 0x4D / 255)

        anchors.verticalCenter: parent.verticalCenter
        x: box.sideMargin
        width: Math.max(box.boxHeight, box.width - 2 * box.sideMargin)
        height: box.boxHeight
        radius: height / 2
        color: box.showPressed ? pressedFill : (box.showHovered ? hoverFill : restFill)
        border.width: 1
        border.color: box.darkTheme ? Qt.rgba(1, 1, 1, 0x12 / 255) : Qt.rgba(0, 0, 0, 0x0F / 255)

        Behavior on color {
            ColorAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
        }

        Glyph {
            id: magnifier

            anchors.verticalCenter: parent.verticalCenter
            x: Math.round(box.boxHeight * 12 / 32)
            width: Math.round(box.boxHeight / 2)
            height: width
            svg: box.glyph
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: magnifier.right
            anchors.leftMargin: Math.round(box.boxHeight / 4)
            anchors.right: parent.right
            anchors.rightMargin: Math.round(box.boxHeight * 12 / 32)
            text: box.placeholder
            elide: Text.ElideRight
            font: Kirigami.Theme.defaultFont
            // WinUI TextFillColorSecondary: #C5FFFFFF / #9E000000.
            color: box.darkTheme ? Qt.rgba(1, 1, 1, 0xC5 / 255) : Qt.rgba(0, 0, 0, 0x9E / 255)
            Accessible.ignored: true
        }
    }
}
