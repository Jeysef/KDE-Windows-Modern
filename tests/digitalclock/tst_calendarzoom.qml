// The flyout calendar's zoom levels: the header zooms out month → year →
// decade, picking a tile zooms back in, and the arrows, Page Up/Down and
// the wheel page by month, year or decade. Uses mock Plasmoid and
// calendar backend modules (mock/).

import QtQuick
import QtTest
import "../../plasma/applets/org.kde.windowsmodern.digitalclock/contents/ui"

Item {
    id: root
    width: 400
    height: 500

    // CalendarView reads these from the applet's root, as in main.qml.
    property date currentTime: new Date(2026, 10, 16, 12, 0)   // Monday 16 November 2026
    function i18n(text) { return text; }
    function i18nc(context, text) { return text; }

    CalendarView {
        id: view
        width: 320
        focus: true
    }

    TestCase {
        name: "CalendarZoom"
        when: windowShown

        function findAll(item, predicate, out) {
            out = out || [];
            if (predicate(item)) {
                out.push(item);
            }
            for (const child of item.children) {
                findAll(child, predicate, out);
            }
            return out;
        }

        // An item the user can see: it and all its ancestors are visible and opaque.
        function shown(item) {
            for (let it = item; it && it !== root; it = it.parent) {
                if (!it.visible || it.opacity === 0) {
                    return false;
                }
            }
            return true;
        }

        // The only bold text in the calendar.
        function headerTitle() {
            return findAll(view, it => it.contentWidth !== undefined && it.font !== undefined && it.font.bold)[0];
        }

        function navButton(up) {
            return findAll(view, it => it.glyphColor !== undefined && it.up === up)[0];
        }

        // Tiles of the year/decade view currently on screen.
        function tiles() {
            return findAll(view, it => it.modelData !== undefined && it.modelData.isDimmed !== undefined && shown(it));
        }

        function tile(text) {
            return tiles().find(t => t.modelData.text === text);
        }

        function days() {
            return findAll(view, it => it.dayData !== undefined && shown(it));
        }

        // Waits until the zoom transition has finished.
        function settle() {
            const levels = findAll(view, it => it.level !== undefined && it.active !== undefined);
            compare(levels.length, 3);
            tryVerify(() => levels.every(l => l.opacity === (l.active ? 1 : 0)
                                              && l.scale === (l.active ? 1 : (view.zoom > l.level ? 0.9 : 1.1))));
        }

        function clickHeader() {
            const title = headerTitle();
            mouseClick(title, Math.min(10, title.contentWidth / 2), title.height / 2);
            settle();
        }

        function wheel(step) {
            mouseWheel(view, view.width / 2, view.height * 0.7, 0, step < 0 ? 120 : -120);
        }

        function init() {
            view.resetToToday();
            view.forceActiveFocus();
            settle();
        }

        function test_monthView() {
            compare(view.zoom, CalendarView.Zoom.Month);
            compare(headerTitle().text, Qt.locale().standaloneMonthName(10, Locale.LongFormat) + " 2026");
            compare(days().length, 42);
            compare(tiles().length, 0);
        }

        function test_headerZoomsOut() {
            const monthHeight = view.height;
            clickHeader();
            compare(view.zoom, CalendarView.Zoom.Year);
            compare(headerTitle().text, "2026");
            compare(days().length, 0);
            const months = tiles();
            compare(months.length, 16);
            compare(months.filter(t => t.modelData.isCurrent).map(t => t.modelData.text),
                    [Qt.locale().standaloneMonthName(10, Locale.ShortFormat)]);
            compare(months.filter(t => t.modelData.isDimmed).length, 4);
            compare(view.height, monthHeight, "zooming out must not resize the calendar");

            clickHeader();
            compare(view.zoom, CalendarView.Zoom.Decade);
            compare(headerTitle().text, "2020 – 2029");
            const years = tiles();
            compare(years.map(t => t.modelData.text)[0], "2020");
            compare(years.map(t => t.modelData.text)[15], "2035");
            compare(years.filter(t => t.modelData.isCurrent).map(t => t.modelData.text), ["2026"]);
            compare(years.filter(t => t.modelData.isDimmed).map(t => t.modelData.text),
                    ["2030", "2031", "2032", "2033", "2034", "2035"]);

            // The decade view is the last level: the header does nothing there.
            clickHeader();
            compare(view.zoom, CalendarView.Zoom.Decade);
            compare(view.height, monthHeight);
        }

        function test_pickingZoomsIn() {
            clickHeader();
            clickHeader();
            mouseClick(tile("2031"));
            settle();
            compare(view.zoom, CalendarView.Zoom.Year);
            compare(headerTitle().text, "2031");

            mouseClick(tile(Qt.locale().standaloneMonthName(2, Locale.ShortFormat)));
            settle();
            compare(view.zoom, CalendarView.Zoom.Month);
            compare(view.displayedYear, 2031);
            compare(view.displayedMonth, 2);
            compare(days().length, 42);
        }

        function test_dimmedMonthOpensNextYear() {
            clickHeader();
            const january = tiles().filter(t => t.modelData.text === Qt.locale().standaloneMonthName(0, Locale.ShortFormat));
            compare(january.length, 2);
            mouseClick(january[1]);
            settle();
            compare(view.zoom, CalendarView.Zoom.Month);
            compare(view.displayedYear, 2027);
            compare(view.displayedMonth, 0);
        }

        function test_wheelPages() {
            wheel(1);
            compare(view.displayedMonth, 11);
            wheel(-1);
            wheel(-1);
            compare(view.displayedMonth, 9);
            compare(view.zoom, CalendarView.Zoom.Month);

            clickHeader();
            wheel(1);
            compare(view.displayedYear, 2027);
            compare(headerTitle().text, "2027");
            wheel(-1);
            wheel(-1);
            compare(view.displayedYear, 2025);

            clickHeader();
            wheel(1);
            compare(headerTitle().text, "2030 – 2039");
            wheel(-1);
            wheel(-1);
            compare(headerTitle().text, "2010 – 2019");
            compare(view.zoom, CalendarView.Zoom.Decade);
        }

        function test_arrowsPageByLevel() {
            mouseClick(navButton(false));
            compare(view.displayedMonth, 11);
            mouseClick(navButton(true));
            compare(view.displayedMonth, 10);

            clickHeader();
            mouseClick(navButton(false));
            compare(view.displayedYear, 2027);
            compare(view.displayedMonth, 10);

            clickHeader();
            mouseClick(navButton(true));
            compare(headerTitle().text, "2010 – 2019");
        }

        function test_keyboard() {
            // Month view: arrows move the selection, Page Down flips the month.
            keyClick(Qt.Key_Right);
            compare(view.selectedDate.getDate(), 17);
            keyClick(Qt.Key_PageDown);
            compare(view.displayedMonth, 11);

            // Zoomed out: Page Up/Down page by year, arrows leave the selection alone.
            clickHeader();
            keyClick(Qt.Key_PageUp);
            compare(view.displayedYear, 2025);
            keyClick(Qt.Key_Left);
            keyClick(Qt.Key_Down);
            compare(view.selectedDate.getDate(), 17);
            compare(view.zoom, CalendarView.Zoom.Year);

            // Escape is left to the popup (it closes the flyout).
            keyClick(Qt.Key_Escape);
            compare(view.zoom, CalendarView.Zoom.Year);

            // Home goes back to today's month.
            keyClick(Qt.Key_Home);
            settle();
            compare(view.zoom, CalendarView.Zoom.Month);
            compare(view.displayedYear, 2026);
            compare(view.displayedMonth, 10);
        }
    }
}
