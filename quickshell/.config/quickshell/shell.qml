import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    property int volume: 0
    property bool volumeMuted: false
    property int brightness: 0
    property string network: "Disconnected"
    property string inputLanguage: "--"
    property bool doNotDisturb: false
    property int scratchpadCount: 0
    property var popupNotifications: []
    readonly property int notificationCount: notificationServer.trackedNotifications.values.length

    function runAction(process, command) {
        if (!process.running) {
            process.command = command;
            process.running = true;
        }
    }

    function refreshFast() {
        volumeQuery.running = true;
        inputQuery.running = true;
        scratchpadQuery.running = true;
    }

    function refreshSlow() {
        brightnessQuery.running = true;
        networkQuery.running = true;
    }

    function countScratchpad(node) {
        if (node.name === "__i3_scratch")
            return (node.nodes || []).length + (node.floating_nodes || []).length;

        const children = (node.nodes || []).concat(node.floating_nodes || []);
        for (let i = 0; i < children.length; ++i) {
            const count = countScratchpad(children[i]);
            if (count >= 0)
                return count;
        }

        return -1;
    }

    function shortLanguage(name) {
        if (!name)
            return "--";

        const language = name.split(/[ (]/)[0];
        return language.slice(0, 2).toUpperCase();
    }

    function showNotificationPopup(notification) {
        const updated = popupNotifications.filter(item => item.id !== notification.id);
        updated.unshift(notification);
        popupNotifications = updated.slice(0, 3);
    }

    function hideNotificationPopup(notification) {
        popupNotifications = popupNotifications.filter(item => item !== notification);
    }

    function activateNotification(notification) {
        hideNotificationPopup(notification);

        for (let index = 0; index < notification.actions.length; ++index) {
            if (notification.actions[index].identifier === "default") {
                notification.actions[index].invoke();
                return;
            }
        }

        notification.dismiss();
    }

    function clearNotificationHistory() {
        const notifications = notificationServer.trackedNotifications.values.slice();
        popupNotifications = [];
        for (let index = 0; index < notifications.length; ++index)
            notifications[index].dismiss();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    NotificationServer {
        id: notificationServer
        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        bodyMarkupSupported: false

        onNotification: notification => {
            notification.tracked = true;
            if (!root.doNotDisturb && !notification.lastGeneration)
                root.showNotificationPopup(notification);
        }
    }

    Process {
        id: volumeQuery
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Volume:\s+([0-9.]+)/);
                if (match)
                    root.volume = Math.round(Number(match[1]) * 100);
                root.volumeMuted = text.includes("[MUTED]");
            }
        }
    }

    Process {
        id: brightnessQuery
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                if (fields.length >= 4)
                    root.brightness = Number(fields[3].replace("%", ""));
            }
        }
    }

    Process {
        id: networkQuery
        command: ["nmcli", "--terse", "--escape", "no", "--fields", "TYPE,STATE,CONNECTION", "device", "status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n");
                root.network = "Disconnected";
                for (let i = 0; i < lines.length; ++i) {
                    const fields = lines[i].split(":");
                    if (fields[0] === "wifi" && fields[1] === "connected") {
                        root.network = fields.slice(2).join(":");
                        break;
                    }
                }
            }
        }
    }

    Process {
        id: inputQuery
        command: ["swaymsg", "-r", "-t", "get_inputs"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const inputs = JSON.parse(text);
                    const keyboard = inputs.find(input => input.type === "keyboard"
                        && input.xkb_active_layout_name);
                    root.inputLanguage = root.shortLanguage(keyboard?.xkb_active_layout_name);
                } catch (error) {
                    root.inputLanguage = "--";
                }
            }
        }
    }

    Process {
        id: scratchpadQuery
        command: ["swaymsg", "-r", "-t", "get_tree"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.scratchpadCount = Math.max(0, root.countScratchpad(JSON.parse(text)));
                } catch (error) {
                    root.scratchpadCount = 0;
                }
            }
        }
    }

    Process {
        id: volumeAction
        onExited: volumeQuery.running = true
    }

    Process {
        id: brightnessAction
        onExited: brightnessQuery.running = true
    }

    Process {
        id: inputAction
        onExited: inputQuery.running = true
    }

    Process {
        id: powerAction
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.refreshFast()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: root.refreshSlow()
    }

    PanelWindow {
        id: notificationPopups
        visible: root.popupNotifications.length > 0
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        implicitWidth: 380
        implicitHeight: popupColumn.implicitHeight
        color: "transparent"

        anchors {
            top: true
            right: true
        }

        margins {
            top: 40
            right: 8
        }

        Column {
            id: popupColumn
            width: parent.width
            spacing: 8

            Repeater {
                model: root.popupNotifications

                NotificationCard {
                    required property var modelData
                    width: popupColumn.width
                    notification: modelData
                    popupMode: true
                    onActivated: root.activateNotification(modelData)
                    onDismissed: {
                        root.hideNotificationPopup(modelData);
                        modelData.dismiss();
                    }

                    Timer {
                        interval: modelData.expireTimeout > 0
                            ? Math.max(1000, modelData.expireTimeout * 1000) : 5000
                        running: true
                        onTriggered: {
                            root.hideNotificationPopup(modelData);
                            if (modelData.transient)
                                modelData.expire();
                        }
                    }

                    Connections {
                        target: modelData
                        function onClosed() {
                            root.hideNotificationPopup(modelData);
                        }
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            property bool powerMenuOpen: false
            property bool notificationCenterOpen: false
            property string pendingPowerAction: ""
            screen: modelData

            function choosePowerAction(action, command) {
                if (action === "lock") {
                    root.runAction(powerAction, command);
                    powerMenuOpen = false;
                    return;
                }

                if (pendingPowerAction === action) {
                    pendingPowerAction = "";
                    powerMenuOpen = false;
                    root.runAction(powerAction, command);
                } else {
                    pendingPowerAction = action;
                    confirmationTimer.restart();
                }
            }

            Timer {
                id: confirmationTimer
                interval: 3000
                onTriggered: bar.pendingPowerAction = ""
            }

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 32
            color: "#2d353b"

            RowLayout {
                anchors {
                    left: parent.left
                    leftMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 6

                Repeater {
                    model: I3.workspaces

                    Rectangle {
                        required property var modelData
                        readonly property bool onThisOutput: modelData.monitor !== null
                            && modelData.monitor.name === bar.screen.name

                        visible: onThisOutput
                        Layout.preferredWidth: visible ? 28 : 0
                        Layout.preferredHeight: 24
                        radius: 4
                        color: modelData.active ? "#a7c080" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.number > 0 ? modelData.number : modelData.name
                            color: modelData.active ? "#2d353b"
                                : modelData.urgent ? "#e67e80" : "#d3c6aa"
                            font.pixelSize: 13
                            font.family: "Cascadia Mono NF"
                            font.bold: modelData.active
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.activate()
                        }
                    }
                }

                StatusPill {
                    icon: "󰆍"
                    text: root.scratchpadCount > 0 ? root.scratchpadCount.toString() : ""
                    active: root.scratchpadCount > 0
                    onClicked: I3.dispatch("scratchpad show")
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                StatusPill {
                    icon: root.doNotDisturb ? "󰂛" : "󰂚"
                    active: root.doNotDisturb
                    onClicked: root.doNotDisturb = !root.doNotDisturb
                }

                StatusPill {
                    text: Qt.formatDateTime(clock.date, "ddd, MMM d  HH:mm")
                    interactive: false
                }

                StatusPill {
                    id: notificationButton
                    icon: root.notificationCount > 0 ? "󰂞" : "󰂜"
                    text: root.notificationCount > 0 ? root.notificationCount.toString() : ""
                    active: bar.notificationCenterOpen
                    onClicked: bar.notificationCenterOpen = !bar.notificationCenterOpen
                }
            }

            PopupWindow {
                id: notificationCenter
                visible: bar.notificationCenterOpen
                grabFocus: true
                implicitWidth: 380
                implicitHeight: 440
                color: "transparent"

                anchor.window: bar
                anchor.rect.x: Math.round(bar.width / 2 - width / 2)
                anchor.rect.y: bar.height + 8

                onVisibleChanged: {
                    if (!visible)
                        bar.notificationCenterOpen = false;
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "#343f44"
                    border.color: "#475258"
                    border.width: 1

                    Text {
                        id: notificationTitle
                        anchors {
                            top: parent.top
                            left: parent.left
                            margins: 16
                        }
                        text: "Notifications"
                        color: "#d3c6aa"
                        font.family: "Cascadia Mono NF"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Rectangle {
                        id: clearNotificationsButton
                        anchors {
                            right: parent.right
                            verticalCenter: notificationTitle.verticalCenter
                            rightMargin: 12
                        }
                        visible: root.notificationCount > 0
                        implicitWidth: clearNotificationsLabel.implicitWidth + 16
                        implicitHeight: 26
                        radius: 5
                        color: clearNotificationsMouse.containsMouse ? "#475258" : "transparent"

                        Text {
                            id: clearNotificationsLabel
                            anchors.centerIn: parent
                            text: "Clear"
                            color: "#e67e80"
                            font.family: "Cascadia Mono NF"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: clearNotificationsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearNotificationHistory()
                        }
                    }

                    Rectangle {
                        anchors {
                            top: notificationTitle.bottom
                            left: parent.left
                            right: parent.right
                            topMargin: 12
                            leftMargin: 12
                            rightMargin: 12
                        }
                        height: 1
                        color: "#475258"
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.notificationCount === 0
                        text: "󰂜\nNo notifications"
                        horizontalAlignment: Text.AlignHCenter
                        color: "#859289"
                        font.family: "Cascadia Mono NF"
                        font.pixelSize: 14
                        lineHeight: 1.5
                    }

                    ListView {
                        id: notificationList
                        anchors {
                            top: notificationTitle.bottom
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            margins: 12
                            topMargin: 24
                        }
                        visible: root.notificationCount > 0
                        clip: true
                        spacing: 8
                        model: notificationServer.trackedNotifications

                        delegate: NotificationCard {
                            required property var modelData
                            width: notificationList.width
                            notification: modelData
                            onActivated: root.activateNotification(modelData)
                            onDismissed: {
                                root.hideNotificationPopup(modelData);
                                modelData.dismiss();
                            }
                        }
                    }
                }
            }

            RowLayout {
                anchors {
                    right: parent.right
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                spacing: 6

                StatusPill {
                    icon: root.volumeMuted || root.volume === 0 ? "󰖁"
                        : root.volume < 50 ? "󰕿" : "󰕾"
                    text: root.volume + "%"
                    active: root.volumeMuted
                    onClicked: root.runAction(volumeAction,
                        ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                    onWheelUp: root.runAction(volumeAction,
                        ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", "5%+"])
                    onWheelDown: root.runAction(volumeAction,
                        ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
                }

                StatusPill {
                    icon: "󰃠"
                    text: root.brightness + "%"
                    onWheelUp: root.runAction(brightnessAction, ["brightnessctl", "set", "+5%"])
                    onWheelDown: root.runAction(brightnessAction, ["brightnessctl", "set", "5%-"])
                }

                StatusPill {
                    icon: root.network === "Disconnected" ? "󰤭" : "󰤨"
                    text: root.network === "Disconnected" ? "" : root.network
                    interactive: false
                }

                StatusPill {
                    icon: "󰌌"
                    text: root.inputLanguage
                    onClicked: root.runAction(inputAction,
                        ["swaymsg", "input", "type:keyboard", "xkb_switch_layout", "next"])
                }

                StatusPill {
                    visible: bar.powerMenuOpen
                    icon: "󰌾"
                    onClicked: bar.choosePowerAction("lock", ["swaylock", "-f"])
                }

                StatusPill {
                    visible: bar.powerMenuOpen
                    icon: "󰜉"
                    active: bar.pendingPowerAction === "reboot"
                    highlightColor: "#e67e80"
                    onClicked: bar.choosePowerAction("reboot", ["systemctl", "reboot"])
                }

                StatusPill {
                    visible: bar.powerMenuOpen
                    icon: "󰐥"
                    active: bar.pendingPowerAction === "shutdown"
                    highlightColor: "#e67e80"
                    onClicked: bar.choosePowerAction("shutdown", ["systemctl", "poweroff"])
                }

                StatusPill {
                    icon: "󰐥"
                    active: bar.powerMenuOpen
                    onClicked: {
                        bar.pendingPowerAction = "";
                        bar.powerMenuOpen = !bar.powerMenuOpen;
                    }
                }
            }
        }
    }
}
