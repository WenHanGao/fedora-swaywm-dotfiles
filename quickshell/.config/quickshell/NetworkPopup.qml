import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var anchorWindow
    required property var palette
    required property var tokens
    property var wifiDevice: null
    property bool open: false
    property var selectedNetwork: null
    property string statusMessage: ""
    readonly property var networks: wifiDevice
        ? wifiDevice.networks.values.slice().sort((left, right) =>
            left.connected !== right.connected ? (left.connected ? -1 : 1)
                : right.signalStrength - left.signalStrength) : []
    readonly property var filteredNetworks: {
        const query = searchInput.text.trim().toLowerCase();
        return query === "" ? networks : networks.filter(network =>
            network.name.toLowerCase().includes(query));
    }
    readonly property string currentNetwork: {
        const connected = networks.find(network => network.connected);
        return connected ? connected.name : "Disconnected";
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

    function securityLabel(network) {
        if (!network)
            return "";
        return WifiSecurityType.toString(network.security)
            .replace(/([a-z])([A-Z])/g, "$1 $2");
    }

    function signalIcon(signal) {
        if (signal >= 0.75)
            return "󰤨";
        if (signal >= 0.5)
            return "󰤥";
        if (signal >= 0.25)
            return "󰤢";
        return "󰤟";
    }

    function supportsPsk(network) {
        return network && (network.security === WifiSecurityType.WpaPsk
            || network.security === WifiSecurityType.Wpa2Psk
            || network.security === WifiSecurityType.Sae);
    }

    function chooseNetwork(network) {
        if (!network)
            return;
        selectedNetwork = network;
        passwordInput.text = "";
        statusMessage = network.connected ? "Already connected" : "";
        if (network.connected)
            return;
        if (network.known || network.security === WifiSecurityType.Open) {
            network.connect();
            statusMessage = "Connecting to " + network.name + "…";
        } else if (supportsPsk(network)) {
            Qt.callLater(() => passwordInput.forceActiveFocus());
        } else {
            statusMessage = "Use Advanced for enterprise or certificate-based networks";
        }
    }

    function connectSelected() {
        if (!selectedNetwork || selectedNetwork.stateChanging)
            return;
        statusMessage = "Connecting to " + selectedNetwork.name + "…";
        if (selectedNetwork.known || selectedNetwork.security === WifiSecurityType.Open)
            selectedNetwork.connect();
        else if (supportsPsk(selectedNetwork))
            selectedNetwork.connectWithPsk(passwordInput.text);
    }

    onVisibleChanged: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = visible;
        if (visible) {
            selectedNetwork = null;
            statusMessage = "";
            searchInput.text = "";
            networkList.currentIndex = 0;
            Qt.callLater(() => searchInput.forceActiveFocus());
        } else {
            passwordInput.text = "";
            dismissed();
        }
    }

    Connections {
        target: root.selectedNetwork

        function onConnectedChanged() {
            if (root.selectedNetwork && root.selectedNetwork.connected) {
                root.statusMessage = "Connected to " + root.selectedNetwork.name;
                passwordInput.text = "";
            }
        }

        function onConnectionFailed(reason) {
            root.statusMessage = "Connection failed: "
                + ConnectionFailReason.toString(reason);
            Qt.callLater(() => passwordInput.forceActiveFocus());
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
            text: "Wi-Fi"
            color: root.palette.fg
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textLg
            font.bold: true
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
            text: root.currentNetwork === "Disconnected"
                ? "Not connected" : "Connected to " + root.currentNetwork
            color: root.currentNetwork === "Disconnected"
                ? root.palette.grey1 : root.palette.green
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
            border.color: searchInput.activeFocus ? root.palette.green : root.palette.bg3
            border.width: 1

            TextInput {
                id: searchInput
                anchors {
                    fill: parent
                    leftMargin: root.tokens.spaceMd
                    rightMargin: root.tokens.spaceMd
                }
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
                    text: "Search networks"
                    color: root.palette.grey1
                    font: parent.font
                }

                onTextChanged: networkList.currentIndex = 0
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.dismissed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        networkList.currentIndex = Math.min(networkList.count - 1,
                            networkList.currentIndex + 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        networkList.currentIndex = Math.max(0,
                            networkList.currentIndex - 1);
                        event.accepted = true;
                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            && networkList.currentIndex >= 0) {
                        root.chooseNetwork(root.filteredNetworks[networkList.currentIndex]);
                        event.accepted = true;
                    }
                }
            }
        }

        Column {
            id: credentials
            anchors {
                top: searchBox.bottom
                left: searchBox.left
                right: searchBox.right
                topMargin: root.tokens.spaceSm
            }
            visible: root.selectedNetwork && !root.selectedNetwork.connected
                && root.supportsPsk(root.selectedNetwork) && !root.selectedNetwork.known
            spacing: root.tokens.spaceSm

            Text {
                width: parent.width
                text: "Password for " + (root.selectedNetwork ? root.selectedNetwork.name : "")
                color: root.palette.fg
                elide: Text.ElideRight
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textSm
            }

            Row {
                width: parent.width
                spacing: root.tokens.spaceSm

                Rectangle {
                    width: parent.width - connectButton.width - parent.spacing
                    height: 36
                    radius: root.tokens.radiusMd
                    color: root.palette.bg0
                    border.color: passwordInput.activeFocus
                        ? root.palette.green : root.palette.bg3
                    border.width: 1

                    TextInput {
                        id: passwordInput
                        anchors {
                            fill: parent
                            leftMargin: root.tokens.spaceMd
                            rightMargin: root.tokens.spaceMd
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: root.palette.fg
                        selectionColor: root.palette.green
                        selectedTextColor: root.palette.bg0
                        font.family: root.tokens.uiFont
                        font.pixelSize: root.tokens.textMd
                        Keys.onReturnPressed: root.connectSelected()
                        Keys.onEnterPressed: root.connectSelected()
                        Keys.onEscapePressed: root.dismissed()
                    }
                }

                Rectangle {
                    id: connectButton
                    width: 88
                    height: 36
                    radius: root.tokens.radiusMd
                    color: connectMouse.containsMouse
                        ? root.palette.green : root.palette.bg3

                    Text {
                        anchors.centerIn: parent
                        text: root.selectedNetwork && root.selectedNetwork.stateChanging
                            ? "Working…" : "Connect"
                        color: connectMouse.containsMouse ? root.palette.bg0 : root.palette.fg
                        font.family: root.tokens.uiFont
                        font.pixelSize: root.tokens.textSm
                        font.bold: connectMouse.containsMouse
                    }

                    MouseArea {
                        id: connectMouse
                        anchors.fill: parent
                        enabled: root.selectedNetwork && !root.selectedNetwork.stateChanging
                        hoverEnabled: enabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.connectSelected()
                    }
                }
            }
        }

        Text {
            id: status
            anchors {
                top: credentials.visible ? credentials.bottom : searchBox.bottom
                left: searchBox.left
                right: searchBox.right
                topMargin: root.tokens.spaceSm
            }
            visible: text !== ""
            text: root.statusMessage
            color: text.startsWith("Connection failed")
                ? root.palette.red : root.palette.grey2
            elide: Text.ElideRight
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textSm
        }

        ListView {
            id: networkList
            anchors {
                top: status.visible ? status.bottom
                    : credentials.visible ? credentials.bottom : searchBox.bottom
                left: searchBox.left
                right: searchBox.right
                bottom: parent.bottom
                topMargin: root.tokens.spaceSm
                bottomMargin: root.tokens.spaceMd
            }
            clip: true
            spacing: root.tokens.spaceXs
            model: root.filteredNetworks
            currentIndex: 0

            delegate: Rectangle {
                id: networkRow
                required property var modelData
                required property int index
                width: networkList.width
                height: 46
                radius: root.tokens.radiusMd
                color: ListView.isCurrentItem || modelData.connected
                    ? root.palette.bg_green
                    : rowMouse.containsMouse ? root.palette.bg3 : "transparent"
                border.color: ListView.isCurrentItem ? root.palette.green : "transparent"
                border.width: 1

                Text {
                    id: signalGlyph
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: root.tokens.spaceMd
                    }
                    text: root.signalIcon(modelData.signalStrength)
                    color: modelData.connected ? root.palette.green : root.palette.aqua
                    font.family: root.tokens.iconFont
                    font.pixelSize: 18
                }

                Column {
                    anchors {
                        left: signalGlyph.right
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: root.tokens.spaceMd
                        rightMargin: root.tokens.spaceMd
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
                        text: (modelData.connected ? "Connected · " : "")
                            + root.securityLabel(modelData)
                        color: root.palette.grey2
                        elide: Text.ElideRight
                        font.family: root.tokens.uiFont
                        font.pixelSize: root.tokens.textXs
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: networkList.currentIndex = networkRow.index
                    onClicked: root.chooseNetwork(modelData)
                }
            }
        }

        Text {
            anchors.centerIn: networkList
            visible: networkList.count === 0
            text: root.wifiDevice ? "No networks found" : "No Wi-Fi adapter"
            color: root.palette.grey1
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textMd
        }
    }
}
