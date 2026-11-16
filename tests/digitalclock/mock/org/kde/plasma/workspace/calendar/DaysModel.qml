// Mock DaysModel: no calendar events.
import QtQuick

QtObject {
    function setPluginsManager(manager) {}
    function eventsForDate(date) { return []; }
}
