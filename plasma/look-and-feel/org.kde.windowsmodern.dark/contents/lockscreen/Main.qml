import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import org.kde.kirigami as Kirigami
import org.kde.breeze.components as BreezeComponents
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

import org.kde.plasma.login as PlasmaLogin

Item {
    id: root
    anchors.fill: parent

    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    property string notificationMessage

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    KeyboardIndicator.KeyState {
        id: capsLockState
        key: Qt.Key_CapsLock
    }

    BreezeComponents.RejectPasswordAnimation {
        id: rejectPasswordAnimation
        target: mainStack
    }

    Connections {
        target: greeterEventFilter
        function onKeyPressed(): void {
            Qt.callLater(() => PlasmaLogin.GreeterState.activateWindow(loginScreenRoot.Window.window));
        }
        function onEscapeKeyPressed(): void {
            PlasmaLogin.GreeterState.timeoutWindow(loginScreenRoot.Window.window);
            PlasmaLogin.GreeterState.clearPasswords();
        }
    }

    // ── Background ──
    // The greeter window is transparent (set in main.cpp). PLM's wallpaper
    // plugin (configured in System Settings → Login Screen → Wallpaper)
    // renders behind it and is blurred via BlurScreenBridge when the UI is
    // visible. We only add a Win11-style dark dimming overlay on top.
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: loginScreenRoot.uiVisible ? 0.45 : 0.0
        z: -1

        Behavior on opacity {
            NumberAnimation {
                duration: Kirigami.Units.veryLongDuration * 2
                easing.type: Easing.InOutQuad
            }
        }
    }

    MouseArea {
        id: loginScreenRoot
        anchors.fill: parent
        hoverEnabled: true

        property bool uiVisible: PlasmaLogin.GreeterState.activeWindow === Window.window
        cursorShape: uiVisible ? Qt.ArrowCursor : Qt.BlankCursor

        onPressed: PlasmaLogin.GreeterState.activateWindow(Window.window);
        onPositionChanged: PlasmaLogin.GreeterState.activateWindow(Window.window);

        // ── Clock (Top-Center, Windows 11 style) ──
        Column {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: parent.height * 0.15
            spacing: Kirigami.Units.smallSpacing / 2
            opacity: loginScreenRoot.uiVisible ? 0 : 1

            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.veryLongDuration * 2
                    easing.type: Easing.InOutQuad
                }
            }

            Text {
                id: timeText
                text: Qt.formatTime(new Date(), "HH:mm")
                font.family: "Segoe UI"
                font.weight: Font.DemiBold
                font.pixelSize: 96
                color: "#FFFFFF"
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                id: dateText
                text: Qt.formatDate(new Date(), "dddd, MMMM d")
                font.family: "Segoe UI"
                font.pixelSize: 24
                color: "#E0E0E0"
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // ── Main login stack ──
        StackView {
            id: mainStack
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            // This pushes the entire block up by 15% of the screen height.
            anchors.verticalCenterOffset: -parent.height * 0.15
            width: Math.min(parent.width * 0.9, 480)
            height: Math.min(parent.height * 0.8, 600)
            focus: true
            hoverEnabled: true

            opacity: loginScreenRoot.uiVisible ? 1 : 0
            Behavior on opacity { OpacityAnimator { duration: Kirigami.Units.longDuration } }

            Connections {
                target: PlasmaLogin.GreeterState
                function onLoginStateChanged() {
                    switch (PlasmaLogin.GreeterState.loginState) {
                        case PlasmaLogin.GreeterState.LoginState.UserList:
                            if (mainStack.depth !== 2) return;
                            mainStack.pop();
                            return;
                        case PlasmaLogin.GreeterState.LoginState.UserPrompt:
                            if (mainStack.depth !== 1) return;
                            mainStack.push(userPromptComponent);
                            return;
                    }
                }
            }

            initialItem: Login {
                id: userListComponent
                userListModel: PlasmaLogin.UserModel
                loginScreenUiVisible: loginScreenRoot.uiVisible

                // MUST BE TRUE so avatar data loads and sync works
                showUserList: true

                userListCurrentIndex: {
                    let preselectedUserIndex = PlasmaLogin.UserModel.indexOfData(PlasmaLogin.Settings.preselectedUser, PlasmaLogin.UserModel.NameRole);
                    let lastLoggedInUserIndex = PlasmaLogin.UserModel.indexOfData(PlasmaLogin.StateConfig.lastLoggedInUser, PlasmaLogin.UserModel.NameRole);
                    if (preselectedUserIndex != -1) return preselectedUserIndex;
                    if (lastLoggedInUserIndex != -1) return lastLoggedInUserIndex;
                    return 0;
                }

                customErrorMessage: {
                    const parts = [];
                    if (capsLockState.locked) parts.push(i18nd("plasma_login", "Caps Lock is on"));
                    if (root.notificationMessage) parts.push(root.notificationMessage);
                    return parts.join(" \u2022 ");
                }

                onLoginRequest: (username, password) => root.handleLoginRequest(username, password, sessionButton.currentSessionType, sessionButton.currentSessionFileName)
            }

            readonly property real zoomFactor: 1.5
            popEnter: Transition {
                ScaleAnimator { from: mainStack.zoomFactor; to: 1; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
                OpacityAnimator { from: 0; to: 1; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
            }
            popExit: Transition {
                ScaleAnimator { from: 1; to: 1 / mainStack.zoomFactor; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
                OpacityAnimator { from: 1; to: 0; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
            }
            pushEnter: Transition {
                ScaleAnimator { from: 1 / mainStack.zoomFactor; to: 1; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
                OpacityAnimator { from: 0; to: 1; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
            }
            pushExit: Transition {
                ScaleAnimator { from: 1; to: mainStack.zoomFactor; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
                OpacityAnimator { from: 1; to: 0; duration: Kirigami.Units.veryLongDuration; easing.type: Easing.OutCubic }
            }
        }

        Component {
            id: userPromptComponent
            Login {
                showUsernamePrompt: true
                loginScreenUiVisible: loginScreenRoot.uiVisible
                fontSize: Kirigami.Theme.defaultFont.pointSize + 2

                customErrorMessage: {
                    const parts = [];
                    if (capsLockState.locked) parts.push(i18nd("plasma_login", "Caps Lock is on"));
                    if (root.notificationMessage) parts.push(root.notificationMessage);
                    return parts.join(" \u2022 ");
                }

                userListModel: ListModel {
                    ListElement { realName: ""; icon: "" }
                    Component.onCompleted: {
                        setProperty(0, "realName", i18nd("plasma_login", "Type in Username and Password"));
                        setProperty(0, "icon", Qt.resolvedUrl("faces/.face.icon").toString());
                    }
                }

                onLoginRequest: (username, password) => root.handleLoginRequest(username, password, sessionButton.currentSessionType, sessionButton.currentSessionFileName)
            }
        }

        // ── Bottom-left user switcher (Windows 10 style) ──
        ListView {
            id: userListSwitcher
            anchors {
                left: parent.left
                bottom: footer.top
                leftMargin: Kirigami.Units.largeSpacing * 2
                bottomMargin: Kirigami.Units.largeSpacing
            }
            width: 240
            height: contentHeight
            model: PlasmaLogin.UserModel
            clip: true

            visible: count > 1 && loginScreenRoot.uiVisible && PlasmaLogin.GreeterState.loginState !== PlasmaLogin.GreeterState.LoginState.UserPrompt

            delegate: Item {
                width: userListSwitcher.width
                height: 32
                opacity: ListView.isCurrentItem ? 1.0 : 0.7

                Row {
                    anchors.fill: parent
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        width: 32; height: 32
                        radius: 16
                        color: "#33FFFFFF"
                        visible: model.icon !== ""

                        Image {
                            anchors.fill: parent
                            source: model.icon || ""
                            fillMode: Image.PreserveAspectCrop
                            clip: true
                        }
                    }
                    Text {
                        text: model.realName || model.name
                        font.family: "Segoe UI"
                        font.pixelSize: 20
                        font.weight: Font.Light
                        color: "#FFFFFF"
                        verticalAlignment: Text.AlignVCenter
                        height: 32
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        userListSwitcher.currentIndex = index
                        PlasmaLogin.GreeterState.userListIndex = index
                    }
                }
            }

            Connections {
                target: PlasmaLogin.GreeterState
                function onUserListIndexChanged() {
                    if (userListSwitcher.currentIndex !== PlasmaLogin.GreeterState.userListIndex) {
                        userListSwitcher.currentIndex = PlasmaLogin.GreeterState.userListIndex;
                    }
                }
            }
        }

        // ── Footer (Keyboard, Session, Network, Battery, Power) ──
        RowLayout {
            id: footer
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing
            opacity: loginScreenRoot.uiVisible ? 1 : 0

            Behavior on opacity { OpacityAnimator { duration: Kirigami.Units.longDuration } }

            KeyboardButton { id: keyboardButton }

            SessionButton {
                id: sessionButton
                onSessionChanged: userListComponent.mainPasswordBox.forceActiveFocus();
                Layout.fillHeight: true
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents.ToolButton {
                icon.name: "network-wireless"
                icon.color: "#FFFFFF"
                display: AbstractButton.IconOnly
                flat: true
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
            }

            PlasmaComponents.ToolButton {
                icon.name: "preferences-desktop-accessibility"
                icon.color: "#FFFFFF"
                display: AbstractButton.IconOnly
                flat: true
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
            }

            BreezeComponents.Battery {}

            // Raw Menu Component to bypass forced white styling
            Menu {
                id: powerMenu
                x: parent.width - width
                y: -implicitHeight
                width: 150

                background: Rectangle {
                    color: "#2C2C2C"
                    border.color: "#3F3F3F"
                    border.width: 1
                }

                delegate: MenuItem {
                    id: menuItem
                    width: parent.width
                    height: 36

                    contentItem: Row {
                        spacing: Kirigami.Units.smallSpacing
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12

                        Kirigami.Icon {
                            source: menuItem.icon.name
                            width: 16; height: 16
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: menuItem.text
                            color: "#FFFFFF"
                            font.family: "Segoe UI"
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    background: Rectangle {
                        color: menuItem.highlighted ? "#33FFFFFF" : "transparent"
                    }
                }

                MenuItem {
                    text: i18nd("plasma_login", "Sleep")
                    icon.name: "system-suspend"
                    onTriggered: PlasmaLogin.SessionManagement.suspend()
                    visible: PlasmaLogin.SessionManagement.canSuspend
                }
                MenuItem {
                    text: i18nd("plasma_login", "Shut Down")
                    icon.name: "system-shutdown"
                    onTriggered: PlasmaLogin.SessionManagement.requestShutdown(PlasmaLogin.SessionManagement.ConfirmationMode.Skip)
                    visible: PlasmaLogin.SessionManagement.canShutdown
                }
                MenuItem {
                    text: i18nd("plasma_login", "Restart")
                    icon.name: "system-reboot"
                    onTriggered: PlasmaLogin.SessionManagement.requestReboot(PlasmaLogin.SessionManagement.ConfirmationMode.Skip)
                    visible: PlasmaLogin.SessionManagement.canReboot
                }
            }

            PlasmaComponents.ToolButton {
                icon.name: "system-shutdown"
                icon.color: "#FFFFFF"
                display: AbstractButton.IconOnly
                flat: true
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
                onClicked: powerMenu.open()
            }
        }
    }

    function handleLoginRequest(username, password, sessionType, sessionFileName) {
        root.notificationMessage = "";
        PlasmaLogin.GreeterState.handleLoginRequest(username, password, sessionType, sessionFileName);
    }

    Connections {
        target: PlasmaLogin.Authenticator

        function onLoginFailed() {
            notificationMessage = i18nd("plasma_login", "Login Failed");
            footer.enabled = true;
            mainStack.enabled = true;
            rejectPasswordAnimation.start();
        }

        function onLoginSucceeded() {
            mainStack.opacity = 0;
            footer.opacity = 0;
        }
    }

    onNotificationMessageChanged: {
        if (notificationMessage) {
            notificationResetTimer.start();
        }
    }

    Timer {
        id: notificationResetTimer
        interval: 3000
        onTriggered: notificationMessage = ""
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            var d = new Date();
            timeText.text = Qt.formatTime(d, "HH:mm");
            dateText.text = Qt.formatDate(d, "dddd, MMMM d");
        }
    }
}
