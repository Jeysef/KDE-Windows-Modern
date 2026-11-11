// Snap Layouts: the layout table, cell rectangles and pointer hit-testing.
import QtQuick
import QtTest
import "../../plasma/kwinscripts/org.kde.windowsmodern.snaplayouts/contents/ui/layouts.js" as Layouts

TestCase {
    name: "SnapLayouts"

    // Every layout tiles the work area exactly: cells cover the whole
    // area once (sum of areas is 1) and stay inside it.
    function test_layoutsTile() {
        for (let l = 0; l < Layouts.layouts.length; ++l) {
            let sum = 0;
            for (const c of Layouts.layouts[l]) {
                verify(c[0] >= 0 && c[1] >= 0 && c[0] + c[2] <= 1 + 1e-9 && c[1] + c[3] <= 1 + 1e-9, "inside, layout " + l);
                sum += c[2] * c[3];
            }
            fuzzyCompare(sum, 1, 1e-9, "covers the area, layout " + l);
        }
    }

    // Neighbouring cells share edges in whole pixels: no gaps, no overlap.
    function test_cellRectsShareEdges() {
        const area = { x: 0, y: 0, width: 1920, height: 1032 };
        const thirds = Layouts.layouts[2].map(c => Layouts.cellRect(area, c));
        compare(thirds[0].x + thirds[0].width, thirds[1].x);
        compare(thirds[1].x + thirds[1].width, thirds[2].x);
        compare(thirds[2].x + thirds[2].width, 1920);
        const half = Layouts.cellRect({ x: 0, y: 48, width: 1920, height: 1032 }, Layouts.layouts[0][1]);
        compare(half.x, 960); compare(half.y, 48); compare(half.width, 960); compare(half.height, 1032);
    }

    function test_cellAt() {
        const w = 72, h = 44, gap = 10;
        compare(Layouts.cellAt(10, 10, w, h, gap), { layout: 0, cell: 0 });      // 50/50, left
        compare(Layouts.cellAt(60, 10, w, h, gap), { layout: 0, cell: 1 });      // 50/50, right
        compare(Layouts.cellAt(75, 10, w, h, gap), null);                        // gap between diagrams
        compare(Layouts.cellAt(4 * (w + gap) + 60, 40, w, h, gap), { layout: 4, cell: 3 }); // quarters, bottom right
        compare(Layouts.cellAt(10, -1, w, h, gap), null);                        // above
        compare(Layouts.cellAt(6 * (w + gap) + 5, 10, w, h, gap), null);          // past the last diagram
    }
}
