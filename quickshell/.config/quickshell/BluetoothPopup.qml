import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var anchorWindow
    required property var palette
    required property var tokens
    property var adapter: null
    property bool open: false
    property var selectedDevice: null
    property string statusMessage: ""
    readonly property var devices: adapter
        ? adapter.devices.values.slice().sort((left, right) => {
            if (left.connected !== right.connected)
                return left.connected ? -1 : 1;
            if (left.paired !== right.paired)
                return left.paired ? -1 : 1;
            return left.name.localeCompare(right.name);
        }) : []
    readonly property var filteredDevices: {
        const query = searchInput.text.trim().toLowerCase();
        return query === "" ? devices : devices.filter(device =>
            device.name.toLowerCase().includes(query));
    }
    readonly property var connectedDevices:
        devices.filter(device => device.connected)
    readonly property string connectionSummary: {
        if (!adapter || !adapter.enabled)
            return "Bluetooth is off";
        if (connectedDevices.length === 0)
            return "Not connected";
        if (connectedDevices.length === 1)
            return "Connected to " + connectedDevices[0].name;
        return connectedDevices.length + " devices connected";
    }

    signal dismissed
    signal advancedSetupRequested

    visible: open
    screen: anchorWindow.screen
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function actionLabel(device) {
        if (device.pairing)
            return "Cancel";
        if (device.connected)
            return "Disconnect";
        return device.paired ? "Connect" : "Pair";
    }

    function deviceDetails(device) {
        const details = [];
        if (device.connected)
            details.push("Connected");
        else if (device.pairing)
            details.push("Pairing");
        else if (device.paired)
            details.push("Paired");
        else
            details.push("Available");
        if (device.batteryAvailable)
            details.push("Battery " + Math.round(device.battery * 100) + "%");
        return details.join(" · ");
    }

    function operateDevice(device) {
        if (!device || !adapter || !adapter.enabled)
            return;
        selectedDevice = device;
        if (device.pairing) {
            device.cancelPair();
            statusMessage = "Pairing cancelled";
        } else if (device.connected) {
            device.disconnect();
            statusMessage = "Disconnecting from " + device.name + "…";
        } else if (device.paired) {
            device.connect();
            statusMessage = "Connecting to " + device.name + "…";
        } else {
            device.pair();
            statusMessage = "Pairing with " + device.name + "…";
        }
    }

    function updateDiscovery() {
        if (adapter)
            adapter.discovering = visible && adapter.enabled;
    }

    onVisibleChanged: {
        updateDiscovery();
        if (visible) {
            selectedDevice = null;
            statusMessage = "";
            searchInput.text = "";
            deviceList.currentIndex = 0;
            Qt.callLater(() => searchInput.forceActiveFocus());
        } else {
            dismissed();
        }
    }

    onAdapterChanged: updateDiscovery()

    Connections {
        target: root.adapter

        function onEnabledChanged() {
            root.updateDiscovery();
            root.statusMessage = root.adapter && root.adapter.enabled
                ? "Bluetooth enabled" : "Bluetooth disabled";
        }
    }

    Connections {
        target: root.selectedDevice

        function onPairedChanged() {
            if (root.selectedDevice && root.selectedDevice.paired
                    && !root.selectedDevice.connected) {
                root.statusMessage = "Paired with " + root.selectedDevice.name
                    + "; connecting…";
                root.selectedDevice.connect();
            }
        }

        function onConnectedChanged() {
            if (!root.selectedDevice)
                return;
            root.statusMessage = root.selectedDevice.connected
                ? "Connected to " + root.selectedDevice.name
                : "Disconnected from " + root.selectedDevice.name;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        id: card
        anchors {
            top: parent.top
            right: parent.right
            topMargin: root.anchorWindow.height + root.tokens.popupMargin
            rightMargin: root.tokens.spaceXs
        }
        width: Math.min(410, root.width - root.tokens.spaceXl)
        height: Math.min(500, root.height - y - root.tokens.spaceMd)
        radius: root.tokens.radiusLg
        color: root.palette.bg2
        border.color: root.palette.bg3
        border.width: 1

        MouseArea { anchors.fill: parent }

        Text {
            id: title
            anchors {
                top: parent.top
                left: parent.left
                topMargin: root.tokens.spaceLg
                leftMargin: root.tokens.spaceLg
            }
            text: "Bluetooth"
            color: root.palette.fg
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textLg
            font.bold: true
        }

        Rectangle {
            id: powerButton
            anchors {
                right: advancedButton.left
                verticalCenter: title.verticalCenter
                rightMargin: root.tokens.spaceXs
            }
            width: powerLabel.implicitWidth + root.tokens.spaceLg
            height: root.tokens.controlHeight
            radius: root.tokens.radiusSm
            color: root.adapter && root.adapter.enabled
                ? root.palette.green
                : powerMouse.containsMouse ? root.palette.bg3 : "transparent"
            border.color: root.adapter && root.adapter.enabled
                ? root.palette.green : root.palette.bg3
            border.width: 1

            Text {
                id: powerLabel
                anchors.centerIn: parent
                text: root.adapter && root.adapter.enabled ? "On" : "Off"
                color: root.adapter && root.adapter.enabled
                    ? root.palette.bg0 : root.palette.grey1
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textSm
                font.bold: root.adapter && root.adapter.enabled
            }

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                enabled: root.adapter !== null
                hoverEnabled: enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.adapter.enabled = !root.adapter.enabled
            }
        }

        Rectangle {
            id: advancedButton
            anchors {
                right: parent.right
                verticalCenter: title.verticalCenter
                rightMargin: root.tokens.spaceMd
            }
            width: advancedLabel.implicitWidth + root.tokens.spaceLg
            height: root.tokens.controlHeight
            radius: root.tokens.radiusSm
            color: advancedMouse.containsMouse ? root.palette.bg3 : "transparent"

            Text {
                id: advancedLabel
                anchors.centerIn: parent
                text: "Advanced"
                color: root.palette.aqua
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textSm
            }

            MouseArea {
                id: advancedMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.advancedSetupRequested()
            }
        }

        Text {
            id: currentLabel
            anchors {
                top: title.bottom
                left: title.left
                right: parent.right
                topMargin: root.tokens.spaceXs
                rightMargin: root.tokens.spaceLg
            }
            text: root.connectionSummary
            color: root.connectedDevices.length > 0
                ? root.palette.green : root.palette.grey1
            elide: Text.ElideRight
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textSm
        }

        Rectangle {
            id: searchBox
            anchors {
                top: currentLabel.bottom
                left: parent.left
                right: parent.right
                topMargin: root.tokens.spaceMd
                leftMargin: root.tokens.spaceMd
                rightMargin: root.tokens.spaceMd
            }
            height: 38
            radius: root.tokens.radiusMd
            color: root.palette.bg0
            border.color: searchInput.activeFocus
                ? root.palette.green : root.palette.bg3
            border.width: 1
            opacity: root.adapter && root.adapter.enabled ? 1 : 0.55

            TextInput {
                id: searchInput
                anchors {
                    fill: parent
                    leftMargin: root.tokens.spaceMd
                    rightMargin: root.tokens.spaceMd
                }
                enabled: root.adapter && root.adapter.enabled
                verticalAlignment: TextInput.AlignVCenter
                color: root.palette.fg
                selectionColor: root.palette.green
                selectedTextColor: root.palette.bg0
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textMd
                clip: true

                Text {
                    anchors.fill: parent
                    visible: parent.text === ""
                    verticalAlignment: Text.AlignVCenter
                    text: root.adapter && root.adapter.enabled
                        ? "Search devices" : "Turn on Bluetooth to search"
                    color: root.palette.grey1
                    font: parent.font
                }

                onTextChanged: deviceList.currentIndex = 0
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.dismissed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        deviceList.currentIndex = Math.min(deviceList.count - 1,
                            deviceList.currentIndex + 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        deviceList.currentIndex = Math.max(0,
                            deviceList.currentIndex - 1);
                        event.accepted = true;
                    } else if ((event.key === Qt.Key_Return
                            || event.key === Qt.Key_Enter)
                            && deviceList.currentIndex >= 0) {
                        root.operateDevice(
                            root.filteredDevices[deviceList.currentIndex]);
                        event.accepted = true;
                    }
                }
            }
        }

        Text {
            id: status
            anchors {
                top: searchBox.bottom
                left: searchBox.left
                right: searchBox.right
                topMargin: root.tokens.spaceSm
            }
            visible: text !== ""
            text: root.statusMessage
            color: root.palette.grey2
            elide: Text.ElideRight
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textSm
        }

        ListView {
            id: deviceList
            anchors {
                top: status.visible ? status.bottom : searchBox.bottom
                left: searchBox.left
                right: searchBox.right
                bottom: parent.bottom
                topMargin: root.tokens.spaceSm
                bottomMargin: root.tokens.spaceMd
            }
            clip: true
            spacing: root.tokens.spaceXs
            model: root.filteredDevices
            currentIndex: 0

            delegate: Rectangle {
                id: deviceRow
                required property var modelData
                required property int index
                width: deviceList.width
                height: 54
                radius: root.tokens.radiusMd
                color: ListView.isCurrentItem || modelData.connected
                    ? root.palette.bg_green
                    : rowMouse.containsMouse ? root.palette.bg3 : "transparent"
                border.color: ListView.isCurrentItem
                    ? root.palette.green : "transparent"
                border.width: 1

                Text {
                    id: deviceGlyph
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: root.tokens.spaceMd
                    }
                    text: modelData.connected ? "󰂱" : "󰂯"
                    color: modelData.connected
                        ? root.palette.green : root.palette.aqua
                    font.family: root.tokens.iconFont
                    font.pixelSize: 18
                }

                Column {
                    anchors {
                        left: deviceGlyph.right
                        right: actionButton.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: root.tokens.spaceMd
                        rightMargin: root.tokens.spaceSm
                    }
                    spacing: 2

                    Text {
                        width: parent.width
                        text: modelData.name
                        color: root.palette.fg
                        elide: Text.ElideRight
                        font.family: root.tokens.uiFont
                        font.pixelSize: root.tokens.textMd
                        font.bold: modelData.connected
                    }

                    Text {
                        width: parent.width
                        text: root.deviceDetails(modelData)
                        color: root.palette.grey2
                        elide: Text.ElideRight
                        font.family: root.tokens.uiFont
                        font.pixelSize: root.tokens.textXs
                    }
                }

                Rectangle {
                    id: actionButton
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: root.tokens.spaceSm
                    }
                    width: 82
                    height: 32
                    radius: root.tokens.radiusSm
                    color: actionMouse.containsMouse
                        ? root.palette.green : root.palette.bg3

                    Text {
                        anchors.centerIn: parent
                        text: root.actionLabel(modelData)
                        color: actionMouse.containsMouse
                            ? root.palette.bg0 : root.palette.fg
                        font.family: root.tokens.uiFont
                        font.pixelSize: root.tokens.textXs
                        font.bold: actionMouse.containsMouse
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        enabled: root.adapter && root.adapter.enabled
                        hoverEnabled: enabled
                        cursorShape: enabled
                            ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.operateDevice(modelData)
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                        left: parent.left
                        right: actionButton.left
                    }
                    enabled: root.adapter && root.adapter.enabled
                    hoverEnabled: enabled
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onEntered: deviceList.currentIndex = deviceRow.index
                    onClicked: root.operateDevice(modelData)
                }
            }
        }

        Text {
            anchors.centerIn: deviceList
            visible: deviceList.count === 0
            text: !root.adapter ? "No Bluetooth adapter"
                : !root.adapter.enabled ? "Bluetooth is turned off"
                : root.adapter.discovering ? "Searching for devices…"
                : "No devices found"
            color: root.palette.grey1
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textMd
        }
    }
}
