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

    function switchInputLayout() {
        I3.dispatch("input type:keyboard xkb_switch_layout next");
        inputRefresh.restart();
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

    function shortLanguage(name) {
        if (!name)
            return "--";
        return name.split(/[ (]/)[0].slice(0, 2).toUpperCase();
    }

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    I3IpcListener {
        subscriptions: ["mode", "window", "input"]

        onIpcEvent: event => {
            try {
                const data = JSON.parse(event.data);
                if (event.type === "mode") {
                    root.bindingMode = data.change || "default";
                } else if (event.type === "input") {
                    root.inputLanguage = root.shortLanguage(
                        data.input?.xkb_active_layout_name);
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

    Timer {
        id: inputRefresh
        interval: 150
        onTriggered: inputQuery.running = true
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: brightnessQuery.running = true
    }
}
