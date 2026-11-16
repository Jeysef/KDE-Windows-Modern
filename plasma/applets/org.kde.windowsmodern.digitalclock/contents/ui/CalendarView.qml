/*
    SPDX-FileCopyrightText: 2026 Jeysef

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.kirigami as Kirigami

import "Calendar.js" as Calendar

ColumnLayout {
    id: calendarView

    Win11Palette { id: palette }

    // Zoom levels: clicking the header zooms out, picking a tile zooms in.
    enum Zoom { Month, Year, Decade }

    // The applet root (main.qml): the clock and the popup's expanded state.
    readonly property var applet: root
    readonly property date today: applet.currentTime

    // Year/month currently displayed by the calendar (0-based month).
    property int displayedYear: today.getFullYear()
    property int displayedMonth: today.getMonth()
    property date selectedDate: today
    property int zoom: CalendarView.Zoom.Month

    readonly property int decadeStart: Math.floor(displayedYear / 10) * 10

    readonly property int firstDayOfWeek: Plasmoid.configuration.firstDayOfWeek > -1
        ? Plasmoid.configuration.firstDayOfWeek
        : Qt.locale().firstDayOfWeek

    readonly property bool showWeekNumbers: Plasmoid.configuration.showWeekNumbers

    readonly property PlasmaCalendar.EventPluginsManager eventPluginsManager: PlasmaCalendar.EventPluginsManager {
        enabledPlugins: Plasmoid.configuration.enabledCalendarPlugins
    }

    readonly property PlasmaCalendar.Calendar calendarBackend: PlasmaCalendar.Calendar {
        days: 7
        weeks: 6
        firstDayOfWeek: calendarView.firstDayOfWeek
        today: calendarView.today
        displayedDate: new Date(calendarView.displayedYear, calendarView.displayedMonth, 1)

        Component.onCompleted: {
            calendarBackend.daysModel.setPluginsManager(calendarView.eventPluginsManager);
        }
    }

    // First date shown in the 6-week grid.
    readonly property date gridStartDate: {
        const firstDayOfMonth = new Date(calendarView.displayedYear, calendarView.displayedMonth, 1);
        const startDayOfWeek = firstDayOfMonth.getDay();
        let daysFromPreviousMonth = startDayOfWeek - calendarView.firstDayOfWeek;
        if (daysFromPreviousMonth < 0) {
            daysFromPreviousMonth += 7;
        }
        return new Date(calendarView.displayedYear, calendarView.displayedMonth, 1 - daysFromPreviousMonth);
    }

    spacing: Kirigami.Units.smallSpacing
    focus: true

    function resetToToday() {
        selectDate(today);
        zoom = CalendarView.Zoom.Month;
    }

    function selectDate(date) {
        displayedYear = date.getFullYear();
        displayedMonth = date.getMonth();
        selectedDate = date;
    }

    function previousMonth() {
        let newMonth = calendarView.displayedMonth - 1;
        let newYear = calendarView.displayedYear;
        if (newMonth < 0) {
            newMonth = 11;
            newYear--;
        }
        calendarView.displayedMonth = newMonth;
        calendarView.displayedYear = newYear;
    }

    function nextMonth() {
        let newMonth = calendarView.displayedMonth + 1;
        let newYear = calendarView.displayedYear;
        if (newMonth > 11) {
            newMonth = 0;
            newYear++;
        }
        calendarView.displayedMonth = newMonth;
        calendarView.displayedYear = newYear;
    }

    // The chevrons, Page Up/Down and the wheel page by month, year or
    // decade, depending on the zoom level.
    function page(step) {
        switch (zoom) {
        case CalendarView.Zoom.Month:
            if (step < 0) {
                previousMonth();
            } else {
                nextMonth();
            }
            break;
        case CalendarView.Zoom.Year:
            displayedYear += step;
            yearGrid.crossfade();
            break;
        case CalendarView.Zoom.Decade:
            displayedYear += 10 * step;
            decadeGrid.crossfade();
            break;
        }
    }

    function zoomOut() {
        if (zoom < CalendarView.Zoom.Decade) {
            zoom++;
        }
    }

    // Like Windows, the flyout always opens on today's month.
    Connections {
        target: calendarView.applet
        function onExpandedChanged() {
            if (calendarView.applet.expanded) {
                calendarView.resetToToday();
            }
        }
    }

    onDisplayedMonthChanged: calendarGrid.crossfade()
    onDisplayedYearChanged: calendarGrid.crossfade()

    Keys.onPressed: event => {
        if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
            calendarView.page(event.key === Qt.Key_PageUp ? -1 : 1);
            event.accepted = true;
            return;
        }
        // The arrow keys move the selected day, so only the month view uses them.
        if (calendarView.zoom !== CalendarView.Zoom.Month && event.key !== Qt.Key_Home) {
            return;
        }
        const d = new Date(calendarView.selectedDate);
        switch (event.key) {
        case Qt.Key_Left:
            d.setDate(d.getDate() - 1);
            calendarView.selectDate(d);
            event.accepted = true;
            break;
        case Qt.Key_Right:
            d.setDate(d.getDate() + 1);
            calendarView.selectDate(d);
            event.accepted = true;
            break;
        case Qt.Key_Up:
            d.setDate(d.getDate() - 7);
            calendarView.selectDate(d);
            event.accepted = true;
            break;
        case Qt.Key_Down:
            d.setDate(d.getDate() + 7);
            calendarView.selectDate(d);
            event.accepted = true;
            break;
        case Qt.Key_Home:
            calendarView.resetToToday();
            event.accepted = true;
            break;
        }
    }

    // A zoom level's content: the active level is shown at full size, the
    // others are faded out, smaller (finer levels) or larger (coarser ones).
    component ZoomLevel: Item {
        required property int level
        readonly property bool active: calendarView.zoom === level

        visible: opacity > 0
        enabled: active
        opacity: active ? 1 : 0
        scale: active ? 1 : (calendarView.zoom > level ? 0.9 : 1.1)

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    // Month/year navigation header. The title zooms out when clicked.
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            id: headerTitle
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            text: {
                switch (calendarView.zoom) {
                case CalendarView.Zoom.Year:
                    return String(calendarView.displayedYear);
                case CalendarView.Zoom.Decade:
                    return calendarView.decadeStart + " – " + (calendarView.decadeStart + 9);
                }
                return Qt.locale().standaloneMonthName(calendarView.displayedMonth, Locale.LongFormat)
                       + " " + calendarView.displayedYear;
            }
            // The decade is the last level: greyed like the dimmed years.
            color: headerButton.enabled ? palette.text : palette.textDisabled
            font {
                weight: Font.Bold
                pixelSize: Kirigami.Units.gridUnit
            }

            Accessible.role: headerButton.enabled ? Accessible.Button : Accessible.StaticText
            Accessible.onPressAction: calendarView.zoomOut()

            // Hover/press background around the title text, behind it; the
            // decade level is the last one, so there it is plain text.
            MouseArea {
                id: headerButton
                z: -1
                x: -Kirigami.Units.smallSpacing
                anchors.verticalCenter: parent.verticalCenter
                width: headerTitle.contentWidth + 2 * Kirigami.Units.smallSpacing
                height: Kirigami.Units.gridUnit * 1.5
                enabled: calendarView.zoom !== CalendarView.Zoom.Decade
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: calendarView.zoomOut()

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: headerButton.containsPress ? palette.pressed
                                                      : (headerButton.containsMouse ? palette.hover : "transparent")

                    Behavior on color {
                        ColorAnimation {
                            duration: Kirigami.Units.shortDuration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }

        CalendarNavButton {
            up: true
            glyphColor: palette.text
            hoverColor: palette.hover
            pressedColor: palette.pressed
            onClicked: calendarView.page(-1)
            Accessible.name: i18n("Previous")
        }

        CalendarNavButton {
            up: false
            glyphColor: palette.text
            hoverColor: palette.hover
            pressedColor: palette.pressed
            onClicked: calendarView.page(1)
            Accessible.name: i18n("Next")
        }
    }

    // The month view, or the year/decade view zoomed out in its place.
    Item {
        id: zoomHost
        Layout.fillWidth: true
        Layout.preferredHeight: monthView.implicitHeight
        clip: true

        ZoomLevel {
            anchors.fill: parent
            level: CalendarView.Zoom.Month

            ColumnLayout {
                id: monthView
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                spacing: calendarView.spacing

                // Day-of-week header.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents.Label {
                        visible: calendarView.showWeekNumbers
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        textFormat: Text.PlainText
                        text: i18nc("@label week number column header", "Wk")
                        color: palette.textSecondary
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    }

                    Repeater {
                        model: 7
                        delegate: PlasmaComponents.Label {
                            required property int index
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            textFormat: Text.PlainText
                            text: Qt.locale().standaloneDayName((calendarView.firstDayOfWeek + index) % 7, Locale.ShortFormat)
                            color: palette.textSecondary
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        }
                    }
                }

                // Calendar grid with optional week number column.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    ColumnLayout {
                        visible: calendarView.showWeekNumbers
                        spacing: calendarGrid.spacing
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5

                        Repeater {
                            model: 6
                            delegate: PlasmaComponents.Label {
                                required property int index
                                Layout.preferredHeight: calendarGrid.cellHeight
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                textFormat: Text.PlainText
                                text: Calendar.isoWeekNumber(new Date(calendarView.gridStartDate.getTime() + index * 7 * 86400000))
                                color: palette.textSecondary
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            }
                        }
                    }

                    CalendarGrid {
                        id: calendarGrid
                        Layout.fillWidth: true
                        Layout.preferredHeight: calendarGrid.cellHeight * 6 + calendarGrid.spacing * 5
                    }
                }
            }
        }

        ZoomLevel {
            anchors.fill: parent
            level: CalendarView.Zoom.Year

            CalendarZoomGrid {
                id: yearGrid
                anchors.fill: parent
                tiles: Calendar.generateYearGrid(calendarView.displayedYear, calendarView.today,
                    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].map(m => Qt.locale().standaloneMonthName(m, Locale.ShortFormat)))
                onPicked: index => {
                    const tile = tiles[index];
                    calendarView.displayedYear = tile.year;
                    calendarView.displayedMonth = tile.month;
                    calendarView.zoom = CalendarView.Zoom.Month;
                }
            }
        }

        ZoomLevel {
            anchors.fill: parent
            level: CalendarView.Zoom.Decade

            CalendarZoomGrid {
                id: decadeGrid
                anchors.fill: parent
                tiles: Calendar.generateDecadeGrid(calendarView.displayedYear, calendarView.today)
                onPicked: index => {
                    calendarView.displayedYear = tiles[index].year;
                    calendarView.zoom = CalendarView.Zoom.Year;
                }
            }
        }

        // Scroll wheel over the grid pages at the current zoom level.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                calendarView.page(wheel.angleDelta.y > 0 ? -1 : 1);
                wheel.accepted = true;
            }
        }
    }
}
