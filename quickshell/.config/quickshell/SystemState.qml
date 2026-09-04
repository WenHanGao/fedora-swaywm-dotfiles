import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root

    readonly property var outputNode: Pipewire.defaultAudioSink
    readonly property var inputNode: Pipewire.defaultAudioSource
    readonly property int volume: outputNode && outputNode.audio
        ? Math.round(outputNode.audio.volume * 100) : 0
    readonly property bool volumeMuted: outputNode && outputNode.audio
        ? outputNode.audio.muted : false
    readonly property int inputVolume: inputNode && inputNode.audio
        ? Math.round(inputNode.audio.volume * 100) : 0
    readonly property bool inputVolumeMuted: inputNode && inputNode.audio
        ? inputNode.audio.muted : false
    readonly property var outputDevices: Pipewire.nodes.values.filter(node =>
        node.ready && node.audio && !node.isStream
            && node.properties["media.class"] === "Audio/Sink")
    readonly property var inputDevices: Pipewire.nodes.values.filter(node =>
        node.ready && node.audio && !node.isStream
            && node.properties["media.class"] === "Audio/Source")

    property int brightness: 0
    property int pendingBrightness: -1
    readonly property var displays: I3.monitors.values.map(monitor => ({
        name: monitor.name,
        label: monitor.name,
        focused: monitor.focused,
        scale: Number(monitor.scale || 1)
    }))

    readonly property var wifiDevice: Networking.devices.values.find(device =>
        device.type === DeviceType.Wifi) || null
    readonly property var connectedNetwork: wifiDevice
        ? wifiDevice.networks.values.find(candidate => candidate.connected) || null : null
    readonly property string network: connectedNetwork ? connectedNetwork.name : "Disconnected"

    property string inputLanguage: "--"
    property string bindingMode: "default"
    property int scratchpadCount: 0

    property bool agentUsageAvailable: false
    property string agentPlan: ""
    property real agentPrimaryUsed: 0
    property int agentPrimaryWindow: 0
    property double agentPrimaryReset: 0
    property real agentSecondaryUsed: 0
    property int agentSecondaryWindow: 0
    property double agentSecondaryReset: 0
    property double agentTotalTokens: 0
    property bool claudeUsageAvailable: false
    property string claudeModel: ""
    property double claudeInputTokens: 0
    property double claudeOutputTokens: 0
    property double claudeTotalTokens: 0

    readonly property var battery: UPower.displayDevice
    readonly property bool batteryAvailable: battery && battery.ready && battery.isPresent
    readonly property int batteryPercent: batteryAvailable
        ? Math.round(battery.percentage * 100) : 0
    readonly property string batteryStatus: !batteryAvailable ? "Unknown"
        : battery.state === UPowerDeviceState.Charging ? "Charging"
        : battery.state === UPowerDeviceState.FullyCharged ? "Fully Charged"
        : battery.state === UPowerDeviceState.Discharging ? "Discharging" : "Unknown"
    readonly property string powerProfile:
        PowerProfiles.profile === PowerProfile.PowerSaver ? "power-saver"
        : PowerProfiles.profile === PowerProfile.Performance ? "performance" : "balanced"
    readonly property bool performanceProfileAvailable:
        PowerProfiles.hasPerformanceProfile

    function setOutputVolume(value) {
        if (outputNode && outputNode.audio)
            outputNode.audio.volume = Math.max(0, Math.min(1.5, value / 100));
    }

    function setInputVolume(value) {
        if (inputNode && inputNode.audio)
            inputNode.audio.volume = Math.max(0, Math.min(1.5, value / 100));
    }

    function adjustOutputVolume(delta) {
        setOutputVolume(volume + delta);
    }

    function toggleOutputMute() {
        if (outputNode && outputNode.audio)
            outputNode.audio.muted = !outputNode.audio.muted;
    }

    function toggleInputMute() {
        if (inputNode && inputNode.audio)
            inputNode.audio.muted = !inputNode.audio.muted;
    }

    function selectOutput(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function selectInput(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function setBrightness(value) {
        const normalized = Math.max(1, Math.min(100, Math.round(value)));
        brightness = normalized;
        if (brightnessAction.running) {
            pendingBrightness = normalized;
            return;
        }
        brightnessAction.command = ["brightnessctl", "set", normalized + "%"];
        brightnessAction.running = true;
    }

    function adjustBrightness(delta) {
        setBrightness(brightness + delta);
    }

    function setDisplayScale(displayName, scale) {
        I3.dispatch("output " + displayName + " scale " + scale.toFixed(1));
    }

    function toggleInputMethod() {
        if (!inputToggle.running)
            inputToggle.running = true;
    }

    function setPowerProfile(profile) {
        if (profile === "power-saver")
            PowerProfiles.profile = PowerProfile.PowerSaver;
        else if (profile === "performance" && performanceProfileAvailable)
            PowerProfiles.profile = PowerProfile.Performance;
        else
            PowerProfiles.profile = PowerProfile.Balanced;
    }

    function countScratchpad(node) {
        if (node.name === "__i3_scratch")
            return (node.nodes || []).length + (node.floating_nodes || []).length;
        const children = (node.nodes || []).concat(node.floating_nodes || []);
        for (let index = 0; index < children.length; ++index) {
            const count = countScratchpad(children[index]);
            if (count >= 0)
                return count;
        }
        return -1;
    }

    function refreshAgentUsage() {
        if (!agentUsageQuery.running)
            agentUsageQuery.running = true;
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    I3IpcListener {
        subscriptions: ["mode", "window"]

        onIpcEvent: event => {
            try {
                const data = JSON.parse(event.data);
                if (event.type === "mode") {
                    root.bindingMode = data.change || "default";
                } else if (event.type === "window") {
                    scratchpadQuery.running = true;
                }
            } catch (error) {
                inputQuery.running = true;
                bindingModeQuery.running = true;
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
        id: brightnessAction
        onExited: {
            brightnessQuery.running = true;
            if (root.pendingBrightness >= 0) {
                const pending = root.pendingBrightness;
                root.pendingBrightness = -1;
                Qt.callLater(() => {
                    brightnessAction.command = ["brightnessctl", "set", pending + "%"];
                    brightnessAction.running = true;
                });
            }
        }
    }

    Process {
        id: inputQuery
        command: ["fcitx5-remote", "-n"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const inputMethod = text.trim();
                root.inputLanguage = !inputMethod ? "--"
                    : inputMethod.startsWith("keyboard-") ? "EN" : "ZH";
            }
        }
    }

    Process {
        id: inputToggle
        command: ["fcitx5-remote", "-t"]
        onExited: inputRefresh.restart()
    }

    Process {
        id: scratchpadQuery
        command: ["swaymsg", "-r", "-t", "get_tree"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.scratchpadCount = Math.max(0,
                        root.countScratchpad(JSON.parse(text)));
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
        id: agentUsageQuery
        command: ["bash", (Quickshell.env("XDG_CONFIG_HOME")
            || Quickshell.env("HOME") + "/.config")
            + "/quickshell/scripts/agent-usage"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const usage = JSON.parse(text.trim());
                    root.agentUsageAvailable = usage.available === true;
                    if (root.agentUsageAvailable) {
                        root.agentPlan = usage.plan || "";
                        root.agentPrimaryUsed = Number(usage.primaryUsed || 0);
                        root.agentPrimaryWindow = Number(usage.primaryWindow || 0);
                        root.agentPrimaryReset = Number(usage.primaryReset || 0);
                        root.agentSecondaryUsed = Number(usage.secondaryUsed || 0);
                        root.agentSecondaryWindow = Number(usage.secondaryWindow || 0);
                        root.agentSecondaryReset = Number(usage.secondaryReset || 0);
                        root.agentTotalTokens = Number(usage.totalTokens || 0);
                    }
                    root.claudeUsageAvailable = usage.claudeAvailable === true;
                    root.claudeModel = usage.claudeModel || "";
                    root.claudeInputTokens = Number(usage.claudeInputTokens || 0);
                    root.claudeOutputTokens = Number(usage.claudeOutputTokens || 0);
                    root.claudeTotalTokens = Number(usage.claudeTotalTokens || 0);
                } catch (error) {
                    root.agentUsageAvailable = false;
                    root.claudeUsageAvailable = false;
                }
            }
        }
    }

    Timer {
        id: inputRefresh
        interval: 1000
        running: true
        repeat: true
        onTriggered: inputQuery.running = true
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            brightnessQuery.running = true;
            root.refreshAgentUsage();
        }
    }
}
