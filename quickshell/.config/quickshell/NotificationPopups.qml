import QtQuick
import Quickshell

PanelWindow {
    id: root

    required property var palette
    required property var tokens
    required property var targetScreen
    property var notifications: []

    signal notificationActivated(var notification)
    signal notificationDismissed(var notification)
    signal popupExpired(var notification)

    visible: notifications.length > 0 && targetScreen !== null
    screen: targetScreen
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    implicitWidth: Math.min(400, targetScreen ? targetScreen.width - tokens.spaceXl : 400)
    implicitHeight: popupColumn.implicitHeight
    color: "transparent"

    anchors {
        top: true
        right: true
    }

    margins {
        top: tokens.barHeight + tokens.popupMargin
        right: tokens.spaceXs
    }

    Column {
        id: popupColumn
        width: parent.width
        spacing: root.tokens.spaceSm

        Repeater {
            model: root.notifications

            NotificationCard {
                id: popupCard
                required property var modelData
                width: popupColumn.width
                notification: modelData
                palette: root.palette
                tokens: root.tokens
                popupMode: true
                onActivated: root.notificationActivated(modelData)
                onDismissed: root.notificationDismissed(modelData)

                Timer {
                    interval: popupCard.notification.expireTimeout > 0
                        ? Math.max(1000, popupCard.notification.expireTimeout) : 5000
                    running: true
                    onTriggered: root.popupExpired(popupCard.notification)
                }

                Connections {
                    target: popupCard.notification
                    function onClosed() {
                        root.popupExpired(popupCard.notification);
                    }
                }
            }
        }
    }
}
