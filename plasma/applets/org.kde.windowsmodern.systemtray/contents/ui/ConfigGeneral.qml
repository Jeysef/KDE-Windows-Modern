/*
    SPDX-FileCopyrightText: 2020 Konrad Materka <materka@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

ColumnLayout {
    spacing: Kirigami.Units.largeSpacing

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Scale icons to fit panel:")
        }

        QQC2.ComboBox {
            id: sizeChooser
            model: [
                { "label": i18n("Small (fixed size)"), "value": false },
                { "label": i18n("Scale with Panel"), "value": true }
            ]
            textRole: "label"
            currentIndex: Plasmoid.configuration.scaleIconsToFit ? 1 : 0
            onActivated: Plasmoid.configuration.scaleIconsToFit = model[currentIndex].value
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Icon spacing:")
        }

        QQC2.ComboBox {
            id: spacingChooser
            model: [
                { "label": i18n("Small"), "value": 1 },
                { "label": i18n("Normal"), "value": 2 },
                { "label": i18n("Large"), "value": 6 }
            ]
            textRole: "label"
            currentIndex: {
                switch (Plasmoid.configuration.iconSpacing) {
                    case 1: return 0;
                    case 2: return 1;
                    case 6: return 2;
                    default: return 1;
                }
            }
            onActivated: Plasmoid.configuration.iconSpacing = model[currentIndex].value
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Reverse icon order:")
        }

        PlasmaComponents3.Switch {
            checked: Plasmoid.configuration.reverseIconOrder
            onToggled: Plasmoid.configuration.reverseIconOrder = checked
        }
    }

    RowLayout {
        Layout.fillWidth: true

        PlasmaComponents3.Label {
            text: i18n("Always show all icons:")
        }

        PlasmaComponents3.Switch {
            checked: Plasmoid.configuration.showAllItems
            onToggled: Plasmoid.configuration.showAllItems = checked
        }
    }
}
