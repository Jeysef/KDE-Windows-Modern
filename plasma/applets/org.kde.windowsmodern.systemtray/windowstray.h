/*
    Windows 11 defaults for which tray icons show, and in what order.

    SPDX-FileCopyrightText: 2026 Jeysef
    SPDX-License-Identifier: GPL-2.0-or-later
*/
#pragma once

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
