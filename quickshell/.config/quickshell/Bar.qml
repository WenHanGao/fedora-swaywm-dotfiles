import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property var theme
    required property var systemState
    required property var notificationServer
    property bool launcherOpen: false
    property bool keybindingHelpOpen: false
    property bool notificationCenterOpen: false
    property bool powerMenuOpen: false
    property bool stayAwake: false
    property bool doNotDisturb: false
    property bool primaryForInhibitor: false
    property bool focused: false
    readonly property bool compact: width < 1200
    readonly property bool veryCompact: width < 900
    readonly property int notificationCount:
        notificationServer.trackedNotifications.values.length

    signal launcherToggled
    signal keybindingHelpToggled
    signal notificationCenterToggled
    signal powerMenuToggled
    signal stayAwakeToggled
    signal doNotDisturbToggled
    signal notificationActivated(var notification)
    signal notificationDismissed(var notification)
    signal notificationsClearRequested
    signal advancedBluetoothRequested
    signal advancedNetworkRequested

    screen: targetScreen

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: theme.design.barHeight
    color: theme.colors.bg1

    function closeLocalMenus(except) {
        const targetWasOpen = pendingLocalMenu === except
            || (except === "audio" && audioMenuOpen)
            || (except === "brightness" && brightnessMenuOpen)
            || (except === "bluetooth" && bluetoothMenuOpen)
            || (except === "network" && networkMenuOpen)
            || (except === "profile" && powerProfileMenuOpen)
            || (except === "agent" && agentUsageMenuOpen);

        localMenuSwitch.stop();
        pendingLocalMenu = "";
        audioMenuOpen = false;
        brightnessMenuOpen = false;
        bluetoothMenuOpen = false;
        networkMenuOpen = false;
        powerProfileMenuOpen = false;
        agentUsageMenuOpen = false;

        if (!targetWasOpen) {
            pendingLocalMenu = except;
            localMenuSwitch.start();
        }

        return !targetWasOpen;
    }

    property string pendingLocalMenu: ""
    property bool audioMenuOpen: false
    property bool brightnessMenuOpen: false
    property bool bluetoothMenuOpen: false
    property bool networkMenuOpen: false
    property bool powerProfileMenuOpen: false
    property bool agentUsageMenuOpen: false

    Timer {
        id: localMenuSwitch
        interval: 0
        onTriggered: {
            const target = root.pendingLocalMenu;
            root.pendingLocalMenu = "";
            root.audioMenuOpen = target === "audio";
            root.brightnessMenuOpen = target === "brightness";
            root.bluetoothMenuOpen = target === "bluetooth";
            root.networkMenuOpen = target === "network";
            root.powerProfileMenuOpen = target === "profile";
            root.agentUsageMenuOpen = target === "agent";
        }
    }

    IdleInhibitor {
        window: root
        enabled: root.stayAwake && root.primaryForInhibitor
    }

    AudioPopup {
        anchorWindow: root
        palette: root.theme.colors
        tokens: root.theme.design
        open: root.audioMenuOpen
        outputVolume: root.systemState.volume
        outputMuted: root.systemState.volumeMuted
        inputVolume: root.systemState.inputVolume
        inputMuted: root.systemState.inputVolumeMuted
        outputDevices: root.systemState.outputDevices
        inputDevices: root.systemState.inputDevices
        activeOutput: root.systemState.outputNode
        activeInput: root.systemState.inputNode
        onDismissed: root.audioMenuOpen = false
        onOutputVolumeRequested: value => root.systemState.setOutputVolume(value)
        onInputVolumeRequested: value => root.systemState.setInputVolume(value)
        onOutputMuteRequested: root.systemState.toggleOutputMute()
        onInputMuteRequested: root.systemState.toggleInputMute()
        onOutputDeviceRequested: device => root.systemState.selectOutput(device)
        onInputDeviceRequested: device => root.systemState.selectInput(device)
    }

    BrightnessPopup {
        anchorWindow: root
        palette: root.theme.colors
        tokens: root.theme.design
        open: root.brightnessMenuOpen
        brightness: root.systemState.brightness
        displays: root.systemState.displays
        onDismissed: root.brightnessMenuOpen = false
        onBrightnessRequested: value => root.systemState.setBrightness(value)
        onScaleRequested: (displayName, scale) =>
            root.systemState.setDisplayScale(displayName, scale)
    }

    BluetoothPopup {
        anchorWindow: root
        palette: root.theme.colors
        tokens: root.theme.design
        adapter: root.systemState.bluetoothAdapter
        open: root.bluetoothMenuOpen
        onDismissed: root.bluetoothMenuOpen = false
        onAdvancedSetupRequested: {
            root.bluetoothMenuOpen = false;
            root.advancedBluetoothRequested();
        }
    }

    NetworkPopup {
        anchorWindow: root
        palette: root.theme.colors
        tokens: root.theme.design
        wifiDevice: root.systemState.wifiDevice
        open: root.networkMenuOpen
        onDismissed: root.networkMenuOpen = false
        onAdvancedSetupRequested: {
            root.networkMenuOpen = false;
            root.advancedNetworkRequested();
        }
    }

    PowerProfilePopup {
        anchorWindow: root
        palette: root.theme.colors
        tokens: root.theme.design
        open: root.powerProfileMenuOpen
        currentProfile: root.systemState.powerProfile
        performanceAvailable: root.systemState.performanceProfileAvailable
        onDismissed: root.powerProfileMenuOpen = false
        onProfileRequested: profile => root.systemState.setPowerProfile(profile)
    }

    AgentUsagePopup {
        anchorWindow: root
        anchorItem: agentUsagePill
        palette: root.theme.colors
        tokens: root.theme.design
        open: root.agentUsageMenuOpen
        available: root.systemState.agentUsageAvailable
        plan: root.systemState.agentPlan
        primaryUsed: root.systemState.agentPrimaryUsed
        primaryWindow: root.systemState.agentPrimaryWindow
        primaryReset: root.systemState.agentPrimaryReset
        secondaryUsed: root.systemState.agentSecondaryUsed
        secondaryWindow: root.systemState.agentSecondaryWindow
        secondaryReset: root.systemState.agentSecondaryReset
        totalTokens: root.systemState.agentTotalTokens
        claudeAvailable: root.systemState.claudeUsageAvailable
        claudeModel: root.systemState.claudeModel
        claudeInputTokens: root.systemState.claudeInputTokens
        claudeOutputTokens: root.systemState.claudeOutputTokens
        onDismissed: root.agentUsageMenuOpen = false
    }

    ApplicationLauncher {
        anchorWindow: root
        palette: root.theme.colors
        tokens: root.theme.design
        open: root.launcherOpen && root.focused
        onDismissed: root.launcherToggled()
    }

    KeybindingHelp {
        anchorWindow: root
        palette: root.theme.colors
        tokens: root.theme.design
        open: root.keybindingHelpOpen && root.focused
        onDismissed: root.keybindingHelpToggled()
    }

    NotificationCenter {
        anchorWindow: root
        palette: root.theme.colors
        tokens: root.theme.design
        notificationServer: root.notificationServer
        open: root.notificationCenterOpen && root.focused
        onDismissed: root.notificationCenterToggled()
        onNotificationActivated: notification => root.notificationActivated(notification)
        onNotificationDismissed: notification => root.notificationDismissed(notification)
        onClearRequested: root.notificationsClearRequested()
    }

    RowLayout {
        anchors {
            left: parent.left
            leftMargin: root.theme.design.spaceSm
            verticalCenter: parent.verticalCenter
        }
        spacing: root.theme.design.spaceXs

        Repeater {
            model: 5

            Rectangle {
                required property int index
                readonly property int workspaceNumber: index + 1
                readonly property var workspace:
                    I3.findWorkspaceByName(workspaceNumber.toString())
                readonly property bool active: I3.focusedWorkspace !== null
                    && I3.focusedWorkspace.number === workspaceNumber
                readonly property bool occupied: workspace !== null
                readonly property bool urgent: occupied && workspace.urgent

                Layout.preferredWidth: root.theme.design.controlHeight
                Layout.preferredHeight: root.theme.design.controlHeight
                radius: root.theme.design.radiusSm
                color: active ? root.theme.colors.green
                    : urgent ? root.theme.colors.bg_red
                    : workspaceMouse.containsMouse ? root.theme.colors.bg3
                    : occupied ? root.theme.colors.bg2 : "transparent"

                Behavior on color {
                    ColorAnimation { duration: root.theme.design.transitionFast }
                }

                Text {
                    anchors.centerIn: parent
                    text: workspaceNumber
                    color: parent.active ? root.theme.colors.bg0
                        : parent.urgent ? root.theme.colors.red
                        : parent.occupied ? root.theme.colors.aqua
                        : root.theme.colors.grey1
                    font.family: root.theme.design.monoFont
                    font.pixelSize: root.theme.design.textMd
                    font.weight: parent.active || parent.occupied
                        ? Font.Bold : Font.Medium

                    Behavior on color {
                        ColorAnimation { duration: root.theme.design.transitionFast }
                    }
                }

                MouseArea {
                    id: workspaceMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: I3.dispatch("workspace number " + parent.workspaceNumber)
                }
            }
        }

        StatusPill {
            visible: root.systemState.scratchpadCount > 0
            palette: root.theme.colors
            tokens: root.theme.design
            icon: "󰆍"
            text: root.systemState.scratchpadCount.toString()
            active: true
            onClicked: I3.dispatch("scratchpad show")
        }

        StatusPill {
            visible: root.systemState.bindingMode !== "default"
            palette: root.theme.colors
            tokens: root.theme.design
            icon: "󰘳"
            text: root.systemState.bindingMode
            active: true
            interactive: false
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: root.theme.design.spaceXs

        StatusPill {
            palette: root.theme.colors
            tokens: root.theme.design
            icon: root.stayAwake ? "󰅶" : "󰛊"
            iconOpacity: root.stayAwake ? 1 : 0.45
            active: root.stayAwake
            onClicked: root.stayAwakeToggled()
        }

        StatusPill {
            palette: root.theme.colors
            tokens: root.theme.design
            icon: "󰪑"
            iconOpacity: root.doNotDisturb ? 1 : 0.45
            active: root.doNotDisturb
            onClicked: root.doNotDisturbToggled()
        }

        StatusPill {
            palette: root.theme.colors
            tokens: root.theme.design
            text: Qt.formatDateTime(clock.date,
                root.veryCompact ? "HH:mm" : "ddd, MMM d  HH:mm")
            interactive: false
        }

        StatusPill {
            palette: root.theme.colors
            tokens: root.theme.design
            icon: root.notificationCount > 0 ? "󰂞" : "󰂜"
            text: root.notificationCount > 0
                ? root.notificationCount.toString() : ""
            active: root.notificationCenterOpen
            onClicked: root.notificationCenterToggled()
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        anchors {
            right: parent.right
            rightMargin: root.theme.design.spaceSm
            verticalCenter: parent.verticalCenter
        }
        spacing: root.theme.design.spaceXs

        StatusPill {
            id: agentUsagePill
            palette: root.theme.colors
            tokens: root.theme.design
            icon: "󰚩"
            text: root.veryCompact || !root.systemState.agentUsageAvailable
                ? "" : Math.round(root.systemState.agentPrimaryUsed) + "%"
            active: root.agentUsageMenuOpen
            highlightColor: root.systemState.agentPrimaryUsed >= 90
                ? root.theme.colors.red
                : root.systemState.agentPrimaryUsed >= 70
                    ? root.theme.colors.yellow : root.theme.colors.green
            onClicked: {
                const opening = root.closeLocalMenus("agent");
                if (opening)
                    root.systemState.refreshAgentUsage();
            }
        }

        StatusPill {
            palette: root.theme.colors
            tokens: root.theme.design
            icon: root.systemState.volumeMuted || root.systemState.volume === 0 ? "󰖁"
                : root.systemState.volume < 50 ? "󰕿" : "󰕾"
            secondaryIcon: root.veryCompact ? ""
                : root.systemState.inputVolumeMuted ? "󰍭" : "󰍬"
            text: root.compact ? "" : root.systemState.volume + "%"
            active: root.audioMenuOpen
            onClicked: root.closeLocalMenus("audio")
            onWheelUp: root.systemState.adjustOutputVolume(5)
            onWheelDown: root.systemState.adjustOutputVolume(-5)
        }

        StatusPill {
            visible: !root.veryCompact
            palette: root.theme.colors
            tokens: root.theme.design
            icon: "󰍹"
            text: root.compact ? "" : root.systemState.brightness + "%"
            active: root.brightnessMenuOpen
            onClicked: root.closeLocalMenus("brightness")
            onWheelUp: root.systemState.adjustBrightness(5)
            onWheelDown: root.systemState.adjustBrightness(-5)
        }

        StatusPill {
            visible: root.systemState.bluetoothAdapter !== null
            palette: root.theme.colors
            tokens: root.theme.design
            icon: !root.systemState.bluetoothEnabled ? "󰂲"
                : root.systemState.connectedBluetoothDevices.length > 0 ? "󰂱" : "󰂯"
            text: root.compact ? "" : root.systemState.bluetoothDeviceName
            maximumTextWidth: 140
            active: root.bluetoothMenuOpen
            iconOpacity: root.systemState.bluetoothEnabled ? 1 : 0.45
            onClicked: root.closeLocalMenus("bluetooth")
        }

        StatusPill {
            palette: root.theme.colors
            tokens: root.theme.design
            icon: root.systemState.network === "Disconnected" ? "󰤭" : "󰤨"
            text: root.compact || root.systemState.network === "Disconnected"
                ? "" : root.systemState.network
            maximumTextWidth: 140
            active: root.networkMenuOpen
            onClicked: root.closeLocalMenus("network")
        }

        StatusPill {
            visible: !root.compact
            palette: root.theme.colors
            tokens: root.theme.design
            icon: "󰌌"
            text: root.systemState.inputLanguage
            onClicked: root.systemState.toggleInputMethod()
        }

        StatusPill {
            visible: root.systemState.batteryAvailable
            palette: root.theme.colors
            tokens: root.theme.design
            icon: batteryIcon()
            text: root.compact ? "" : root.systemState.batteryPercent + "%"
            active: root.powerProfileMenuOpen
                || (root.systemState.batteryStatus !== "Charging"
                    && root.systemState.batteryPercent <= 20)
            highlightColor: root.systemState.batteryStatus !== "Charging"
                && root.systemState.batteryPercent <= 20
                    ? root.theme.colors.red : root.theme.colors.green
            onClicked: root.closeLocalMenus("profile")

            function batteryIcon() {
                if (root.systemState.batteryStatus === "Charging")
                    return "󰂄";
                const percent = root.systemState.batteryPercent;
                if (percent >= 95) return "󰁹";
                if (percent >= 75) return "󰂁";
                if (percent >= 55) return "󰁿";
                if (percent >= 35) return "󰁽";
                if (percent >= 15) return "󰁻";
                return "󰂎";
            }
        }

        StatusPill {
            palette: root.theme.colors
            tokens: root.theme.design
            icon: "󰐥"
            active: root.powerMenuOpen
            onClicked: root.powerMenuToggled()
        }
    }
}
