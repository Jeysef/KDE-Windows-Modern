/*
    Windows 11 defaults for which tray icons show, and in what order.

    SPDX-FileCopyrightText: 2026 Jeysef
    SPDX-License-Identifier: GPL-2.0-or-later
*/
#pragma once

#include <QDir>
#include <QFile>
#include <QList>
#include <QString>

namespace WindowsTray
{
// Windows 11 ends the tray with these, left to right, right before the clock:
// input language, network, volume, battery.
inline const QList<QString> &tail()
{
    static const QList<QString> ids = {
        QStringLiteral("org.kde.plasma.keyboardlayout"),
        QStringLiteral("org.kde.plasma.networkmanagement"),
        QStringLiteral("org.kde.plasma.volume"),
        QStringLiteral("org.kde.plasma.battery"),
    };
    return ids;
}

// True on laptops: the kernel lists a system battery (not a mouse's or a
// headset's, whose scope is "Device").
inline bool hasSystemBattery()
{
    static const bool found = [] {
        const QDir supplies(QStringLiteral("/sys/class/power_supply"));
        for (const QString &name : supplies.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
            QFile type(supplies.filePath(name + QStringLiteral("/type")));
            QFile scope(supplies.filePath(name + QStringLiteral("/scope")));
            const bool isBattery = type.open(QIODevice::ReadOnly) && type.readAll().trimmed() == "Battery";
            const bool isPeripheral = scope.open(QIODevice::ReadOnly) && scope.readAll().trimmed() == "Device";
            if (isBattery && !isPeripheral) {
                return true;
            }
        }
        return false;
    }();
    return found;
}

// Always in the tray on Windows while they exist, even when Plasma marks
// them passive (the battery does when full and on the charger). The input
// language is left out: Windows hides it too when there is only one.
inline bool alwaysShown(const QString &itemId)
{
    if (itemId == QLatin1String("org.kde.plasma.battery")) {
        return hasSystemBattery();
    }
    return itemId == QLatin1String("org.kde.plasma.networkmanagement")
        || itemId == QLatin1String("org.kde.plasma.volume");
}

// Not in the tray nor behind the chevron unless pinned, set to "Always
// hidden" (which puts them behind the chevron) or needing attention:
// - Bluetooth and Brightness & Color: Quick Settings below the chevron's
//   grid already has their toggle/slider, and its ">" opens their page.
// - Weather (a widget), Vaults and the X11 video bridge: KDE plumbing that
//   Windows has no tray icon for.
// Keeps the grid to three rows, so the flyout does not scroll.
inline bool hiddenByDefault(const QString &itemId)
{
    static const QList<QString> ids = {
        QStringLiteral("org.kde.plasma.bluetooth"),
        QStringLiteral("org.kde.plasma.brightness"),
        QStringLiteral("org.kde.plasma.weather"),
        QStringLiteral("org.kde.plasma.vault"),
        QStringLiteral("Xwayland Video Bridge"), // xwaylandvideobridge's StatusNotifierItem
    };
    return ids.contains(itemId);
}

// Icons that appear in the tray without being pinned. As on Windows 11,
// every other icon (apps, Bluetooth, clipboard, brightness...) waits behind
// the chevron until it needs attention or the user pins it ("Always shown").
inline bool shownByDefault(const QString &itemId)
{
    return tail().contains(itemId)
        || itemId == QLatin1String("org.kde.plasma.notifications")
        || itemId == QLatin1String("org.kde.plasma.cameraindicator"); // privacy: camera in use
}
}
