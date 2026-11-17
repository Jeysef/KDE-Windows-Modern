// Mock of org.kde.plasma.workspace.calendar's Calendar backend.
import QtQuick

QtObject {
    property int days
    property int weeks
    property int firstDayOfWeek
    property date today
    property date displayedDate
    property DaysModel daysModel: DaysModel {}
}
