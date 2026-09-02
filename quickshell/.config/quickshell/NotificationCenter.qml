import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorWindow
    required property var palette
    required property var tokens
    required property var notificationServer
    property bool open: false
    readonly property int notificationCount:
        notificationServer.trackedNotifications.values.length

    signal dismissed
    signal notificationActivated(var notification)
    signal notificationDismissed(var notification)
    signal clearRequested

    visible: open
    grabFocus: true
    implicitWidth: Math.min(400, anchorWindow.width - tokens.spaceXl)
    implicitHeight: Math.min(480, anchorWindow.screen.height
        - anchorWindow.height - tokens.spaceXl)
    color: "transparent"

    anchor.window: anchorWindow
    anchor.rect.x: Math.round(anchorWindow.width / 2 - width / 2)
    anchor.rect.y: anchorWindow.height + tokens.popupMargin

    onVisibleChanged: {
        if (!visible && open)
            dismissed();
    }

    Rectangle {
        anchors.fill: parent
        focus: true
        radius: root.tokens.radiusLg
        color: root.palette.bg2
        border.color: root.palette.bg3
        border.width: 1

        Keys.onEscapePressed: root.dismissed()

        Text {
            id: title
            anchors {
                top: parent.top
                left: parent.left
                topMargin: root.tokens.spaceLg
                leftMargin: root.tokens.spaceLg
            }
            text: "Notifications"
            color: root.palette.fg
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textLg
            font.bold: true
        }

        Rectangle {
            anchors {
                right: parent.right
                verticalCenter: title.verticalCenter
                rightMargin: root.tokens.spaceMd
            }
            visible: root.notificationCount > 0
            width: clearLabel.implicitWidth + root.tokens.spaceLg
            height: root.tokens.controlHeight
            radius: root.tokens.radiusSm
            color: clearMouse.containsMouse ? root.palette.bg_red : "transparent"

            Text {
                id: clearLabel
                anchors.centerIn: parent
                text: "Clear all"
                color: root.palette.red
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textSm
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearRequested()
            }
        }

        Rectangle {
            id: separator
            anchors {
                top: title.bottom
                left: parent.left
                right: parent.right
                topMargin: root.tokens.spaceMd
                leftMargin: root.tokens.spaceMd
                rightMargin: root.tokens.spaceMd
            }
            height: 1
            color: root.palette.bg3
        }

        Text {
            anchors.centerIn: parent
            visible: root.notificationCount === 0
            text: "󰂜\nYou’re all caught up"
            horizontalAlignment: Text.AlignHCenter
            color: root.palette.grey1
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textMd
            lineHeight: 1.5
        }

        ListView {
            id: notificationList
            anchors {
                top: separator.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: root.tokens.spaceMd
                topMargin: root.tokens.spaceMd
            }
            visible: root.notificationCount > 0
            clip: true
            spacing: root.tokens.spaceSm
            model: root.notificationServer.trackedNotifications

            delegate: NotificationCard {
                required property var modelData
                width: notificationList.width
                notification: modelData
                palette: root.palette
                tokens: root.tokens
                onActivated: root.notificationActivated(modelData)
                onDismissed: root.notificationDismissed(modelData)
            }
        }
    }
}
