/*
    SPDX-FileCopyrightText: 2026 Jeysef

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.kirigami as Kirigami

MouseArea {
    id: dayDelegate

    required property var dayData
    required property PlasmaCalendar.DaysModel daysModel
    required property int eventsRevision

    Win11Palette { id: palette }

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    // Events for this day, queried from the shared DaysModel.
    readonly property var dayEvents: {
        dayDelegate.eventsRevision;                 // refresh when events arrive
        return daysModel ? daysModel.eventsForDate(dayData.date) : [];
    }
    readonly property bool hasEvents: dayEvents && dayEvents.length > 0

    Accessible.role: Accessible.Button
    Accessible.name: dayData.day
        + (dayData.isToday ? i18n(", today") : "")
        + (dayData.isSelected ? i18n(", selected") : "")
    Accessible.onPressAction: calendarView.selectDate(dayData.date)  // as the month/year tiles

    onClicked: {
        calendarView.selectDate(dayData.date);
    }

    // One circle in every state (hover, press, picked ring, today), as on
    // Windows 11: the picked day used to turn into a rounded square while
    // hovered, and plain days had a square hover.
    Rectangle {
        id: dayBackground
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        radius: width / 2
        color: {
            if (dayData.isToday) {
                return palette.accent;
            } else if (dayDelegate.containsPress) {
                return palette.pressed;
            } else if (dayDelegate.containsMouse) {
                return palette.hover;
            }
            return "transparent";
        }
        // The picked day: an accent ring, as Windows 11 draws it (it was a
        // surface-coloured fill, invisible in dark mode).
        border.color: dayData.isSelected && !dayData.isToday ? palette.accent : "transparent"
        border.width: 2

        Behavior on color {
            ColorAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    scale: dayDelegate.containsPress ? 0.96 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.InOutQuad
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 1

        PlasmaComponents.Label {
            id: dayLabel
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            text: dayData.day
            color: {
                if (dayData.isToday) {
                    return palette.accentText;
                } else if (dayData.isCurrentMonth) {
                    return palette.text;
                }
                return palette.textDisabled;
            }
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
        }

        // Event dots.
        RowLayout {
            id: eventDotsRow
            Layout.alignment: Qt.AlignHCenter
            visible: dayDelegate.hasEvents
            spacing: 2

            Repeater {
                model: Math.min(3, dayDelegate.dayEvents.length)
                delegate: Rectangle {
                    required property int index
                    width: 4
                    height: 4
                    radius: 2
                    color: dayDelegate.dayEvents[index].eventColor || palette.accent
                }
            }
        }
    }

    QQC2.ToolTip {
        visible: dayDelegate.hasEvents && dayDelegate.containsMouse
        text: dayDelegate.dayEvents.map(ev => ev.title || "").join("\n")
        delay: 800
    }
}
