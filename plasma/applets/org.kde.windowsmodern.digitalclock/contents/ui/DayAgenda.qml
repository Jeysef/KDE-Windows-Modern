/*
    SPDX-FileCopyrightText: 2026 Windows Modern contributors

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.digitalclock as DigitalClockPrivate

import "code/dateformat.js" as DateFormat

// The picked day's events under the calendar: public holidays and your
// KDE calendars (the clock's calendar plugins), like Windows 10's agenda.
// Clicking a date in the calendar picks it.
ColumnLayout {
    id: agenda

    required property date date
    required property var events
    // Events listed before "+N more".
    property int maximumEvents: 4

    Win11Palette { id: palette }

    spacing: Kirigami.Units.smallSpacing

    Accessible.role: Accessible.List
    Accessible.name: dateLabel.text

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            id: dateLabel
            Layout.fillWidth: true
            textFormat: Text.PlainText
            elide: Text.ElideRight
            text: Qt.locale().toString(agenda.date,
                                       DateFormat.longDateWithoutYear(Qt.locale().dateFormat(Locale.LongFormat)))
            color: palette.text
            font.weight: Font.DemiBold
        }

        // Stock Plasma's "Add…": opens your calendar app (the text/calendar
        // handler, e.g. KOrganizer or Merkuro); shown only when one is installed.
        PlasmaComponents.ToolButton {
            visible: DigitalClockPrivate.ApplicationIntegration.calendarInstalled
            text: i18nc("@action:button Add event", "Add…")
            icon.name: "list-add"
            Accessible.description: i18nc("@info:tooltip", "Add a new event")
            onClicked: DigitalClockPrivate.ApplicationIntegration.launchCalendar()
        }
    }

    // "No events" takes as much height as one event (title + time line):
    // the popup grows upwards with the agenda, so a height change moved the
    // calendar under the pointer when a day with one event was picked.
    PlasmaComponents.Label {
        Layout.fillWidth: true
        Layout.preferredHeight: titleProbe.implicitHeight + timeProbe.implicitHeight
        visible: agenda.events.length === 0
        verticalAlignment: Text.AlignTop
        textFormat: Text.PlainText
        text: i18nc("@info:status the picked day has no events", "No events")
        color: palette.textSecondary
    }
    PlasmaComponents.Label { id: titleProbe; visible: false; text: "X" }
    PlasmaComponents.Label { id: timeProbe; visible: false; text: "X"; font: Kirigami.Theme.smallFont }

    Repeater {
        model: agenda.events.slice(0, agenda.maximumEvents)

        delegate: RowLayout {
            id: eventRow
            required property var modelData

            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing * 2

            // The event's calendar colour, as a bar (Windows 10's agenda style).
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 3
                radius: 1.5
                color: eventRow.modelData.eventColor || palette.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    text: eventRow.modelData.title
                    color: palette.text
                }

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    text: {
                        const ev = eventRow.modelData;
                        if (ev.isAllDay) {
                            return i18nc("@info an event lasting the whole day", "All day");
                        }
                        const fmt = Qt.locale().timeFormat(Locale.ShortFormat);
                        return Qt.locale().toString(ev.startDateTime, fmt) + " – "
                            + Qt.locale().toString(ev.endDateTime, fmt);
                    }
                    color: palette.textSecondary
                    font: Kirigami.Theme.smallFont
                }
            }
        }
    }

    PlasmaComponents.Label {
        Layout.fillWidth: true
        visible: agenda.events.length > agenda.maximumEvents
        textFormat: Text.PlainText
        text: i18ncp("@info more events on the picked day than are listed",
                     "+%1 more", "+%1 more", agenda.events.length - agenda.maximumEvents)
        color: palette.textSecondary
    }
}
