import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

import org.kde.plasma.login as PlasmaLogin
import org.kde.breeze.components

SessionManagementScreen {
    id: root
    property Item mainPasswordBox: passwordBox

    property bool showUsernamePrompt: !showUserList
    property bool loginScreenUiVisible: false

    property real fontSize: Kirigami.Theme.defaultFont.pointSize

    signal loginRequest(string username, string password)

    // Silence the built-in action items layout (we provide our own login button)
    actionItems: [ Item { visible: false } ]

    // ── Custom Error Message ──
    property string customErrorMessage: ""
    notificationMessage: "" // Silence the default top-aligned message

    showUserList: true

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    // Visually hide the built-in KDE user list without breaking background logic/sync
    Component.onCompleted: {
        if (root.userList) {
            root.userList.visible = false;
            root.userList.opacity = 0;
            root.userList.height = 0;
        }
    }

    onUserSelected: {
        passwordBox.clear();
        focusFirstVisibleFormControl();
    }

    function focusFirstVisibleFormControl() {
        const nextControl = (userNameInput.visible
            ? userNameInput
            : (passwordBox.visible
                ? passwordBox
                : loginButton));
        nextControl.forceActiveFocus(Qt.TabFocusReason);
    }

    function startLogin() {
        const username = showUsernamePrompt ? userNameInput.text : userList.selectedUser
        const password = passwordBox.text
        loginButton.forceActiveFocus();
        loginRequest(username, password);
    }

    // ── Custom avatar (replaces built-in UserList) ──
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 140
        Layout.preferredHeight: 140
        Layout.bottomMargin: 16

        Image {
            id: avatarImg
            anchors.fill: parent
            source: {
                if (!showUsernamePrompt && userList.currentItem && userList.currentItem.icon) {
                    return userList.currentItem.icon;
                }
                return Qt.resolvedUrl("faces/.face.icon");
            }
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(140, 140)
            asynchronous: true

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: 140; height: 140
                    radius: 70
                }
            }
        }
    }

    // ── Username ──
    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 4
        text: {
            if (showUsernamePrompt) {
                return "User";
            }
            if (userList.currentItem && userList.currentItem.realName) {
                return userList.currentItem.realName;
            }
            return "";
        }
        font.family: "Segoe UI"
        font.pixelSize: 32
        font.weight: Font.Normal
        color: "#FFFFFF"
        horizontalAlignment: Text.AlignHCenter
    }

    // ── Custom Error Message (Windows 10 style) ──
    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: 20
        Layout.bottomMargin: 0

        Text {
            anchors.centerIn: parent
            visible: root.customErrorMessage !== ""
            text: root.customErrorMessage
            font.family: "Segoe UI"
            font.pixelSize: 14
            font.italic: true
            color: "#A0A0A0"
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // ── Username input (when showing username prompt) ──
    TextField {
        id: userNameInput
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.maximumWidth: 380
        Layout.alignment: Qt.AlignHCenter

        text: ""
        visible: showUsernamePrompt
        focus: showUsernamePrompt
        placeholderText: i18nd("plasma_login", "Username")
        placeholderTextColor: "#A0A0A0"
        font.family: "Segoe UI"
        font.pixelSize: 14
        color: "#FFFFFF"

        background: Rectangle {
            color: "transparent"
            border.color: userNameInput.focus ? "#4CC2FF" : "#A0A0A0"
            radius: 0
        }

        onAccepted: {
            if (root.loginScreenUiVisible) {
                passwordBox.forceActiveFocus()
            }
        }
    }

    // ── Password field + submit button (Win11 style) ──
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.maximumWidth: 380
        Layout.alignment: Qt.AlignHCenter
        visible: root.showUsernamePrompt || (userList.currentItem && userList.currentItem.needsPassword)

        Rectangle {
            anchors.fill: parent
            color: "#40000000"
            border.color: passwordBox.focus ? "#4CC2FF" : "#A0A0A0"
            radius: 0
        }

        TextField {
            id: passwordBox
            anchors.left: parent.left
            anchors.right: loginButton.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height

            placeholderText: i18nd("plasma_login", "Password")
            placeholderTextColor: "#A0A0A0"
            font.family: "Segoe UI"
            font.pixelSize: 14
            color: "#FFFFFF"
            focus: !showUsernamePrompt
            echoMode: TextInput.Password
            leftPadding: 10
            verticalAlignment: TextInput.AlignVCenter

            background: Item {}

            onAccepted: {
                if (root.loginScreenUiVisible) {
                    startLogin();
                }
            }

            Keys.onEscapePressed: {
                if (mainStack.currentItem) {
                    mainStack.currentItem.forceActiveFocus();
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left && !text) {
                    userList.decrementCurrentIndex();
                    event.accepted = true
                }
                if (event.key === Qt.Key_Right && !text) {
                    userList.incrementCurrentIndex();
                    event.accepted = true
                }
            }

            Connections {
                target: PlasmaLogin.Authenticator
                function onLoginFailed() {
                    passwordBox.selectAll()
                    passwordBox.forceActiveFocus()
                }
            }
        }

        ToolButton {
            id: loginButton
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32

            icon.name: LayoutMirroring.enabled ? "go-previous" : "go-next"
            visible: passwordBox.text.length > 0 || !root.showUsernamePrompt
            icon.color: hovered ? "#4CC2FF" : "#A0A0A0"

            onClicked: startLogin()
            Keys.onEnterPressed: clicked()
            Keys.onReturnPressed: clicked()

            background: Rectangle {
                color: parent.hovered ? "#33FFFFFF" : "transparent"
            }
        }
    }

    // ── No-password button ──
    PlasmaComponents.Button {
        Layout.alignment: Qt.AlignHCenter
        text: i18nd("plasma_login", "Log In")
        visible: !root.showUsernamePrompt && userList.currentItem && !userList.currentItem.needsPassword
        onClicked: startLogin()
        flat: true
    }

    // ── Synchronize GreeterState ──
    Item {
        id: sync
        readonly property bool isUserList: root.showUserList && !root.showUsernamePrompt

        Component.onCompleted: {
            if (sync.isUserList) {
                root.userList.currentIndex = PlasmaLogin.GreeterState.userListIndex;
                passwordBox.text = PlasmaLogin.GreeterState.userListPassword;
            } else {
                userNameInput.text = PlasmaLogin.GreeterState.userPromptUsername;
                passwordBox.text = PlasmaLogin.GreeterState.userPromptPassword;
            }
            passwordBox.echoMode = PlasmaLogin.GreeterState.showPassword ? TextInput.Normal : TextInput.Password;
        }

        Connections {
            target: root.userList
            function onCurrentIndexChanged() {
                if (!sync.isUserList) return;
                if (PlasmaLogin.GreeterState.userListIndex != root.userList.currentIndex) {
                    PlasmaLogin.GreeterState.userListIndex = root.userList.currentIndex;
                }
            }
        }

        Connections {
            target: userNameInput
            function onTextChanged() {
                if (!sync.isUserList) {
                    if (PlasmaLogin.GreeterState.userPromptUsername != userNameInput.text) {
                        PlasmaLogin.GreeterState.userPromptUsername = userNameInput.text;
                    }
                }
            }
        }

        Connections {
            target: passwordBox
            function onTextChanged() {
                if (sync.isUserList) {
                    if (PlasmaLogin.GreeterState.userListPassword != passwordBox.text) {
                        PlasmaLogin.GreeterState.userListPassword = passwordBox.text;
                    }
                } else {
                    if (PlasmaLogin.GreeterState.userPromptPassword != passwordBox.text) {
                        PlasmaLogin.GreeterState.userPromptPassword = passwordBox.text;
                    }
                }
            }
        }

        Connections {
            target: PlasmaLogin.GreeterState
            function onUserListIndexChanged() {
                if (!sync.isUserList) return;
                if (root.userList.currentIndex != PlasmaLogin.GreeterState.userListIndex) {
                    root.userList.currentIndex = PlasmaLogin.GreeterState.userListIndex;
                }
            }
            function onUserListPasswordChanged() {
                if (!sync.isUserList) return;
                if (passwordBox.text != PlasmaLogin.GreeterState.userListPassword) {
                    passwordBox.text = PlasmaLogin.GreeterState.userListPassword;
                }
            }
            function onUserPromptUsernameChanged() {
                if (sync.isUserList) return;
                if (userNameInput.text != PlasmaLogin.GreeterState.userPromptUsername) {
                    userNameInput.text = PlasmaLogin.GreeterState.userPromptUsername;
                }
            }
            function onUserPromptPasswordChanged() {
                if (sync.isUserList) return;
                if (passwordBox.text != PlasmaLogin.GreeterState.userPromptPassword) {
                    passwordBox.text = PlasmaLogin.GreeterState.userPromptPassword;
                }
            }
        }
    }
}
