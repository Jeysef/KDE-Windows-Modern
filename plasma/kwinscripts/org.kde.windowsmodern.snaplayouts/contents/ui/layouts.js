/*
    Windows 11 Snap Layouts (as on a 16:9 screen). Each layout is a list of
    cells; a cell is x, y, width, height as fractions of the work area.

    SPDX-FileCopyrightText: 2026 Jeysef
    SPDX-License-Identifier: GPL-3.0-or-later
*/
.pragma library

const layouts = [
    [[0, 0, 1 / 2, 1], [1 / 2, 0, 1 / 2, 1]],
    [[0, 0, 2 / 3, 1], [2 / 3, 0, 1 / 3, 1]],
    [[0, 0, 1 / 3, 1], [1 / 3, 0, 1 / 3, 1], [2 / 3, 0, 1 / 3, 1]],
    [[0, 0, 1 / 2, 1], [1 / 2, 0, 1 / 2, 1 / 2], [1 / 2, 1 / 2, 1 / 2, 1 / 2]],
    [[0, 0, 1 / 2, 1 / 2], [1 / 2, 0, 1 / 2, 1 / 2], [0, 1 / 2, 1 / 2, 1 / 2], [1 / 2, 1 / 2, 1 / 2, 1 / 2]],
    [[0, 0, 1 / 4, 1], [1 / 4, 0, 1 / 2, 1], [3 / 4, 0, 1 / 4, 1]],
];

// A cell of a layout on a work area, in whole pixels (cells share edges).
function cellRect(area, cell) {
    const x0 = Math.round(area.x + cell[0] * area.width);
    const y0 = Math.round(area.y + cell[1] * area.height);
    const x1 = Math.round(area.x + (cell[0] + cell[2]) * area.width);
    const y1 = Math.round(area.y + (cell[1] + cell[3]) * area.height);
    return { x: x0, y: y0, width: x1 - x0, height: y1 - y0 };
}

// The layout cell at a point relative to the first diagram's top-left
// corner, for diagrams of size w x h laid out in a row with gap between
// them; or null.
function cellAt(lx, ly, w, h, gap) {
    if (ly < 0 || ly >= h || lx < 0) {
        return null;
    }
    const layout = Math.floor(lx / (w + gap));
    const dx = lx - layout * (w + gap);
    if (layout >= layouts.length || dx >= w) {
        return null;
    }
    const cells = layouts[layout];
    for (let i = 0; i < cells.length; ++i) {
        const c = cells[i];
        if (dx >= c[0] * w && dx < (c[0] + c[2]) * w && ly >= c[1] * h && ly < (c[1] + c[3]) * h) {
            return { layout: layout, cell: i };
        }
    }
    return null;
}
