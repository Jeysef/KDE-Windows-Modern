// The clock's date lines: the flyout's long date without the year, and
// the panel's short date with a four-digit year.

import QtQuick
import QtTest
import "../../plasma/applets/org.kde.windowsmodern.digitalclock/contents/ui/code/dateformat.js" as DateFormat

TestCase {
    name: "DateFormat"

    readonly property date day: new Date(2026, 10, 11)   // Wednesday 11 November 2026

    function dateLine(localeName) {
        const loc = Qt.locale(localeName);
        return loc.toString(day, DateFormat.longDateWithoutYear(loc.dateFormat(Locale.LongFormat)));
    }

    // Exact expectations for locales whose CLDR data is long-stable.
    function test_exact_data() {
        return [
            { tag: "cs_CZ", locale: "cs_CZ", expected: "středa 11. listopadu" },
            { tag: "en_US", locale: "en_US", expected: "Wednesday, November 11" },
        ];
    }
    function test_exact(data) {
        compare(dateLine(data.locale), data.expected);
    }

    // For every locale: no year left in the pattern or the output, and the
    // day of the month is still there.
    function test_noYear_data() {
        return ["cs_CZ", "sk_SK", "en_US", "en_GB", "de_DE", "fr_FR", "es_ES", "pt_BR", "pl_PL",
                "ru_RU", "uk_UA", "hu_HU", "ja_JP", "zh_CN", "ko_KR"].map(n => ({ tag: n, locale: n }));
    }
    function test_noYear(data) {
        const loc = Qt.locale(data.locale);
        const pattern = DateFormat.longDateWithoutYear(loc.dateFormat(Locale.LongFormat));
        verify(!/y/.test(pattern.replace(/'[^']*'/g, "")), "pattern still has a year token: " + pattern);
        const line = loc.toString(day, pattern);
        verify(line.indexOf("2026") === -1, "output contains the year: " + line);
        verify(line.indexOf("11") !== -1, "output lost the day of the month: " + line);
        verify(!/[,'\s]$/.test(line), "output ends with a dangling separator: " + line);
    }

    // The panel's date line: the locale's short date with a four-digit year.
    function test_shortDate_data() {
        return [
            { tag: "cs_CZ", locale: "cs_CZ", expected: "11.11.2026" },
            { tag: "en_US", locale: "en_US", expected: "11/11/2026" },
            { tag: "de_DE", locale: "de_DE", expected: "11.11.2026" },
        ];
    }
    function test_shortDate(data) {
        const loc = Qt.locale(data.locale);
        compare(loc.toString(day, DateFormat.shortDateFullYear(loc.dateFormat(Locale.ShortFormat))), data.expected);
    }

    function test_shortDateFullYear_patterns() {
        compare(DateFormat.shortDateFullYear("dd.MM.yy"), "dd.MM.yyyy");
        compare(DateFormat.shortDateFullYear("yy-MM-dd"), "yyyy-MM-dd");
        compare(DateFormat.shortDateFullYear("d/M/yyyy"), "d/M/yyyy");
    }
}
