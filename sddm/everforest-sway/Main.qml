import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import SddmComponents 2.0 as SDDM

Rectangle {
    id: root

    width: 1920
    height: 1080
    color: "#232a2e"

    readonly property color bgDim: "#232a2e"
    readonly property color bg0: "#2d353b"
    readonly property color bg1: "#343f44"
    readonly property color bg3: "#475258"
    readonly property color bg5: "#56635f"
    readonly property color foreground: "#d3c6aa"
    readonly property color muted: "#9da9a0"
    readonly property color green: "#a7c080"
    readonly property color red: "#e67e80"
    readonly property color yellow: "#dbbc7f"

    property bool authenticating: false
    property int sessionIndex: sessionBox.currentIndex

    function submitLogin() {
        if (authenticating || usernameField.text.length === 0)
            return

        authenticating = true
        statusMessage.color = muted
        statusMessage.text = qsTr("Signing in…")
        sddm.login(usernameField.text, passwordField.text, sessionIndex)
    }

    SDDM.TextConstants {
        id: textConstants
    }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            statusMessage.color = root.green
            statusMessage.text = textConstants.loginSucceeded
        }

        function onLoginFailed() {
            authenticating = false
            passwordField.text = ""
            statusMessage.color = root.red
            statusMessage.text = textConstants.loginFailed
            passwordField.forceActiveFocus()
        }

        function onInformationMessage(message) {
            statusMessage.color = root.yellow
            statusMessage.text = message
        }
    }

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl(config.background)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#59000000"
    }

    Item {
        anchors.fill: parent
        visible: primaryScreen

        Column {
            id: loginArea

            width: Math.min(420, parent.width - 48)
            spacing: 22
            anchors.centerIn: parent

            Column {
                width: parent.width
                spacing: 2

                Text {
                    id: clockText

                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.foreground
                    font.family: "Noto Sans"
                    font.pixelSize: 64
                    font.weight: Font.DemiBold
                    text: Qt.formatTime(new Date(), "HH:mm")

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: {
                            clockText.text = Qt.formatTime(new Date(), "HH:mm")
                            dateText.text = Qt.formatDate(new Date(), "dddd, d MMMM")
                        }
                    }
                }

                Text {
                    id: dateText

                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.muted
                    font.family: "Noto Sans"
                    font.pixelSize: 17
                    text: Qt.formatDate(new Date(), "dddd, d MMMM")
                }
            }

            Rectangle {
                width: parent.width
                height: formColumn.implicitHeight + 64
                radius: 18
                color: "#f0343f44"
                border.width: 1
                border.color: "#8ca7c080"

                Column {
                    id: formColumn

                    anchors.centerIn: parent
                    width: parent.width - 64
                    spacing: 14

                    Column {
                        width: parent.width
                        spacing: 3

                        Text {
                            color: root.foreground
                            font.family: "Noto Sans"
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            text: qsTr("Welcome back")
                        }

                        Text {
                            color: root.muted
                            font.family: "Noto Sans"
                            font.pixelSize: 13
                            text: sddm.hostName
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            color: root.muted
                            font.family: "Noto Sans"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            text: textConstants.userName
                        }

                        Controls.TextField {
                            id: usernameField

                            width: parent.width
                            height: 44
                            enabled: !root.authenticating
                            color: root.foreground
                            selectionColor: root.bg5
                            selectedTextColor: root.foreground
                            placeholderText: textConstants.userName
                            placeholderTextColor: root.muted
                            font.family: "Noto Sans"
                            font.pixelSize: 14
                            text: userModel.lastUser
                            leftPadding: 14
                            rightPadding: 14

                            background: Rectangle {
                                radius: 10
                                color: "#e6232a2e"
                                border.width: 1
                                border.color: usernameField.activeFocus ? root.green : root.bg5
                            }

                            Keys.onReturnPressed: root.submitLogin()
                            Keys.onEnterPressed: root.submitLogin()
                            KeyNavigation.tab: passwordField
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            color: root.muted
                            font.family: "Noto Sans"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            text: textConstants.password
                        }

                        Controls.TextField {
                            id: passwordField

                            width: parent.width
                            height: 44
                            enabled: !root.authenticating
                            color: root.foreground
                            selectionColor: root.bg5
                            selectedTextColor: root.foreground
                            placeholderText: textConstants.password
                            placeholderTextColor: root.muted
                            font.family: "Noto Sans"
                            font.pixelSize: 14
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            leftPadding: 14
                            rightPadding: 14

                            background: Rectangle {
                                radius: 10
                                color: "#e6232a2e"
                                border.width: 1
                                border.color: passwordField.activeFocus ? root.green : root.bg5
                            }

                            Keys.onReturnPressed: root.submitLogin()
                            Keys.onEnterPressed: root.submitLogin()
                            KeyNavigation.backtab: usernameField
                            KeyNavigation.tab: sessionBox
                        }
                    }

                    Controls.ComboBox {
                        id: sessionBox

                        width: parent.width
                        height: 42
                        enabled: !root.authenticating
                        model: sessionModel
                        textRole: "name"
                        currentIndex: sessionModel.lastIndex
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        leftPadding: 14
                        rightPadding: 32

                        contentItem: Text {
                            leftPadding: 0
                            rightPadding: 0
                            color: root.foreground
                            font: sessionBox.font
                            text: sessionBox.displayText
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            radius: 10
                            color: "#e6232a2e"
                            border.width: 1
                            border.color: sessionBox.activeFocus ? root.green : root.bg5
                        }

                        KeyNavigation.backtab: passwordField
                        KeyNavigation.tab: loginButton
                    }

                    Text {
                        id: statusMessage

                        width: parent.width
                        height: 18
                        color: root.muted
                        font.family: "Noto Sans"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        text: root.authenticating ? qsTr("Signing in…") : ""
                    }

                    Controls.Button {
                        id: loginButton

                        width: parent.width
                        height: 44
                        enabled: !root.authenticating && usernameField.text.length > 0
                        text: root.authenticating ? qsTr("Signing in…") : textConstants.login

                        contentItem: Text {
                            color: root.bgDim
                            font.family: "Noto Sans"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: loginButton.text
                        }

                        background: Rectangle {
                            radius: 10
                            color: loginButton.enabled
                                ? (loginButton.down ? "#83c092" : root.green)
                                : root.bg5
                        }

                        onClicked: root.submitLogin()
                        KeyNavigation.backtab: sessionBox
                    }
                }
            }
        }

        Row {
            spacing: 10
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 24

            Controls.Button {
                id: rebootButton

                text: qsTr("Restart")
                flat: true
                onClicked: sddm.reboot()

                contentItem: Text {
                    color: rebootButton.hovered ? root.foreground : root.muted
                    font.family: "Noto Sans"
                    font.pixelSize: 13
                    text: rebootButton.text
                }
            }

            Controls.Button {
                id: powerButton

                text: qsTr("Shut down")
                flat: true
                onClicked: sddm.powerOff()

                contentItem: Text {
                    color: powerButton.hovered ? root.red : root.muted
                    font.family: "Noto Sans"
                    font.pixelSize: 13
                    text: powerButton.text
                }
            }
        }
    }

    Component.onCompleted: {
        if (usernameField.text.length === 0)
            usernameField.forceActiveFocus()
        else
            passwordField.forceActiveFocus()
    }
}
