import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    Theme {
        id: theme
    }

    property int volume: 0
    property bool volumeMuted: false
    property int inputVolume: 0
    property bool inputVolumeMuted: false
    property var outputDevices: []
    property var inputDevices: []
    property int brightness: 0
    property string network: "Disconnected"
    property string inputLanguage: "--"
    property bool batteryAvailable: false
    property int batteryPercent: 0
    property string batteryStatus: "Unknown"
    property string powerProfile: "balanced"
    property bool doNotDisturb: false
    property bool launcherOpen: false
    property bool keybindingHelpOpen: false
    property bool notificationCenterOpen: false
    property string bindingMode: "default"
    property int scratchpadCount: 0
    property var popupNotifications: []
    readonly property int outerMargin: 1
    readonly property int notificationCount: notificationServer.trackedNotifications.values.length

    function runAction(process, command) {
        if (!process.running) {
            process.command = command;
            process.running = true;
        }
    }

    function refreshFast() {
        volumeQuery.running = true;
        sourceVolumeQuery.running = true;
        inputQuery.running = true;
        scratchpadQuery.running = true;
    }

    function parseAudioDevices(text) {
        let section = "";
        const sinks = [];
        const sources = [];
        const lines = text.split("\n");

        for (let index = 0; index < lines.length; ++index) {
            const line = lines[index];
            if (line.includes("Sinks:")) {
                section = "sinks";
                continue;
            }
            if (line.includes("Sources:")) {
                section = "sources";
                continue;
            }
            if (line.match(/^\s*[├└]─\s+\S.*:$/)) {
                section = "";
                continue;
            }
            if (section === "")
                continue;

            const cleaned = line.replace(/[│├└─]/g, " ");
            const match = cleaned.match(/^\s*(\*)?\s*(\d+)\.\s+(.+?)\s*$/);
            if (!match)
                continue;

            const device = {
                id: match[2],
                name: match[3].replace(/\s+\[vol:.*$/, ""),
                active: match[1] === "*"
            };
            if (section === "sinks")
                sinks.push(device);
            else
                sources.push(device);
        }

        outputDevices = sinks;
        inputDevices = sources;
    }

    function refreshSlow() {
        brightnessQuery.running = true;
        networkQuery.running = true;
        audioStatusQuery.running = true;
        batteryQuery.running = true;
        powerProfileQuery.running = true;
    }

    function batteryIcon() {
        if (batteryStatus === "Charging")
            return "󰂄";
        if (batteryPercent >= 95)
            return "󰁹";
        if (batteryPercent >= 85)
            return "󰂂";
        if (batteryPercent >= 75)
            return "󰂁";
        if (batteryPercent >= 65)
            return "󰂀";
        if (batteryPercent >= 55)
            return "󰁿";
        if (batteryPercent >= 45)
            return "󰁾";
        if (batteryPercent >= 35)
            return "󰁽";
        if (batteryPercent >= 25)
            return "󰁼";
        if (batteryPercent >= 15)
            return "󰁻";
        if (batteryPercent >= 5)
            return "󰁺";
        return "󰂎";
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
        popupNotifications = popupNotifications.filter(item => item.id !== notification.id);
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

    function handleHardwareOsd(notification) {
        const channel = notification.hints["x-canonical-private-synchronous"];
        const value = Number(notification.hints.value);

        if (channel === "volume") {
            if (Number.isFinite(value))
                volume = value;
            volumeMuted = notification.summary.toLowerCase().includes("muted");
            return true;
        }

        if (channel === "brightness") {
            if (Number.isFinite(value))
                brightness = value;
            return true;
        }

        return false;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    I3IpcListener {
        subscriptions: ["mode"]

        onIpcEvent: event => {
            try {
                const data = JSON.parse(event.data);
                root.bindingMode = data.change || "default";
            } catch (error) {
                bindingModeQuery.running = true;
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.launcherOpen = !root.launcherOpen;
            if (root.launcherOpen) {
                root.keybindingHelpOpen = false;
                root.notificationCenterOpen = false;
            }
        }

        function close(): void {
            root.launcherOpen = false;
        }
    }

    IpcHandler {
        target: "keybindings"

        function toggle(): void {
            root.keybindingHelpOpen = !root.keybindingHelpOpen;
            if (root.keybindingHelpOpen) {
                root.launcherOpen = false;
                root.notificationCenterOpen = false;
            }
        }

        function close(): void {
            root.keybindingHelpOpen = false;
        }
    }

    IpcHandler {
        target: "notification-center"

        function toggle(): void {
            root.notificationCenterOpen = !root.notificationCenterOpen;
            if (root.notificationCenterOpen) {
                root.launcherOpen = false;
                root.keybindingHelpOpen = false;
            }
        }

        function close(): void {
            root.notificationCenterOpen = false;
        }
    }

    NotificationServer {
        id: notificationServer
        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        bodyMarkupSupported: false

        onNotification: notification => {
            if (root.handleHardwareOsd(notification)) {
                notification.tracked = false;
                return;
            }

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
        id: sourceVolumeQuery
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/Volume:\s+([0-9.]+)/);
                if (match)
                    root.inputVolume = Math.round(Number(match[1]) * 100);
                root.inputVolumeMuted = text.includes("[MUTED]");
            }
        }
    }

    Process {
        id: audioStatusQuery
        command: ["wpctl", "status", "-n"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parseAudioDevices(text)
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
        id: batteryQuery
        command: ["sh", "-c", "for battery in /sys/class/power_supply/*; do [ \"$(cat \"$battery/type\" 2>/dev/null)\" = Battery ] || continue; printf '%s\\t%s\\n' \"$(cat \"$battery/capacity\")\" \"$(cat \"$battery/status\")\"; exit 0; done; exit 1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split("\t");
                root.batteryAvailable = fields.length === 2;
                if (root.batteryAvailable) {
                    root.batteryPercent = Number(fields[0]);
                    root.batteryStatus = fields[1];
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                root.batteryAvailable = false;
        }
    }

    Process {
        id: powerProfileQuery
        command: ["busctl", "--system", "get-property",
            "net.hadess.PowerProfiles", "/net/hadess/PowerProfiles",
            "net.hadess.PowerProfiles", "ActiveProfile"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/"([^"]+)"/);
                if (match)
                    root.powerProfile = match[1];
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
        id: bindingModeQuery
        command: ["swaymsg", "-r", "-t", "get_binding_state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.bindingMode = JSON.parse(text).name || "default";
                } catch (error) {
                    root.bindingMode = "default";
                }
            }
        }
    }

    Process {
        id: volumeAction
        onExited: {
            volumeQuery.running = true;
            sourceVolumeQuery.running = true;
        }
    }

    Process {
        id: audioDeviceAction
        onExited: {
            audioStatusQuery.running = true;
            volumeQuery.running = true;
            sourceVolumeQuery.running = true;
        }
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
        id: networkEditorAction
        onExited: networkQuery.running = true
    }

    Process {
        id: powerAction
    }

    Process {
        id: powerProfileAction
        onExited: powerProfileQuery.running = true
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
            right: root.outerMargin
        }

        Column {
            id: popupColumn
            width: parent.width
            spacing: 8

            Repeater {
                model: root.popupNotifications

                NotificationCard {
                    id: popupCard
                    required property var modelData
                    width: popupColumn.width
                    notification: modelData
                    palette: theme.colors
                    popupMode: true
                    onActivated: root.activateNotification(modelData)
                    onDismissed: {
                        root.hideNotificationPopup(modelData);
                        modelData.dismiss();
                    }

                    Timer {
                        interval: popupCard.notification.expireTimeout > 0
                            ? Math.max(1000, popupCard.notification.expireTimeout) : 5000
                        running: true
                        onTriggered: {
                            root.hideNotificationPopup(popupCard.notification);
                            if (popupCard.notification.transient)
                                popupCard.notification.expire();
                        }
                    }

                    Connections {
                        target: popupCard.notification
                        function onClosed() {
                            root.hideNotificationPopup(popupCard.notification);
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
            property bool powerProfileMenuOpen: false
            property bool audioMenuOpen: false
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

            AudioPopup {
                anchorWindow: bar
                palette: theme.colors
                open: bar.audioMenuOpen
                outputVolume: root.volume
                outputMuted: root.volumeMuted
                inputVolume: root.inputVolume
                inputMuted: root.inputVolumeMuted
                outputDevices: root.outputDevices
                inputDevices: root.inputDevices
                onDismissed: bar.audioMenuOpen = false
                onOutputVolumeRequested: value => root.runAction(volumeAction,
                    ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", value + "%"])
                onInputVolumeRequested: value => root.runAction(volumeAction,
                    ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SOURCE@", value + "%"])
                onOutputMuteRequested: root.runAction(volumeAction,
                    ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                onInputMuteRequested: root.runAction(volumeAction,
                    ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"])
                onOutputDeviceRequested: id => root.runAction(audioDeviceAction,
                    ["wpctl", "set-default", id])
                onInputDeviceRequested: id => root.runAction(audioDeviceAction,
                    ["wpctl", "set-default", id])
            }

            ApplicationLauncher {
                anchorWindow: bar
                palette: theme.colors
                open: root.launcherOpen && I3.focusedMonitor !== null
                    && I3.focusedMonitor.name === bar.screen.name
                onDismissed: root.launcherOpen = false
            }

            KeybindingHelp {
                anchorWindow: bar
                palette: theme.colors
                open: root.keybindingHelpOpen && I3.focusedMonitor !== null
                    && I3.focusedMonitor.name === bar.screen.name
                onDismissed: root.keybindingHelpOpen = false
            }

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 32
            color: theme.colors.bg0

            RowLayout {
                anchors {
                    left: parent.left
                    leftMargin: root.outerMargin
                    verticalCenter: parent.verticalCenter
                }
                spacing: 6

                Repeater {
                    model: 5

                    Rectangle {
                        required property int index
                        readonly property int workspaceNumber: index + 1
                        readonly property var workspace: I3.findWorkspaceByName(workspaceNumber.toString())
                        readonly property bool active: I3.focusedWorkspace !== null
                            && I3.focusedWorkspace.number === workspaceNumber

                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 24
                        radius: 4
                        color: active ? theme.colors.green : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: workspaceNumber
                            color: active ? theme.colors.bg0
                                : workspace !== null && workspace.urgent
                                    ? theme.colors.red : theme.colors.fg
                            font.pixelSize: 13
                            font.family: "Cascadia Mono NF"
                            font.bold: active
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: I3.dispatch("workspace number " + workspaceNumber)
                        }
                    }
                }

                StatusPill {
                    palette: theme.colors
                    icon: "󰆍"
                    text: root.scratchpadCount > 0 ? root.scratchpadCount.toString() : ""
                    active: root.scratchpadCount > 0
                    onClicked: I3.dispatch("scratchpad show")
                }

                StatusPill {
                    palette: theme.colors
                    icon: "󰘳"
                    text: root.bindingMode
                    active: root.bindingMode !== "default"
                    interactive: false
                }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                StatusPill {
                    palette: theme.colors
                    icon: root.doNotDisturb ? "󰅶" : "󰛊"
                    iconOpacity: root.doNotDisturb ? 1.0 : 0.5
                    active: root.doNotDisturb
                    onClicked: root.doNotDisturb = !root.doNotDisturb
                }

                StatusPill {
                    palette: theme.colors
                    text: Qt.formatDateTime(clock.date, "ddd, MMM d  HH:mm")
                    interactive: false
                }

                StatusPill {
                    palette: theme.colors
                    id: notificationButton
                    icon: root.notificationCount > 0 ? "󰂞" : "󰂜"
                    text: root.notificationCount > 0 ? root.notificationCount.toString() : ""
                    active: root.notificationCenterOpen
                    onClicked: root.notificationCenterOpen = !root.notificationCenterOpen
                }
            }

            PopupWindow {
                id: notificationCenter
                visible: root.notificationCenterOpen && I3.focusedMonitor !== null
                    && I3.focusedMonitor.name === bar.screen.name
                grabFocus: true
                implicitWidth: 380
                implicitHeight: 440
                color: "transparent"

                anchor.window: bar
                anchor.rect.x: Math.round(bar.width / 2 - width / 2)
                anchor.rect.y: bar.height + 8

                onVisibleChanged: {
                    if (!visible)
                        root.notificationCenterOpen = false;
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: theme.colors.bg1
                    border.color: theme.colors.bg3
                    border.width: 1

                    Text {
                        id: notificationTitle
                        anchors {
                            top: parent.top
                            left: parent.left
                            margins: 16
                        }
                        text: "Notifications"
                        color: theme.colors.fg
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
                        color: clearNotificationsMouse.containsMouse
                            ? theme.colors.bg3 : "transparent"

                        Text {
                            id: clearNotificationsLabel
                            anchors.centerIn: parent
                            text: "Clear"
                            color: theme.colors.red
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
                        color: theme.colors.bg3
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.notificationCount === 0
                        text: "󰂜\nNo notifications"
                        horizontalAlignment: Text.AlignHCenter
                        color: theme.colors.grey1
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
                            palette: theme.colors
                            onActivated: root.activateNotification(modelData)
                            onDismissed: {
                                root.hideNotificationPopup(modelData);
                                modelData.dismiss();
                            }
                        }
                    }
                }
            }

            PopupWindow {
                id: powerProfileMenu
                visible: bar.powerProfileMenuOpen
                grabFocus: true
                implicitWidth: 230
                implicitHeight: 166
                color: "transparent"

                anchor.window: bar
                anchor.rect.x: bar.width - width - root.outerMargin
                anchor.rect.y: bar.height + 8

                onVisibleChanged: {
                    if (!visible)
                        bar.powerProfileMenuOpen = false;
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: theme.colors.bg1
                    border.color: theme.colors.bg3
                    border.width: 1

                    Text {
                        id: powerProfileTitle
                        anchors {
                            top: parent.top
                            left: parent.left
                            topMargin: 12
                            leftMargin: 14
                        }
                        text: "Power profile"
                        color: theme.colors.fg
                        font.family: "Cascadia Mono NF"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Column {
                        anchors {
                            top: powerProfileTitle.bottom
                            left: parent.left
                            right: parent.right
                            topMargin: 10
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 4

                        Repeater {
                            model: [
                                { name: "Power Saver", profile: "power-saver", icon: "󰌪" },
                                { name: "Balanced", profile: "balanced", icon: "󰾅" },
                                { name: "Performance", profile: "performance", icon: "󰓅" }
                            ]

                            Rectangle {
                                required property var modelData
                                readonly property bool selected:
                                    root.powerProfile === modelData.profile

                                width: parent.width
                                height: 32
                                radius: 6
                                color: selected ? theme.colors.green
                                    : profileMouse.containsMouse ? theme.colors.bg3 : "transparent"

                                Row {
                                    anchors {
                                        left: parent.left
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 10
                                    }
                                    spacing: 10

                                    Text {
                                        text: modelData.icon
                                        color: selected ? theme.colors.bg0 : theme.colors.green
                                        font.family: "Cascadia Mono NF"
                                        font.pixelSize: 16
                                    }

                                    Text {
                                        text: modelData.name
                                        color: selected ? theme.colors.bg0 : theme.colors.fg
                                        font.family: "Cascadia Mono NF"
                                        font.pixelSize: 12
                                        font.bold: selected
                                    }
                                }

                                MouseArea {
                                    id: profileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.runAction(powerProfileAction,
                                            ["busctl", "--system", "set-property",
                                                "net.hadess.PowerProfiles",
                                                "/net/hadess/PowerProfiles",
                                                "net.hadess.PowerProfiles",
                                                "ActiveProfile", "s", modelData.profile]);
                                        bar.powerProfileMenuOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            PopupWindow {
                id: powerMenu
                visible: bar.powerMenuOpen
                grabFocus: true
                implicitWidth: 400
                implicitHeight: 170
                color: "transparent"

                anchor.window: bar
                anchor.rect.x: Math.round(bar.width / 2 - width / 2)
                anchor.rect.y: Math.round(bar.screen.height / 2 - height / 2)

                onVisibleChanged: {
                    if (!visible) {
                        bar.powerMenuOpen = false;
                        bar.pendingPowerAction = "";
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: theme.colors.bg1
                    border.color: theme.colors.bg3
                    border.width: 1

                    Text {
                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                            topMargin: 16
                        }
                        text: bar.pendingPowerAction === ""
                            ? "Power menu" : "Click again to confirm"
                        color: bar.pendingPowerAction === ""
                            ? theme.colors.fg : theme.colors.red
                        font.family: "Cascadia Mono NF"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Row {
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            bottom: parent.bottom
                            bottomMargin: 16
                        }
                        spacing: 10

                        PowerActionButton {
                            palette: theme.colors
                            icon: "󰌾"
                            label: "Lock"
                            onClicked: bar.choosePowerAction("lock", ["gtklock", "--daemonize"])
                        }

                        PowerActionButton {
                            palette: theme.colors
                            icon: "󰜉"
                            label: bar.pendingPowerAction === "reboot" ? "Confirm" : "Reboot"
                            accentColor: theme.colors.red
                            confirmationPending: bar.pendingPowerAction === "reboot"
                            onClicked: bar.choosePowerAction("reboot", ["systemctl", "reboot"])
                        }

                        PowerActionButton {
                            palette: theme.colors
                            icon: "󰐥"
                            label: bar.pendingPowerAction === "shutdown" ? "Confirm" : "Shutdown"
                            accentColor: theme.colors.red
                            confirmationPending: bar.pendingPowerAction === "shutdown"
                            onClicked: bar.choosePowerAction("shutdown", ["systemctl", "poweroff"])
                        }
                    }
                }
            }

            RowLayout {
                anchors {
                    right: parent.right
                    rightMargin: root.outerMargin
                    verticalCenter: parent.verticalCenter
                }
                spacing: 6

                StatusPill {
                    palette: theme.colors
                    icon: root.volumeMuted || root.volume === 0 ? "󰖁"
                        : root.volume < 50 ? "󰕿" : "󰕾"
                    secondaryIcon: root.inputVolumeMuted ? "󰍭" : "󰍬"
                    text: root.volume + "%"
                    onClicked: {
                        bar.audioMenuOpen = !bar.audioMenuOpen;
                        if (bar.audioMenuOpen)
                            audioStatusQuery.running = true;
                    }
                    onWheelUp: root.runAction(volumeAction,
                        ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", "5%+"])
                    onWheelDown: root.runAction(volumeAction,
                        ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
                }

                StatusPill {
                    palette: theme.colors
                    icon: "󰃠"
                    text: root.brightness + "%"
                    onWheelUp: root.runAction(brightnessAction, ["brightnessctl", "set", "+5%"])
                    onWheelDown: root.runAction(brightnessAction, ["brightnessctl", "set", "5%-"])
                }

                StatusPill {
                    palette: theme.colors
                    icon: root.network === "Disconnected" ? "󰤭" : "󰤨"
                    text: root.network === "Disconnected" ? "" : root.network
                    onClicked: root.runAction(networkEditorAction,
                        ["nm-connection-editor"])
                }

                StatusPill {
                    palette: theme.colors
                    icon: "󰌌"
                    text: root.inputLanguage
                    onClicked: root.runAction(inputAction,
                        ["swaymsg", "input", "type:keyboard", "xkb_switch_layout", "next"])
                }

                StatusPill {
                    id: batteryButton
                    palette: theme.colors
                    visible: root.batteryAvailable
                    icon: root.batteryIcon()
                    text: root.batteryPercent + "%"
                    active: bar.powerProfileMenuOpen
                        || (root.batteryStatus !== "Charging" && root.batteryPercent <= 20)
                    highlightColor: root.batteryStatus !== "Charging"
                        && root.batteryPercent <= 20 ? theme.colors.red : theme.colors.green
                    onClicked: bar.powerProfileMenuOpen = !bar.powerProfileMenuOpen
                }

                StatusPill {
                    palette: theme.colors
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
