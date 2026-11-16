/*
    SPDX-FileCopyrightText: 2026 Jeysef <jeysef@users.noreply.github.com>
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick

import org.kde.plasma.configuration

// i18n() is put into the context by Plasma, where qmllint cannot see it.
// qmllint disable unqualified
ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "edit-find"
        source: "ConfigGeneral.qml"
    }
}
