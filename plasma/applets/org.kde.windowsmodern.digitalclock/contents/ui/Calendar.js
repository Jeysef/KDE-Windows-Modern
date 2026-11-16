/*
    SPDX-FileCopyrightText: 2026 Jeysef

    SPDX-License-Identifier: GPL-2.0-or-later
*/

function daysInMonth(year, month) {
    // month is 0-based (0 = January)
    return new Date(year, month + 1, 0).getDate();
}

function isoWeekNumber(date) {
    // ISO-8601 week number for a given date.
    const tmp = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    const dayNum = tmp.getUTCDay() || 7;
    tmp.setUTCDate(tmp.getUTCDate() + 4 - dayNum);
    const yearStart = new Date(Date.UTC(tmp.getUTCFullYear(), 0, 1));
    return Math.ceil((((tmp - yearStart) / 86400000) + 1) / 7);
}

function generateMonthGrid(year, month, today, selectedDate, firstDayOfWeek) {
    // Generate a 7x6 (42 day) grid for a month view, similar to upstream MonthView.
    // year/month are for the month being displayed (month is 0-based).
    // today and selectedDate are JS Date objects.
    // firstDayOfWeek: 0 = Sunday, 1 = Monday, etc.

    const daysInDisplayedMonth = daysInMonth(year, month);
    const firstDayOfMonth = new Date(year, month, 1);
    const startDayOfWeek = firstDayOfMonth.getDay(); // 0 = Sunday

    // Determine how many days from the previous month to show
    let daysFromPreviousMonth = startDayOfWeek - firstDayOfWeek;
    if (daysFromPreviousMonth < 0) {
        daysFromPreviousMonth += 7;
    }

    const gridStartDate = new Date(year, month, 1 - daysFromPreviousMonth);

    const result = [];
    for (let i = 0; i < 42; i++) {
        const date = new Date(gridStartDate);
        date.setDate(gridStartDate.getDate() + i);

        const isCurrentMonth = date.getMonth() === month && date.getFullYear() === year;
        const isToday = today !== undefined && today !== null
            && date.getFullYear() === today.getFullYear()
            && date.getMonth() === today.getMonth()
            && date.getDate() === today.getDate();
        const isSelected = selectedDate !== undefined && selectedDate !== null
            && date.getFullYear() === selectedDate.getFullYear()
            && date.getMonth() === selectedDate.getMonth()
            && date.getDate() === selectedDate.getDate();

        result.push({
            year: date.getFullYear(),
            month: date.getMonth(),
            day: date.getDate(),
            date: date,
            isCurrentMonth: isCurrentMonth,
            isToday: isToday,
            isSelected: isSelected,
        });
    }

    return result;
}

function generateYearGrid(year, today, monthNames) {
    // The year view's 16 tiles: the 12 months of the year, then the first
    // four months of the next year (dimmed). monthNames holds 12 names.
    const result = [];
    for (let i = 0; i < 16; i++) {
        const tileYear = year + Math.floor(i / 12);
        const month = i % 12;
        result.push({
            year: tileYear,
            month: month,
            text: monthNames[month],
            isCurrent: tileYear === today.getFullYear() && month === today.getMonth(),
            isDimmed: tileYear !== year,
        });
    }
    return result;
}

function generateDecadeGrid(year, today) {
    // The decade view's 16 tiles: the decade containing year, then the
    // first six years of the next decade (dimmed).
    const decadeStart = Math.floor(year / 10) * 10;
    const result = [];
    for (let i = 0; i < 16; i++) {
        const tileYear = decadeStart + i;
        result.push({
            year: tileYear,
            text: String(tileYear),
            isCurrent: tileYear === today.getFullYear(),
            isDimmed: i >= 10,
        });
    }
    return result;
}
