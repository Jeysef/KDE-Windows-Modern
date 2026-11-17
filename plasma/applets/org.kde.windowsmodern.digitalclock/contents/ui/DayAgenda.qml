/*
    SPDX-FileCopyrightText: 2026 Windows Modern contributors

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

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

    PlasmaComponents.Label {
        Layout.fillWidth: true
        visible: agenda.events.length === 0
        textFormat: Text.PlainText
        text: i18nc("@info:status the picked day has no events", "No events")
        color: palette.textSecondary
    }

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
