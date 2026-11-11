// On-screen keyboard toggle (Windows' login screen offers it under its
// accessibility button). Shown only when a virtual keyboard is available.
// Loaded through a Loader: if the module is missing, only this button goes.
import QtQuick
import org.kde.plasma.workspace.keyboardlayout as Keyboards

StatusIconButton {
    visible: Keyboards.KWinVirtualKeyboard.available
    icon.name: Keyboards.KWinVirtualKeyboard.active ? "input-keyboard-virtual-on" : "input-keyboard-virtual"
    text: i18nd("plasma_login", "On-screen keyboard")
    onClicked: Keyboards.KWinVirtualKeyboard.active = !Keyboards.KWinVirtualKeyboard.active
}
