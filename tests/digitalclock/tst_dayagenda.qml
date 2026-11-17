// The picked day's agenda under the flyout calendar: "No events" for an
// empty day, a timed event with its times, an all-day event, and at most
// four events listed before "+N more".

import QtQuick
import QtTest
import "../../plasma/applets/org.kde.windowsmodern.digitalclock/contents/ui"

Item {
    id: root
    width: 360
    height: 400

    function i18nc(context, text) { return text; }
    function i18ncp(context, singular, plural, n) { return (n === 1 ? singular : plural).replace("%1", n); }

    function ev(title, allDay, h) {
        return {
            title: title,
            isAllDay: allDay,
            startDateTime: new Date(2026, 10, 26, h, 0),
            endDateTime: new Date(2026, 10, 26, h + 1, 30),
            eventColor: "#ff0000",
        };
    }

    DayAgenda {
        id: agenda
        width: 320
        date: new Date(2026, 10, 26)
        events: []
    }

    TestCase {
        name: "DayAgenda"
        when: windowShown

        function texts(item, out) {
            out = out || [];
            if (item.text !== undefined && item.visible) {
                out.push(item.text);
            }
            for (const child of item.children) {
                texts(child, out);
            }
            return out;
        }

        function test_noEvents() {
            agenda.events = [];
            waitForRendering(agenda);
            verify(texts(agenda).includes("No events"));
        }

        function test_timedAndAllDay() {
            agenda.events = [root.ev("Thanksgiving", true, 0), root.ev("Meeting", false, 9)];
            waitForRendering(agenda);
            const t = texts(agenda);
            verify(!t.includes("No events"));
            verify(t.includes("Thanksgiving"));
            verify(t.includes("All day"));
            verify(t.includes("Meeting"));
            const fmt = Qt.locale().timeFormat(Locale.ShortFormat);
            verify(t.includes(Qt.locale().toString(new Date(2026, 10, 26, 9, 0), fmt) + " – "
                              + Qt.locale().toString(new Date(2026, 10, 26, 10, 30), fmt)), t.join(" | "));
        }

        function test_moreThanFour() {
            agenda.events = [1, 2, 3, 4, 5, 6].map(i => root.ev("Event " + i, true, 0));
            waitForRendering(agenda);
            const t = texts(agenda);
            verify(t.includes("Event 4"));
            verify(!t.includes("Event 5"));
            verify(t.includes("+2 more"), t.join(" | "));
        }
    }
}
