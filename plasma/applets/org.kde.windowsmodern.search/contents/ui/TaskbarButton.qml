/*
    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later

    A Windows 11 taskbar button: a square cell with a centred monochrome
    glyph (Glyph.qml) as large as the app icons, and the Icon Tasks
    buttons' hover tile. Pressed shows the same
    tile with WinUI's pressed fill and shrinks the glyph, as the Windows
    taskbar does.

    The tile can't be drawn with the theme's own widgets/tasks frame: its
    hover-center carries the running-app indicator bar, and these buttons
    are not apps. So it is painted from tasks.svg's geometry instead (see
    the tile below).

    Shared by the Search and Task View applets. Each package carries an
    identical copy (verify-all.sh checks that they don't drift); the file
    has no Plasma imports so tests can render it headless.
*/

import QtQuick

import org.kde.kirigami as Kirigami

MouseArea {
    id: button

    // The glyph: markup of a 24 x 24 SVG drawing in currentColor.
    property string glyph
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

    // Glyph size: Icon Tasks' rule for app icons, the cell minus the hover
    // frame's borders rounded down to a standard icon size: 32 px on a
    // 48 px taskbar. The glyphs fill ~20 of their 24 units, so they look
    // as large as the app icons' art (~28 px), as on Windows.
    readonly property int glyphSize: Kirigami.Units.iconSizes.roundedIconSize(
        Math.max(Kirigami.Units.iconSizes.small, Math.min(width, height) - 2 * tileInset))

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

    // The hover tile, drawn the way Plasma draws tasks.svg's "hover" frame
    // for the task buttons: 2 px transparent borders (hover-top/-left/...
    // are 2 px, fill:none) around hover-center, whose 26 x 26 tile (rx 4,
    // 1 px stroke) KSvg renders with QSvgRenderer into the rest of the
    // cell, stroke included (its 27 x 27 bounds). In a 48 px cell: a
    // 44 x 44 tile inset 2 px with ~6.5 px corners. This renders the same
    // rect the same way, minus hover-center's running-app bar.
    readonly property real tileInset: 2
    readonly property real tileSize: Math.max(0, Math.min(width, height) - 2 * tileInset)

    Image {
        id: tile

        // tasks.svg's colours: white on dark, black on light. Hover fill is
        // tasks.svg's 0.06 / 0.035 (WinUI SubtleFillColorSecondary,
        // #0FFFFFFF / #09000000); pressed is SubtleFillColorTertiary,
        // #0AFFFFFF / #06000000. The stroke is 0.03 in both.
        readonly property string ink: button.darkTheme ? "#ffffff" : "#000000"
        readonly property real fillOpacity: button.showPressed ? (button.darkTheme ? 10 / 255 : 6 / 255)
                                                               : (button.darkTheme ? 0.06 : 0.035)

        anchors.centerIn: parent
        width: button.tileSize
        height: button.tileSize
        // Rasterise at device pixels, as KSvg does, not scaled up.
        sourceSize: Qt.size(Math.ceil(width * Screen.devicePixelRatio), Math.ceil(height * Screen.devicePixelRatio))
        opacity: button.showHovered || button.showPressed ? 1 : 0
        source: "data:image/svg+xml," + encodeURIComponent(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='-0.5 -0.5 27 27' preserveAspectRatio='none'>"
            + "<rect width='26' height='26' rx='4' ry='4' fill='" + ink + "' fill-opacity='" + fillOpacity
            + "' stroke='" + ink + "' stroke-opacity='0.03' stroke-width='1'/></svg>")

        Behavior on opacity {
            NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
        }
    }

    Glyph {
        anchors.centerIn: parent
        width: button.glyphSize
        height: button.glyphSize
        svg: button.glyph
        scale: button.showPressed ? 0.9 : 1

        Behavior on scale {
            NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic }
        }
    }
}
