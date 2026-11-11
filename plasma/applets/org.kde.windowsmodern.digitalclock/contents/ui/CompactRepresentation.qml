/*
    SPDX-FileCopyrightText: 2026 Jeysef

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.clock as PlasmaClock
import org.kde.plasma.private.digitalclock as DigitalClockPrivate
import org.kde.kirigami as Kirigami

MouseArea {
    id: main
    objectName: "windowsmodern-digitalclock-compactrepresentation"

    required property var plasmoidItem

    activeFocusOnTab: true
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton

    Layout.fillWidth: false
    Layout.fillHeight: true

    // Advertise the compact representation's real horizontal size to the
    // Plasma panel layout. Without explicit minimum/preferred widths, Plasma
    // can allocate a narrower cell than the rendered clock text, which lets
    // the labels visually spill over neighbouring taskbar components.
    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth

    // Plasma controls the panel cell height. Keep the compact representation's
    // requested width tied to the labels' natural widths so text cannot paint
    // into neighbouring panel items.
    readonly property real panelHeight: parent ? parent.height : height
    readonly property real compactPadding: Math.max(0, Plasmoid.configuration.compactPadding)
    readonly property real maxContentHeight: Math.max(1, panelHeight * (1 - 2 * compactPadding))
    readonly property real horizontalPadding: Kirigami.Units.largeSpacing / 2
    readonly property real labelSpacing: Kirigami.Units.smallSpacing / 2
    readonly property int visibleLabelCount: 1 + (showDate ? 1 : 0) + (showTimezone ? 1 : 0)
    readonly property real availableLabelHeight: Math.max(
        1,
        maxContentHeight - labelSpacing * Math.max(0, visibleLabelCount - 1)
    )
    readonly property real contentImplicitWidth: Math.max(
        timeLabel.implicitWidth,
        dateLabel.visible ? dateLabel.implicitWidth : 0,
        timeZoneLabel.visible ? timeZoneLabel.implicitWidth : 0
    )

    implicitWidth: Math.ceil(contentImplicitWidth + 2 * horizontalPadding)
    implicitHeight: panelHeight

    // Last-resort paint boundary: even during transient panel relayouts (for
    // example while the time/date string changes width), never draw outside
    // the cell Plasma assigned to this applet.
    clip: true

    // Font configured by the user, or the theme font when automatic sizing is enabled.
    readonly property font baseFont: {
        if (Plasmoid.configuration.autoFontAndSize || Plasmoid.configuration.fontFamily.length === 0) {
            return Kirigami.Theme.defaultFont;
        }

        return Qt.font({
            family: Plasmoid.configuration.fontFamily,
            pointSize: Plasmoid.configuration.fontSize,
            weight: Plasmoid.configuration.fontWeight,
            styleName: Plasmoid.configuration.fontStyleName,
            italic: Plasmoid.configuration.italicText
        });
    }

    readonly property string timezoneString: {
        const showConfiguredTimezone = Plasmoid.configuration.showLocalTimezone
            || (Plasmoid.configuration.lastSelectedTimezone !== "Local" && !clock.isSystemTimeZone);

        if (!showConfiguredTimezone) {
            return "";
        }

        switch (Plasmoid.configuration.displayTimezoneFormat) {
        case 0: // Code
            return clock.timeZoneCode;
        case 1: // City
            return DigitalClockPrivate.TimeZonesI18n.i18nCity(clock.timeZone);
        case 2: // Offset from UTC
            return clock.timeZoneOffset;
        default:
            return "";
        }
    }

    readonly property bool showDate: Plasmoid.configuration.showDate
    readonly property bool showTimezone: timezoneString.length > 0

    // Height ratios for stacked labels. Visible ratios sum to 1.
    readonly property real timeHeightRatio: {
        if (showDate && showTimezone) {
            return 0.55;
        }
        if (showDate || showTimezone) {
            return 0.65;
        }
        return 1.0;
    }
    readonly property real dateHeightRatio: {
        if (showDate && showTimezone) {
            return 0.30;
        }
        return showDate ? 0.35 : 0;
    }
    readonly property real timezoneHeightRatio: showTimezone ? (showDate ? 0.15 : 0.35) : 0

    function pointToPixel(pointSize: real): int {
        const pixelsPerInch = Screen.pixelDensity * 25.4;
        return Math.round(pointSize / 72 * pixelsPerInch);
    }

    function dateFormatter(dateTime: date): string {
        switch (Plasmoid.configuration.dateFormat) {
        case "custom":
            return Qt.locale().toString(dateTime, Plasmoid.configuration.customDateFormat);
        case "isoDate":
            return Qt.formatDate(dateTime, Qt.ISODate);
        case "longDate":
            return Qt.formatDate(dateTime, Qt.locale(), Locale.LongFormat);
        default:
            return Qt.formatDate(dateTime, Qt.locale(), Locale.ShortFormat);
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: timeLabel.text + (dateLabel.visible ? ", " + dateLabel.text : "")

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            plasmoidItem.expanded = !plasmoidItem.expanded;
        }
    }

    PlasmaClock.Clock {
        id: clock
        timeZone: Plasmoid.configuration.lastSelectedTimezone
        trackSeconds: Plasmoid.configuration.showSeconds === 2 // Always
    }

    ColumnLayout {
        id: contentLayout

        anchors {
            fill: parent
            leftMargin: main.horizontalPadding
            rightMargin: main.horizontalPadding
            topMargin: Math.max(0, (main.panelHeight - main.maxContentHeight) / 2)
            bottomMargin: Math.max(0, (main.panelHeight - main.maxContentHeight) / 2)
        }
        spacing: main.labelSpacing

        PlasmaComponents.Label {
            id: timeLabel

            Layout.fillWidth: true
            Layout.preferredHeight: main.availableLabelHeight * main.timeHeightRatio

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText

            text: Qt.locale().toString(
                clock.dateTime,
                Plasmoid.configuration.showSeconds === 2
                    ? main.plasmoidItem.timeFormatWithSeconds
                    : main.plasmoidItem.timeFormat
            )

            font {
                family: main.baseFont.family
                weight: main.baseFont.weight
                italic: main.baseFont.italic
                styleName: main.baseFont.styleName
                pixelSize: {
                    const heightLimit = main.availableLabelHeight * main.timeHeightRatio;
                    if (Plasmoid.configuration.autoFontAndSize) {
                        return Math.max(1, Math.round(heightLimit));
                    }
                    return Math.max(1, Math.min(
                        main.pointToPixel(Plasmoid.configuration.fontSize),
                        Math.round(heightLimit)
                    ));
                }
                features: { "tnum": 1 }
            }
        }

        PlasmaComponents.Label {
            id: dateLabel

            visible: main.showDate
            Layout.fillWidth: true
            Layout.preferredHeight: main.availableLabelHeight * main.dateHeightRatio

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            text: main.dateFormatter(clock.dateTime)

            font {
                family: main.baseFont.family
                weight: main.baseFont.weight
                italic: main.baseFont.italic
                styleName: main.baseFont.styleName
                pixelSize: Math.max(1, Math.round(timeLabel.font.pixelSize * 0.65))
                features: { "tnum": 1 }
            }
        }

        PlasmaComponents.Label {
            id: timeZoneLabel

            visible: main.showTimezone
            Layout.fillWidth: true
            Layout.preferredHeight: main.availableLabelHeight * main.timezoneHeightRatio

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
            text: main.timezoneString

            font {
                family: main.baseFont.family
                weight: main.baseFont.weight
                italic: main.baseFont.italic
                styleName: main.baseFont.styleName
                pixelSize: Math.max(1, Math.round(timeLabel.font.pixelSize * 0.55))
                features: { "tnum": 1 }
            }
        }
    }
}
