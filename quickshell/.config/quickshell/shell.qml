import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Io
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    Theme {
        id: appTheme
    }

    SystemState {
        id: stateModel
    }

    property bool doNotDisturb: false
    property bool stayAwake: false
    property bool launcherOpen: false
    property bool keybindingHelpOpen: false
    property bool notificationCenterOpen: false
    property bool powerMenuOpen: false
    property var popupNotifications: []
    readonly property var focusedScreen: {
        if (I3.focusedMonitor !== null) {
            const match = Quickshell.screens.find(screen =>
                screen.name === I3.focusedMonitor.name);
            if (match)
                return match;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function toggleOverlay(name) {
        let opening = false;
        if (name === "launcher")
            opening = !launcherOpen;
        else if (name === "keybindings")
            opening = !keybindingHelpOpen;
        else if (name === "notifications")
            opening = !notificationCenterOpen;
        else if (name === "power")
            opening = !powerMenuOpen;

        launcherOpen = name === "launcher" && opening;
        keybindingHelpOpen = name === "keybindings" && opening;
        notificationCenterOpen = name === "notifications" && opening;
        powerMenuOpen = name === "power" && opening;
    }

    function closeOverlay(name) {
        if (name === "launcher")
            launcherOpen = false;
        else if (name === "keybindings")
            keybindingHelpOpen = false;
        else if (name === "notifications")
            notificationCenterOpen = false;
        else if (name === "power")
            powerMenuOpen = false;
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

    function dismissNotification(notification) {
        hideNotificationPopup(notification);
        notification.dismiss();
    }

    function clearNotificationHistory() {
        const notifications = notificationService.trackedNotifications.values.slice();
        popupNotifications = [];
        for (let index = 0; index < notifications.length; ++index)
            notifications[index].dismiss();
    }

    function handleHardwareOsd(notification) {
        const channel = notification.hints["x-canonical-private-synchronous"];
        if (channel === "volume")
            return true;
        if (channel === "brightness") {
            const value = Number(notification.hints.value);
            if (Number.isFinite(value))
                stateModel.brightness = value;
            return true;
        }
        return false;
    }

    function runPowerAction(action) {
        if (action === "lock") {
            const configHome = Quickshell.env("XDG_CONFIG_HOME")
                || Quickshell.env("HOME") + "/.config";
            Quickshell.execDetached([configHome + "/gtklock/lock", "--daemonize"]);
        } else if (action === "reboot")
            Quickshell.execDetached(["systemctl", "reboot"]);
        else if (action === "shutdown")
            Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggleOverlay("launcher"); }
        function close(): void { root.closeOverlay("launcher"); }
    }

    IpcHandler {
        target: "keybindings"
        function toggle(): void { root.toggleOverlay("keybindings"); }
        function close(): void { root.closeOverlay("keybindings"); }
    }

    IpcHandler {
        target: "notification-center"
        function toggle(): void { root.toggleOverlay("notifications"); }
        function close(): void { root.closeOverlay("notifications"); }
    }

    IpcHandler {
        target: "power-menu"
        function toggle(): void { root.toggleOverlay("power"); }
        function close(): void { root.closeOverlay("power"); }
    }

    NotificationServer {
        id: notificationService
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

    NotificationPopups {
        palette: appTheme.colors
        tokens: appTheme.design
        targetScreen: root.focusedScreen
        notifications: root.popupNotifications
        onNotificationActivated: notification => root.activateNotification(notification)
        onNotificationDismissed: notification => root.dismissNotification(notification)
        onPopupExpired: notification => {
            root.hideNotificationPopup(notification);
            if (notification.transient)
                notification.expire();
        }
    }

    PowerMenu {
        targetScreen: root.focusedScreen
        palette: appTheme.colors
        tokens: appTheme.design
        open: root.powerMenuOpen
        onDismissed: root.powerMenuOpen = false
        onActionRequested: action => root.runPowerAction(action)
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            targetScreen: modelData
            theme: appTheme
            systemState: stateModel
            notificationServer: notificationService
            launcherOpen: root.launcherOpen
            keybindingHelpOpen: root.keybindingHelpOpen
            notificationCenterOpen: root.notificationCenterOpen
            powerMenuOpen: root.powerMenuOpen
            stayAwake: root.stayAwake
            doNotDisturb: root.doNotDisturb
            focused: modelData === root.focusedScreen
            primaryForInhibitor: Quickshell.screens.length > 0
                && modelData === Quickshell.screens[0]
            onLauncherToggled: root.toggleOverlay("launcher")
            onKeybindingHelpToggled: root.toggleOverlay("keybindings")
            onNotificationCenterToggled: root.toggleOverlay("notifications")
            onPowerMenuToggled: root.toggleOverlay("power")
            onStayAwakeToggled: root.stayAwake = !root.stayAwake
            onDoNotDisturbToggled: root.doNotDisturb = !root.doNotDisturb
            onNotificationActivated: notification => root.activateNotification(notification)
            onNotificationDismissed: notification => root.dismissNotification(notification)
            onNotificationsClearRequested: root.clearNotificationHistory()
            onAdvancedBluetoothRequested:
                Quickshell.execDetached(["blueman-manager"])
            onAdvancedNetworkRequested:
                Quickshell.execDetached(["nm-connection-editor"])
        }
    }
}
