import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var anchorWindow
    required property var palette
    required property var tokens
    property bool open: false
    readonly property var categories: [
        {
            column: 0,
            title: "General",
            bindings: [
                ["Mod + Enter", "Open Foot terminal"],
                ["Mod + Shift + Enter", "Open Brave browser"],
                ["Mod + Alt + Enter", "Open Herdr in the home directory"],
                ["Mod + Space", "Toggle application launcher"],
                ["Mod + K", "Toggle this keybinding guide"],
                ["Mod + N", "Toggle notification center"],
                ["Mod + Escape", "Toggle power menu"],
                ["Mod + Shift + L", "Lock the session"],
                ["Mod + Shift + Q", "Close focused window"],
                ["Mod + Shift + C", "Reload Sway"],
                ["Mod + Shift + B", "Restart Quickshell"],
                ["Mod + Shift + E", "Show exit prompt"],
                ["Mod + drag", "Move a floating window"]
            ]
        },
        {
            column: 0,
            title: "Focus and movement",
            bindings: [
                ["Mod + Arrow keys", "Focus in a direction"],
                ["Mod + Shift + Arrows", "Move the focused window"],
                ["Mod + A", "Focus parent container"]
            ]
        },
        {
            column: 0,
            title: "Layout",
            bindings: [
                ["Mod + B / V", "Horizontal / vertical split"],
                ["Mod + W", "Tabbed layout"],
                ["Mod + E", "Toggle split direction"],
                ["Mod + F", "Toggle fullscreen"],
                ["Mod + T", "Toggle floating"],
                ["Mod + R", "Enter resize mode"]
            ]
        },
        {
            column: 1,
            title: "Workspaces",
            bindings: [
                ["Mod + 1…5", "Switch to workspace 1…5"],
                ["Mod + Shift + 1…5", "Move window to workspace 1…5"],
                ["Three-finger swipe left", "Next workspace"],
                ["Three-finger swipe right", "Previous workspace"]
            ]
        },
        {
            column: 1,
            title: "Scratchpad",
            bindings: [
                ["Mod + Minus", "Show a scratchpad window"],
                ["Mod + Shift + Minus", "Move window to scratchpad"]
            ]
        },
        {
            column: 1,
            title: "Resize mode",
            bindings: [
                ["Arrow keys", "Resize the focused window"],
                ["Enter / Escape", "Leave resize mode"]
            ]
        },
        {
            column: 1,
            title: "Hardware and media",
            bindings: [
                ["Volume Up / Down", "Adjust output volume"],
                ["Audio Mute", "Toggle output mute"],
                ["Microphone Mute", "Toggle microphone mute"],
                ["Brightness Up / Down", "Adjust display brightness"],
                ["Play / Pause / Stop", "Control media playback"],
                ["Next / Previous", "Change media track"],
                ["Forward / Rewind", "Seek ten seconds"]
            ]
        }
    ]
    readonly property var bindings: {
        const result = [];
        for (let categoryIndex = 0; categoryIndex < categories.length; ++categoryIndex) {
            const category = categories[categoryIndex];
            for (let bindingIndex = 0; bindingIndex < category.bindings.length; ++bindingIndex) {
                result.push({
                    category: category.title,
                    shortcut: category.bindings[bindingIndex][0],
                    description: category.bindings[bindingIndex][1]
                });
            }
        }
        return result;
    }
    readonly property var filteredBindings: {
        const query = searchInput.text.trim().toLowerCase();
        if (query === "")
            return bindings;
        return bindings.filter(binding =>
            binding.shortcut.toLowerCase().includes(query)
                || binding.description.toLowerCase().includes(query)
                || binding.category.toLowerCase().includes(query));
    }

    signal dismissed

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

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            Qt.callLater(() => searchInput.forceActiveFocus());
        } else if (open) {
            dismissed();
        }
    }

    function selectResult(index) {
        if (shortcutList.count === 0)
            return;
        shortcutList.currentIndex = Math.max(0,
            Math.min(shortcutList.count - 1, index));
        shortcutList.positionViewAtIndex(shortcutList.currentIndex,
            ListView.Contain);
    }

    FocusScope {
        id: keyboardHandler
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: event => {
            root.dismissed();
            event.accepted = true;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }

        Rectangle {
            id: guideCard
            anchors.centerIn: parent
            width: Math.min(900, parent.width - root.tokens.spaceXl * 2)
            height: Math.min(700, parent.height - root.tokens.spaceXl * 2)
            radius: root.tokens.radiusLg
            color: root.palette.bg2
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
                    topMargin: 18
                    leftMargin: 22
                }
                text: "Keyboard shortcuts"
                color: root.palette.fg
                font.family: root.tokens.uiFont
                font.pixelSize: 22
                font.bold: true
            }

            Text {
                anchors {
                    right: parent.right
                    verticalCenter: title.verticalCenter
                    rightMargin: 22
                }
                text: root.filteredBindings.length + " shortcuts · Esc to close"
                color: root.palette.grey1
                font.family: root.tokens.uiFont
                font.pixelSize: 13
            }

            Rectangle {
                id: titleDivider
                anchors {
                    top: title.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: 14
                    leftMargin: 18
                    rightMargin: 18
                }
                height: 1
                color: root.palette.bg3
            }

            Rectangle {
                id: searchBox
                anchors {
                    top: titleDivider.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: 14
                    leftMargin: 18
                    rightMargin: 18
                }
                height: 40
                radius: 7
                color: root.palette.bg0
                border.color: searchInput.activeFocus
                    ? root.palette.green : root.palette.bg3
                border.width: 1

                Text {
                    id: searchIcon
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 12
                    }
                    text: "󰍉"
                    color: root.palette.green
                    font.family: root.tokens.iconFont
                    font.pixelSize: 18
                }

                Text {
                    anchors {
                        left: searchIcon.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    visible: searchInput.text === ""
                    text: "Search shortcuts, actions, or categories…"
                    color: root.palette.grey1
                    font.family: root.tokens.uiFont
                    font.pixelSize: 14
                }

                TextInput {
                    id: searchInput
                    anchors {
                        left: searchIcon.right
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                        rightMargin: 12
                    }
                    color: root.palette.fg
                    selectionColor: root.palette.green
                    selectedTextColor: root.palette.bg0
                    font.family: root.tokens.uiFont
                    font.pixelSize: 14
                    clip: true

                    onTextChanged: shortcutList.currentIndex =
                        root.filteredBindings.length > 0 ? 0 : -1

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            root.selectResult(shortcutList.currentIndex + 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            root.selectResult(shortcutList.currentIndex - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageDown) {
                            root.selectResult(shortcutList.currentIndex
                                + Math.max(1, Math.floor(shortcutList.height / 56) - 1));
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            root.selectResult(shortcutList.currentIndex
                                - Math.max(1, Math.floor(shortcutList.height / 56) - 1));
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Home
                                && (event.modifiers & Qt.ControlModifier)) {
                            root.selectResult(0);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_End
                                && (event.modifiers & Qt.ControlModifier)) {
                            root.selectResult(shortcutList.count - 1);
                            event.accepted = true;
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: shortcutList
                visible: root.filteredBindings.length === 0
                text: "No matching shortcuts"
                color: root.palette.grey1
                font.family: root.tokens.uiFont
                font.pixelSize: 15
            }

            ListView {
                id: shortcutList
                anchors {
                    top: searchBox.bottom
                    left: parent.left
                    right: scrollBar.left
                    bottom: parent.bottom
                    topMargin: 14
                    leftMargin: 18
                    rightMargin: 8
                    bottomMargin: 18
                }
                clip: true
                spacing: 4
                model: root.filteredBindings
                currentIndex: count > 0 ? 0 : -1

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: shortcutList.width
                    height: 52
                    radius: 6
                    color: ListView.isCurrentItem
                        ? root.palette.bg3 : index % 2 === 0
                            ? root.palette.bg0 : "transparent"
                    border.color: ListView.isCurrentItem
                        ? root.palette.green : "transparent"
                    border.width: 1

                    Row {
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        spacing: 14

                        Text {
                            width: 150
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.category
                            color: root.palette.aqua
                            font.family: root.tokens.uiFont
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Text {
                            width: 245
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.shortcut
                            color: root.palette.yellow
                            font.family: root.tokens.uiFont
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width - 437
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.description
                            color: root.palette.fg
                            font.family: root.tokens.uiFont
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            shortcutList.currentIndex = index;
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }

            Item {
                id: scrollBar
                anchors {
                    top: shortcutList.top
                    right: parent.right
                    bottom: shortcutList.bottom
                    rightMargin: 18
                }
                width: 5
                visible: shortcutList.contentHeight > shortcutList.height

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.palette.bg3
                }

                Rectangle {
                    y: shortcutList.visibleArea.yPosition * parent.height
                    width: parent.width
                    height: Math.max(24,
                        shortcutList.visibleArea.heightRatio * parent.height)
                    radius: width / 2
                    color: root.palette.green
                }
            }
        }
    }
}
