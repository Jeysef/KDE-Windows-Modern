import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.icon: "preferences-system-windows"
    Plasmoid.title: i18n("Quick Settings")
    Plasmoid.backgroundHints: PlasmaCore.Types.StandardBackground

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: QuickSettings {}
}
