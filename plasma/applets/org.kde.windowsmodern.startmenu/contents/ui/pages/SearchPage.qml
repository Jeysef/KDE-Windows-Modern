/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   Search results shown in the left column when the search field has text.
 *   Uses Milou.ResultsView (the same component the default Plasma Kickoff
 *   uses) for the model/scrolling/keyboard logic, with a custom delegate
 *   and full-row collapsible category headers.
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou

import "../components"

Item {
    id: searchPage

    width: parent.width
    height: parent.height

    property alias resultsView: resultsView

    // Track collapsed categories as a comma-separated string so QML
    // binding updates fire reliably (var objects don't notify on nested
    // key changes).
    property string collapsedCategories: ""

    function isCollapsed(cat) {
        if (!cat) return false
        var parts = collapsedCategories.split(",")
        return parts.indexOf(cat) >= 0
    }

    function toggleCollapsed(cat) {
        if (!cat) return
        var parts = collapsedCategories ? collapsedCategories.split(",") : []
        var idx = parts.indexOf(cat)
        if (idx >= 0) {
            parts.splice(idx, 1)
        } else {
            parts.push(cat)
        }
        collapsedCategories = parts.join(",")
        resultsView.forceLayout()
    }

    function tryActivate(row, col) {
        if (resultsView.count > 0) {
            resultsView.currentIndex = 0;
            resultsView.forceActiveFocus();
        }
    }

    function activateFirstResult() {
        if (resultsView.count > 0) {
            resultsView.currentIndex = 0;
            resultsView.forceActiveFocus();
            resultsView.runCurrentIndex(null);
        }
    }

    // ── Filter pills (rounded chips) ────────────────────────────────────
    RowLayout {
        id: filterPillsWrapper
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.searching
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: [
                { label: i18n("All"),      filter: "all",       runner: "" },
                { label: i18n("Apps"),     filter: "apps",      runner: "krunner_services" },
                { label: i18n("Files"),    filter: "files",     runner: "krunner_placesrunner" },
                { label: i18n("Settings"), filter: "settings",  runner: "krunner_systemsettings" },
                { label: i18n("Actions"),  filter: "actions",   runner: "krunner_powerdevil" }
            ]
            delegate: Rectangle {
                required property var modelData

                readonly property bool active: kicker.searchRunnerFilter === modelData.filter

                Layout.alignment: Qt.AlignVCenter
                radius: Kirigami.Units.smallSpacing
                implicitHeight: Math.floor(Kirigami.Units.gridUnit * 1.4)
                implicitWidth: pillRow.implicitWidth + Kirigami.Units.largeSpacing * 2
                color: active
                       ? Kirigami.Theme.highlightColor
                       : (pillHover.containsMouse
                          ? Qt.rgba(Kirigami.Theme.textColor.r,
                                    Kirigami.Theme.textColor.g,
                                    Kirigami.Theme.textColor.b, 0.12)
                          : Qt.rgba(Kirigami.Theme.textColor.r,
                                    Kirigami.Theme.textColor.g,
                                    Kirigami.Theme.textColor.b, 0.06))
                border.width: active ? 0 : 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                       Kirigami.Theme.textColor.g,
                                       Kirigami.Theme.textColor.b, 0.15)
                Behavior on color { ColorAnimation { duration: 90 } }

                Row {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: active
                               ? Kirigami.Theme.highlightedTextColor
                               : Kirigami.Theme.textColor
                        font.family: "Segoe UI"
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
                        font.weight: active ? Font.DemiBold : Font.Normal
                    }
                }

                MouseArea {
                    id: pillHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        kicker.searchRunnerFilter = modelData.filter;
                        resultsView.singleRunner = modelData.runner;
                        // Force re-query: reset and re-apply the query
                        var q = bottomBarContent.searchText;
                        resultsView.queryString = "";
                        resultsView.queryString = q;
                    }
                }
            }
        }

        // Force left-justification of the pill cluster.
        Item { Layout.fillWidth: true }
    }

    // ── Search results (Milou ResultsView with custom delegate) ────────
    Milou.ResultsView {
        id: resultsView
        anchors {
            top: filterPillsWrapper.bottom
            topMargin: Kirigami.Units.largeSpacing
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        queryField: searchFieldInput
        // queryString is set explicitly by the shell on text change.
        limit: 50

        onActivated: root.closeMenu()

        PlasmaComponents3.ScrollBar.vertical: PlasmaComponents3.ScrollBar {
            policy: PlasmaComponents3.ScrollBar.AsNeeded
        }

        // Custom section header: full-row, collapsible
        section.delegate: Rectangle {
            width: resultsView.width
            height: headerRow.implicitHeight + Kirigami.Units.smallSpacing
            color: "transparent"

            readonly property string category: section

            RowLayout {
                id: headerRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    source: searchPage.isCollapsed(section) ? "arrow-right" : "arrow-down"
                    opacity: 0.6
                }

                PlasmaComponents3.Label {
                    text: section
                    color: Kirigami.Theme.disabledTextColor
                    font.family: "Segoe UI"
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Qt.rgba(Kirigami.Theme.textColor.r,
                                   Kirigami.Theme.textColor.g,
                                   Kirigami.Theme.textColor.b, 0.08)
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: searchPage.toggleCollapsed(section)
            }
        }

        // Custom delegate: icon left, text right, no inline category
        delegate: Item {
            id: resultDelegate

            width: resultsView.width
            implicitHeight: visible ? Math.floor(Kirigami.Units.gridUnit * 1.6) : 0

            required property int index
            required property var model

            readonly property bool isCurrent: ListView.isCurrentItem

            // Hover/selection highlight — matches ListItemDelegate style
            Rectangle {
                anchors.fill: parent
                anchors.margins: 0
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.hoverColor
                opacity: {
                    if (resultMouse.containsMouse) return 1.0
                    if (resultDelegate.isCurrent && resultsView.activeFocus) return 0.5
                    return 0.0
                }
                Behavior on opacity { NumberAnimation { duration: 90 } }
            }

            RowLayout {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.largeSpacing
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    source: resultDelegate.model.decoration || ""
                    animated: false
                }

                PlasmaComponents3.Label {
                    id: displayLabel
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Kirigami.Theme.textColor
                    text: resultDelegate.model.display || ""
                    font.family: "Segoe UI"
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
                    textFormat: Text.PlainText
                    verticalAlignment: Text.AlignVCenter
                }

                PlasmaComponents3.Label {
                    visible: text.length > 0
                    opacity: 0.6
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: Kirigami.Theme.textColor
                    text: resultDelegate.model.subtext || ""
                    font.family: "Segoe UI"
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize - 2
                    verticalAlignment: Text.AlignVCenter
                    Layout.maximumWidth: resultsView.width * 0.35
                }
            }

            MouseArea {
                id: resultMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    resultsView.currentIndex = resultDelegate.index
                    resultsView.runCurrentIndex()
                }
                onEntered: resultsView.currentIndex = resultDelegate.index
            }

            // Hide items in collapsed categories
            visible: !searchPage.isCollapsed(resultDelegate.ListView.section)
        }

        Keys.onUpPressed: event => {
            if (currentIndex <= 0) {
                event.accepted = true;
                bottomBarContent.focusSearch();
            }
        }
    }
}
