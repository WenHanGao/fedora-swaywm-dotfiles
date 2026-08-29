import QtQuick
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property var notification
    property bool popupMode: false

    signal activated
    signal dismissed

    function plainText(value) {
        return String(value || "")
            .replace(/<[^>]*>/g, "")
            .replace(/&amp;/g, "&")
            .replace(/&lt;/g, "<")
            .replace(/&gt;/g, ">");
    }

    implicitWidth: 356
    implicitHeight: notificationText.implicitHeight + 24
    radius: 8
    color: cardMouse.containsMouse ? "#3d484d" : "#2d353b"
    border.color: notification.urgency === NotificationUrgency.Critical
        ? "#e67e80" : "#475258"
    border.width: 1

    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            margins: 1
        }
        width: 3
        radius: 2
        color: root.notification.urgency === NotificationUrgency.Critical
            ? "#e67e80" : "#a7c080"
    }

    Column {
        id: notificationText
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 12
            leftMargin: 16
            rightMargin: 38
        }
        spacing: 4

        Text {
            width: parent.width
            text: root.plainText(root.notification.appName || "Notification")
            color: "#a7c080"
            font.family: "Cascadia Mono NF"
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.plainText(root.notification.summary || "Notification")
            color: "#d3c6aa"
            font.family: "Cascadia Mono NF"
            font.pixelSize: 14
            font.bold: true
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.plainText(root.notification.body)
            color: "#9da9a0"
            font.family: "Cascadia Mono NF"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            maximumLineCount: root.popupMode ? 3 : 4
            elide: Text.ElideRight
        }
    }

    Text {
        id: closeLabel
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 8
            rightMargin: 10
        }
        z: 2
        text: "×"
        color: closeMouse.containsMouse ? "#e67e80" : "#859289"
        font.family: "Cascadia Mono NF"
        font.pixelSize: 18

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.dismissed()
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
