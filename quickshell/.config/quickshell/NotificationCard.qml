import QtQuick
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property var notification
    required property var palette
    required property var tokens
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

    function isAbrtNotification() {
        const appName = String(notification.appName || "").toLowerCase();
        const desktopEntry = String(notification.desktopEntry || "").toLowerCase();
        return appName.includes("abrt")
            || appName.includes("problem reporting")
            || desktopEntry.includes("org.freedesktop.problems")
            || desktopEntry.includes("gnomeabrt");
    }

    function desktopEntryName() {
        const desktopEntry = plainText(notification.desktopEntry)
            .replace(/\.desktop$/i, "");
        if (desktopEntry === "")
            return "";
        if (isAbrtNotification())
            return "ABRT Problem Reporting";

        const parts = desktopEntry.split(".");
        const name = parts[parts.length - 1].replace(/[-_]+/g, " ");
        return name.charAt(0).toUpperCase() + name.slice(1);
    }

    function sourceName() {
        const appName = plainText(notification.appName);
        const desktopEntry = desktopEntryName();
        if (desktopEntry !== ""
                && (appName === ""
                    || appName.toLowerCase() === "notification"
                    || isAbrtNotification()))
            return desktopEntry;
        return appName || desktopEntry || "Notification";
    }

    implicitWidth: 356
    implicitHeight: notificationText.implicitHeight + 24
    radius: tokens.radiusMd
    color: cardMouse.containsMouse ? palette.bg2 : palette.bg0
    border.color: notification.urgency === NotificationUrgency.Critical
        ? palette.red : palette.bg3
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
            ? root.palette.red : root.palette.green
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

        Row {
            width: parent.width
            spacing: root.tokens.spaceSm

            Text {
                width: parent.width - (criticalBadge.visible
                    ? criticalBadge.width + parent.spacing : 0)
                anchors.verticalCenter: parent.verticalCenter
                text: root.sourceName()
                color: root.palette.green
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textXs
                elide: Text.ElideRight
            }

            Rectangle {
                id: criticalBadge
                visible: root.notification.urgency === NotificationUrgency.Critical
                width: criticalLabel.implicitWidth + 10
                height: criticalLabel.implicitHeight + 4
                radius: root.tokens.radiusSm
                color: root.palette.bg_red

                Text {
                    id: criticalLabel
                    anchors.centerIn: parent
                    text: "CRITICAL"
                    color: root.palette.red
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textXs
                    font.bold: true
                }
            }
        }

        Text {
            width: parent.width
            text: root.plainText(root.notification.summary || "Notification")
            color: root.palette.fg
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textMd
            font.bold: true
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.plainText(root.notification.body)
            color: root.palette.grey2
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textSm
            wrapMode: Text.Wrap
            maximumLineCount: root.popupMode ? 3 : 4
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: root.isAbrtNotification()
            text: "Open Problem Reporting to see the executable, crash reason, and backtrace."
            color: root.palette.yellow
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textXs
            wrapMode: Text.Wrap
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
        color: closeMouse.containsMouse ? root.palette.red : root.palette.grey1
        font.family: root.tokens.uiFont
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
