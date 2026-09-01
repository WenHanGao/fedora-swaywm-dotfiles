import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var anchorWindow
    required property var palette
    property bool open: false
    readonly property var categories: [
        {
            column: 0,
            title: "General",
            bindings: [
                ["Mod + Enter", "Open Foot terminal"],
                ["Mod + Space", "Toggle application launcher"],
                ["Mod + K", "Toggle this keybinding guide"],
                ["Mod + N", "Toggle notification center"],
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
        if (visible)
            Qt.callLater(() => keyboardHandler.forceActiveFocus());
        else if (open)
            dismissed();
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
            anchors.centerIn: parent
            width: Math.min(1080, parent.width - 48)
            height: Math.min(780, parent.height - 48)
            radius: 12
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
                    topMargin: 18
                    leftMargin: 22
                }
                text: "Keyboard shortcuts"
                color: root.palette.fg
                font.family: "Cascadia Mono NF"
                font.pixelSize: 20
                font.bold: true
            }

            Text {
                anchors {
                    right: parent.right
                    verticalCenter: title.verticalCenter
                    rightMargin: 22
                }
                text: "Mod+K or Esc to close"
                color: root.palette.grey1
                font.family: "Cascadia Mono NF"
                font.pixelSize: 12
            }

            Rectangle {
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

            Row {
                anchors {
                    top: title.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: 32
                    leftMargin: 26
                    rightMargin: 26
                    bottomMargin: 20
                }
                spacing: 44

                Repeater {
                    model: 2

                    Column {
                        required property int index
                        width: (parent.width - parent.spacing) / 2
                        spacing: 10

                        Repeater {
                            model: root.categories.filter(category => category.column === parent.index)

                            Column {
                                required property var modelData
                                width: parent.width
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: modelData.title
                                    color: root.palette.green
                                    font.family: "Cascadia Mono NF"
                                    font.pixelSize: 15
                                    font.bold: true
                                }

                                Repeater {
                                    model: modelData.bindings

                                    Row {
                                        required property var modelData
                                        width: parent.width
                                        height: 29
                                        spacing: 14

                                        Rectangle {
                                            width: 220
                                            height: 27
                                            radius: 5
                                            color: root.palette.bg0
                                            border.color: root.palette.bg3
                                            border.width: 1

                                            Text {
                                                anchors {
                                                    left: parent.left
                                                    verticalCenter: parent.verticalCenter
                                                    leftMargin: 10
                                                }
                                                text: modelData[0]
                                                color: root.palette.yellow
                                                font.family: "Cascadia Mono NF"
                                                font.pixelSize: 12
                                            }
                                        }

                                        Text {
                                            width: parent.width - 234
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData[1]
                                            color: root.palette.fg
                                            font.family: "Cascadia Mono NF"
                                            font.pixelSize: 12
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
