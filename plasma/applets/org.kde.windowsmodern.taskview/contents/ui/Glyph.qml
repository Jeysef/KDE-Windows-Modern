/*
    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later

    A monochrome glyph in the colour scheme's text colour: `svg` is the
    markup of a 24 x 24 drawing in currentColor (alpha is kept, so two-tone
    glyphs work). Rendered by Qt's SVG renderer at device pixels.

    Why not a theme icon: the Windows Modern pack has full-colour icons in
    apps/ (32 px and up) under the names of its small monochrome glyphs
    (window-duplicate, search; *-symbolic falls back to them too), so at
    the app icons' size the theme hands out the wrong art. Kirigami.Icon's
    isMask doesn't recolour a packaged file, and a shader would draw
    nothing on the software renderer.

    Shared by the Search and Task View applets; each package carries an
    identical copy (verify-all.sh checks).
*/

import QtQuick

import org.kde.kirigami as Kirigami

Image {
    id: glyph

    property string svg
    property color color: Kirigami.Theme.textColor

    readonly property string colorHex: "#" + [color.r, color.g, color.b]
        .map(c => Math.round(c * 255).toString(16).padStart(2, "0")).join("")

    sourceSize: Qt.size(Math.ceil(width * Screen.devicePixelRatio), Math.ceil(height * Screen.devicePixelRatio))
    opacity: color.a
    source: svg.length === 0 ? "" : "data:image/svg+xml," + encodeURIComponent(
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'>"
        + svg.replace(/currentColor/g, colorHex) + "</svg>")
}
