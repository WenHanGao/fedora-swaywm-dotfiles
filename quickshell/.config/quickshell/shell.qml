import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import Quickshell.Io

ShellRoot {
    id: root

    property int volume: 0
    property bool volumeMuted: false
    property int brightness: 0
    property string network: "Disconnected"
    property string inputLanguage: "--"
    property bool doNotDisturb: false
    property int scratchpadCount: 0

    function runAction(process, command) {
        if (!process.running) {
            process.command = command;
            process.running = true;
        }
    }

    function refreshFast() {
        volumeQuery.running = true;
        dndQuery.running = true;
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

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
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
        id: dndQuery
        command: ["dunstctl", "is-paused"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.doNotDisturb = text.trim() === "true"
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
        id: dndAction
        onExited: dndQuery.running = true
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

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            property bool powerMenuOpen: false
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
                    text: Qt.formatDateTime(clock.date, "ddd, MMM d  HH:mm")
                    interactive: false
                }

                StatusPill {
                    icon: root.doNotDisturb ? "󰂛" : "󰂚"
                    active: root.doNotDisturb
                    onClicked: root.runAction(dndAction, ["dunstctl", "set-paused", "toggle"])
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
