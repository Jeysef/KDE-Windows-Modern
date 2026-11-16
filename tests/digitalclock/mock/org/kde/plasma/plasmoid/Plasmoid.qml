// Mock of org.kde.plasma.plasmoid: just the clock's calendar settings.
pragma Singleton
import QtQuick

QtObject {
    property QtObject configuration: QtObject {
        property int firstDayOfWeek: 1
        property bool showWeekNumbers: false
        property var enabledCalendarPlugins: []
    }
}
