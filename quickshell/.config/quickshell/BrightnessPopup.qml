import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorWindow
    required property var palette
    required property var tokens
    property bool open: false
    property int brightness: 0
    property var displays: []
    property string selectedDisplayName: ""
    readonly property var selectedDisplay: displays.find(display =>
        display.name === selectedDisplayName) || null
    readonly property var scaleOptions: [0.8, 0.9, 1.0, 1.1, 1.2]
    readonly property int displayListHeight: Math.min(128,
        Math.max(32, displays.length * 32))

    signal dismissed
    signal brightnessRequested(int value)
    signal scaleRequested(string displayName, real scale)

    visible: open
    grabFocus: true
    implicitWidth: Math.min(370, anchorWindow.width - tokens.spaceXl)
    implicitHeight: 189 + displayListHeight
    color: "transparent"

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow.width - width - 1
    anchor.rect.y: anchorWindow.height + tokens.popupMargin

    function ensureSelectedDisplay() {
        if (displays.length === 0) {
            selectedDisplayName = "";
            return;
        }
        if (displays.some(display => display.name === selectedDisplayName))
            return;
        const focusedDisplay = displays.find(display => display.focused);
        selectedDisplayName = focusedDisplay ? focusedDisplay.name : displays[0].name;
    }

    onDisplaysChanged: ensureSelectedDisplay()
    onOpenChanged: {
        if (open)
            ensureSelectedDisplay();
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => brightnessControl.forceActiveFocus());
        else
            root.dismissed();
    }

    Rectangle {
        anchors.fill: parent
        focus: true
        radius: root.tokens.radiusLg
        color: root.palette.bg2
        border.color: root.palette.bg3
        border.width: 1

        Keys.onEscapePressed: root.dismissed()

        Column {
            anchors {
                fill: parent
                margins: root.tokens.spaceLg
            }
            spacing: root.tokens.spaceSm

            Text {
                text: "Brightness"
                color: root.palette.fg
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textLg
                font.bold: true
            }

            BrightnessSlider {
                id: brightnessControl
                width: parent.width
                palette: root.palette
                tokens: root.tokens
                value: root.brightness
                onValueCommitted: value => root.brightnessRequested(value)
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.palette.bg3
            }

            Text {
                text: "Displays"
                color: root.palette.aqua
                font.family: root.tokens.uiFont
                font.pixelSize: 12
                font.bold: true
            }

            Item {
                width: parent.width
                height: root.displayListHeight

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.displays.length === 0
                    text: "No active displays"
                    color: root.palette.grey1
                    font.family: root.tokens.uiFont
                    font.pixelSize: 11
                }

                ListView {
                    id: displayList
                    anchors.fill: parent
                    visible: root.displays.length > 0
                    clip: true
                    model: root.displays
                    activeFocusOnTab: true
                    currentIndex: 0

                    Keys.onReturnPressed: {
                        if (currentIndex >= 0)
                            root.selectedDisplayName = root.displays[currentIndex].name;
                    }
                    Keys.onEnterPressed: {
                        if (currentIndex >= 0)
                            root.selectedDisplayName = root.displays[currentIndex].name;
                    }

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected:
                            modelData.name === root.selectedDisplayName
                        width: displayList.width
                        height: 32
                        radius: 5
                        color: modelData.focused ? root.palette.green
                            : selected ? root.palette.bg3 : "transparent"

                        Row {
                            anchors {
                                left: parent.left
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: 8
                                rightMargin: 8
                            }
                            spacing: 8

                            Text {
                                text: modelData.focused ? "󰄬" : "󰍹"
                                color: modelData.focused
                                    ? root.palette.bg0 : root.palette.grey1
                                font.family: root.tokens.iconFont
                                font.pixelSize: 14
                            }

                            Text {
                                width: parent.width - 28
                                text: modelData.label
                                elide: Text.ElideRight
                                color: modelData.focused
                                    ? root.palette.bg0 : root.palette.fg
                                font.family: root.tokens.uiFont
                                font.pixelSize: 11
                                font.bold: modelData.focused
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selectedDisplayName = modelData.name
                        }
                    }
                }
            }

            Text {
                text: root.selectedDisplay
                    ? "Scale · " + root.selectedDisplay.name : "Scale"
                color: root.palette.aqua
                font.family: root.tokens.uiFont
                font.pixelSize: 12
                font.bold: true
            }

            Row {
                width: parent.width
                height: 30
                spacing: 5

                Repeater {
                    model: root.scaleOptions

                    Rectangle {
                        required property real modelData
                        readonly property bool active: root.selectedDisplay
                            && Math.abs(root.selectedDisplay.scale - modelData) < 0.01
                        width: (parent.width - 20) / 5
                        height: 30
                        radius: 5
                        color: active ? root.palette.green
                            : scaleMouse.containsMouse ? root.palette.bg3 : "transparent"
                        border.color: active ? root.palette.green : root.palette.bg3
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.toFixed(1) + "×"
                            color: parent.active ? root.palette.bg0 : root.palette.fg
                            font.family: root.tokens.monoFont
                            font.pixelSize: 11
                            font.bold: parent.active
                        }

                        MouseArea {
                            id: scaleMouse
                            anchors.fill: parent
                            enabled: root.selectedDisplay !== null
                            hoverEnabled: enabled
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.scaleRequested(
                                root.selectedDisplayName, modelData)
                        }
                    }
                }
            }
        }
    }
}
