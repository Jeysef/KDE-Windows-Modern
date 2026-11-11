// Live battery icon: charge level in steps of ten, charging state. Hidden
// on machines without a battery, as on Windows.
// Loaded through a Loader: if the battery module is missing, only this goes.
import QtQuick
import org.kde.plasma.private.battery

StatusIconButton {
    BatteryControlModel {
        id: battery
    }
    visible: battery.hasCumulative
    icon.name: {
        const step = Math.min(100, Math.max(0, Math.round(battery.percent / 10) * 10));
        return "battery-" + String(step).padStart(3, "0") + (battery.pluggedIn ? "-charging" : "");
    }
    text: battery.pluggedIn
        ? i18nd("plasma_shell_org.kde.plasma.desktop", "Battery: %1% (charging)", battery.percent)
        : i18nd("plasma_shell_org.kde.plasma.desktop", "Battery: %1%", battery.percent)
}
