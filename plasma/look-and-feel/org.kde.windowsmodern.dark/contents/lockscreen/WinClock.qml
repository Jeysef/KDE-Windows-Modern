/*
 * SPDX-FileCopyrightText: 2026 Jeysef
 *
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick
import org.kde.kirigami as Kirigami

import "dateformat.js" as DateFormat

Column {
    id: root

    property real opacityWhenInactive: 1
    property real opacityWhenActive: 0
    property bool uiVisible: false

    // The locale's long date without the year, as the Windows login screen
    // shows it. dateformat.js is a copy of the digital clock's.
    function dateLine(d: date): string {
        return Qt.locale().toString(d, DateFormat.longDateWithoutYear(Qt.locale().dateFormat(Locale.LongFormat)));
    }

    spacing: Kirigami.Units.smallSpacing / 2
    opacity: uiVisible ? opacityWhenActive : opacityWhenInactive

    Behavior on opacity {
        OpacityAnimator {
            duration: Kirigami.Units.veryLongDuration * 2
            easing.type: Easing.InOutQuad
        }
    }

    Text {
        id: timeText
        text: Qt.formatTime(new Date(), "HH:mm")
        font.family: WinStyle.fontFamily
        font.weight: Font.DemiBold
        font.pixelSize: WinStyle.clockTimePixelSize
        color: WinStyle.foregroundColor
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
        id: dateText
        text: root.dateLine(new Date())
        font.family: WinStyle.fontFamily
        font.pixelSize: WinStyle.clockDatePixelSize
        color: WinStyle.secondaryForegroundColor
        horizontalAlignment: Text.AlignHCenter
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            const now = new Date();
            timeText.text = Qt.formatTime(now, "HH:mm");
            dateText.text = root.dateLine(now);
        }
    }
}
