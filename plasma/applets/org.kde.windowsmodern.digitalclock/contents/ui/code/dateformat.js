/*
    Locale-aware date formats for the Windows Modern clock.

    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/
.pragma library

// The locale's short date format with a four-digit year, as the Windows
// taskbar clock shows it ("11.11.2026" in cs_CZ, "11/11/2026" in en_US).
// Qt's short formats often use a two-digit year ("dd.MM.yy").
function shortDateFullYear(shortFormat) {
    return shortFormat.replace(/(^|[^y])yy(?!y)/g, "$1yyyy");
}

// The locale's long date format with the year removed, as the Windows 11
// clock flyout shows it ("Wednesday, November 11" in en_US, "středa
// 11. listopadu" in cs_CZ, "11月11日水曜日" in ja_JP). Removing the year from
// the locale's own pattern keeps the word order and grammatical case right,
// which a fixed pattern such as "dddd, MMMM d" does not.
function longDateWithoutYear(longFormat) {
    let f = longFormat;
    // Year at the start: "yyyy年M月d日dddd", "yyyy. MMMM d., dddd".
    f = f.replace(/^\s*y+\s*(?:年|년|\.)?\s*/, "");
    // Year at the end, with a literal word before it ("'de'") or after it
    // ("'г'."): "dddd, d 'de' MMMM 'de' yyyy", "dddd, d MMMM yyyy 'г'.",
    // "dddd, MMMM d, yyyy", "dddd d. MMMM yyyy".
    f = f.replace(/(?:\s*'[^']*')?[\s,]*y+\s*(?:'[^']*'\.?|年|년)?\s*$/, "");
    // Year somewhere in the middle (rare): drop it with one adjacent separator.
    f = f.replace(/[\s,]*y+(?:年|년)?/, "");
    return f.trim();
}
