import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var anchorWindow
    required property var palette
    property bool open: false
    property string currentNetwork: "Disconnected"
    property var networks: []
    property string selectedSsid: ""
    property string selectedSecurity: ""
    property string statusMessage: ""
    readonly property bool selectedSecured: selectedSsid !== ""
        && selectedSecurity !== "" && selectedSecurity !== "--"
    readonly property var filteredNetworks: {
        const query = searchInput.text.trim().toLowerCase();
        if (query === "")
            return networks;
        return networks.filter(network =>
            network.ssid.toLowerCase().includes(query)
                || network.security.toLowerCase().includes(query));
    }

    signal dismissed
    signal refreshRequested
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

    function splitNmcliLine(line) {
        const fields = [];
        let field = "";
        let escaped = false;
        for (let index = 0; index < line.length; ++index) {
            const character = line[index];
            if (escaped) {
                field += character;
                escaped = false;
            } else if (character === "\\") {
                escaped = true;
            } else if (character === ":") {
                fields.push(field);
                field = "";
            } else {
                field += character;
            }
        }
        fields.push(field);
        return fields;
    }

    function parseNetworks(text) {
        const strongestBySsid = {};
        const lines = text.trim().split("\n");
        for (let index = 0; index < lines.length; ++index) {
            if (lines[index] === "")
                continue;
            const fields = splitNmcliLine(lines[index]);
            if (fields.length < 4 || fields[1] === "")
                continue;
            const network = {
                active: fields[0] === "*",
                ssid: fields[1],
                signal: Number(fields[2]) || 0,
                security: fields.slice(3).join(":") || "--"
            };
            const existing = strongestBySsid[network.ssid];
            if (!existing || network.active || network.signal > existing.signal)
                strongestBySsid[network.ssid] = network;
        }
        const result = Object.keys(strongestBySsid).map(ssid => strongestBySsid[ssid]);
        result.sort((left, right) => left.active !== right.active
            ? (left.active ? -1 : 1) : right.signal - left.signal);
        networks = result;
    }

    function signalIcon(signal) {
        if (signal >= 75)
            return "󰤨";
        if (signal >= 50)
            return "󰤥";
        if (signal >= 25)
            return "󰤢";
        return "󰤟";
    }

    function refresh() {
        if (!scanProcess.running) {
            statusMessage = "Scanning…";
            scanProcess.running = true;
        }
    }

    function chooseNetwork(network) {
        wifiList.currentIndex = filteredNetworks.indexOf(network);
        if (network.active) {
            selectedSsid = "";
            selectedSecurity = "";
            statusMessage = "Already connected";
            return;
        }
        selectedSsid = network.ssid;
        selectedSecurity = network.security;
        passwordInput.text = "";
        statusMessage = "";
        if (selectedSecured)
            Qt.callLater(() => passwordInput.forceActiveFocus());
        else
            connectToSelected();
    }

    function connectToSelected() {
        if (selectedSsid === "" || connectProcess.running)
            return;
        const command = ["nmcli", "--wait", "20", "device", "wifi",
            "connect", selectedSsid];
        if (passwordInput.text !== "")
            command.push("password", passwordInput.text);
        statusMessage = "Connecting to " + selectedSsid + "…";
        connectProcess.command = command;
        connectProcess.running = true;
    }

    onVisibleChanged: {
        if (visible) {
            selectedSsid = "";
            selectedSecurity = "";
            searchInput.text = "";
            refresh();
            Qt.callLater(() => searchInput.forceActiveFocus());
        } else {
            passwordInput.text = "";
            root.dismissed();
        }
    }

    Process {
        id: scanProcess
        command: ["nmcli", "--terse", "--escape", "yes", "--fields",
            "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list",
            "--rescan", "yes"]
        stdout: StdioCollector {
            onStreamFinished: root.parseNetworks(text)
        }
        onExited: exitCode => {
            if (exitCode === 0)
                root.statusMessage = "";
            else
                root.statusMessage = "Unable to scan for Wi-Fi networks";
        }
    }

    Process {
        id: connectProcess
        stdout: StdioCollector { id: connectionOutput }
        stderr: StdioCollector { id: connectionError }
        onExited: exitCode => {
            if (exitCode === 0) {
                root.statusMessage = "Connected to " + root.selectedSsid;
                root.selectedSsid = "";
                root.selectedSecurity = "";
                passwordInput.text = "";
                root.refreshRequested();
                refreshTimer.restart();
            } else {
                const message = connectionError.text.trim()
                    || connectionOutput.text.trim() || "Connection failed";
                root.statusMessage = message.replace(/^Error:\s*/, "");
                if (root.selectedSecured)
                    Qt.callLater(() => passwordInput.forceActiveFocus());
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 1000
        onTriggered: root.refresh()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        anchors {
            top: parent.top
            right: parent.right
            topMargin: root.anchorWindow.height + 8
            rightMargin: 1
        }
        width: 390
        height: 430
        radius: 10
        color: root.palette.bg1
        border.color: root.palette.bg3
        border.width: 1

        MouseArea {
            anchors.fill: parent
        }

        Text {
            id: title
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 14
                leftMargin: 16
            }
            text: "Wi-Fi"
            color: root.palette.fg
            font.family: "Cascadia Mono NF"
            font.pixelSize: 15
            font.bold: true
        }

        Rectangle {
            id: refreshButton
            anchors {
                right: parent.right
                verticalCenter: title.verticalCenter
                rightMargin: 12
            }
            width: 30
            height: 28
            radius: 5
            color: refreshMouse.containsMouse ? root.palette.bg3 : "transparent"

            Text {
                anchors.centerIn: parent
                text: scanProcess.running ? "󰑓" : "󰑐"
                color: root.palette.aqua
                font.family: "Cascadia Mono NF"
                font.pixelSize: 16
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                enabled: !scanProcess.running
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.refresh()
            }
        }

        Rectangle {
            anchors {
                right: refreshButton.left
                verticalCenter: title.verticalCenter
                rightMargin: 6
            }
            width: 104
            height: 28
            radius: 5
            color: advancedMouse.containsMouse ? root.palette.bg3 : "transparent"

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "󰒓"
                    color: root.palette.aqua
                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 15
                }

                Text {
                    text: "Advanced"
                    color: root.palette.fg
                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 10
                }
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
                left: parent.left
                right: parent.right
                topMargin: 4
                leftMargin: 16
                rightMargin: 16
            }
            text: root.currentNetwork === "Disconnected"
                ? "Not connected" : "Connected · " + root.currentNetwork
            color: root.currentNetwork === "Disconnected"
                ? root.palette.grey1 : root.palette.green
            font.family: "Cascadia Mono NF"
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Rectangle {
            id: searchBox
            anchors {
                top: currentLabel.bottom
                left: parent.left
                right: parent.right
                topMargin: 10
                leftMargin: 12
                rightMargin: 12
            }
            height: 38
            radius: 6
            color: root.palette.bg0
            border.color: searchInput.activeFocus
                ? root.palette.green : root.palette.bg3
            border.width: 1

            Text {
                id: searchIcon
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                }
                text: "󰍉"
                color: root.palette.green
                font.family: "Cascadia Mono NF"
                font.pixelSize: 15
            }

            Text {
                anchors {
                    left: searchIcon.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 8
                }
                visible: searchInput.text === ""
                text: "Search networks…"
                color: root.palette.grey1
                font.family: "Cascadia Mono NF"
                font.pixelSize: 12
            }

            TextInput {
                id: searchInput
                anchors {
                    left: searchIcon.right
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 8
                    rightMargin: 10
                }
                color: root.palette.fg
                selectionColor: root.palette.green
                selectedTextColor: root.palette.bg0
                font.family: "Cascadia Mono NF"
                font.pixelSize: 12
                clip: true

                onTextChanged: wifiList.currentIndex =
                    root.filteredNetworks.length > 0 ? 0 : -1

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.dismissed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down && wifiList.count > 0) {
                        wifiList.currentIndex = Math.min(wifiList.count - 1,
                            wifiList.currentIndex + 1);
                        wifiList.positionViewAtIndex(wifiList.currentIndex, ListView.Contain);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up && wifiList.count > 0) {
                        wifiList.currentIndex = Math.max(0, wifiList.currentIndex - 1);
                        wifiList.positionViewAtIndex(wifiList.currentIndex, ListView.Contain);
                        event.accepted = true;
                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            && wifiList.currentIndex >= 0) {
                        root.chooseNetwork(root.filteredNetworks[wifiList.currentIndex]);
                        event.accepted = true;
                    }
                }
            }
        }

        Item {
            id: authPanel
            anchors {
                left: parent.left
                right: parent.right
                bottom: statusLabel.top
                leftMargin: 12
                rightMargin: 12
                bottomMargin: 8
            }
            visible: root.selectedSecured
            height: visible ? 42 : 0

            Rectangle {
                anchors {
                    left: parent.left
                    right: connectButton.left
                    top: parent.top
                    bottom: parent.bottom
                    rightMargin: 8
                }
                radius: 6
                color: root.palette.bg0
                border.color: passwordInput.activeFocus
                    ? root.palette.green : root.palette.bg3
                border.width: 1

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    visible: passwordInput.text === ""
                    text: "Password (blank uses saved profile)"
                    color: root.palette.grey1
                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 10
                }

                TextInput {
                    id: passwordInput
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: root.palette.fg
                    selectionColor: root.palette.green
                    selectedTextColor: root.palette.bg0
                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 12
                    clip: true
                    onAccepted: root.connectToSelected()
                    Keys.onEscapePressed: event => {
                        root.selectedSsid = "";
                        root.selectedSecurity = "";
                        searchInput.forceActiveFocus();
                        event.accepted = true;
                    }
                }
            }

            Rectangle {
                id: connectButton
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                }
                width: 86
                radius: 6
                color: connectMouse.containsMouse
                    ? root.palette.green : root.palette.bg3

                Text {
                    anchors.centerIn: parent
                    text: connectProcess.running ? "Connecting" : "Connect"
                    color: connectMouse.containsMouse
                        ? root.palette.bg0 : root.palette.fg
                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    id: connectMouse
                    anchors.fill: parent
                    enabled: !connectProcess.running
                    hoverEnabled: enabled
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.connectToSelected()
                }
            }
        }

        Text {
            id: statusLabel
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 16
                rightMargin: 16
                bottomMargin: 10
            }
            height: 18
            text: root.statusMessage
            color: root.palette.grey1
            font.family: "Cascadia Mono NF"
            font.pixelSize: 10
            elide: Text.ElideRight
        }

        Text {
            anchors.centerIn: wifiList
            visible: !scanProcess.running && root.filteredNetworks.length === 0
            text: searchInput.text === "" ? "No Wi-Fi networks found" : "No matching networks"
            color: root.palette.grey1
            font.family: "Cascadia Mono NF"
            font.pixelSize: 12
        }

        ListView {
            id: wifiList
            anchors {
                top: searchBox.bottom
                left: parent.left
                right: parent.right
                bottom: authPanel.visible ? authPanel.top : statusLabel.top
                topMargin: 10
                leftMargin: 12
                rightMargin: 12
                bottomMargin: 8
            }
            visible: root.filteredNetworks.length > 0
            clip: true
            spacing: 3
            model: root.filteredNetworks
            currentIndex: count > 0 ? 0 : -1

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: wifiList.width
                height: 48
                radius: 6
                color: modelData.active ? root.palette.green
                    : ListView.isCurrentItem ? root.palette.bg3 : "transparent"

                Text {
                    id: wifiIcon
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    text: root.signalIcon(modelData.signal)
                    color: modelData.active ? root.palette.bg0 : root.palette.aqua
                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 17
                }

                Column {
                    anchors {
                        left: wifiIcon.right
                        right: signalLabel.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                        rightMargin: 8
                    }
                    spacing: 2

                    Text {
                        width: parent.width
                        text: modelData.ssid
                        color: modelData.active ? root.palette.bg0 : root.palette.fg
                        font.family: "Cascadia Mono NF"
                        font.pixelSize: 12
                        font.bold: modelData.active
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: modelData.security === "--" ? "Open" : modelData.security
                        color: modelData.active ? root.palette.bg0 : root.palette.grey1
                        font.family: "Cascadia Mono NF"
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: signalLabel
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 10
                    }
                    text: modelData.signal + "%"
                    color: modelData.active ? root.palette.bg0 : root.palette.grey1
                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 10
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.chooseNetwork(modelData)
                }
            }
        }
    }
}
