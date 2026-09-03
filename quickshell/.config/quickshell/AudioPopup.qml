import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorWindow
    required property var palette
    required property var tokens
    property bool open: false
    property int outputVolume: 0
    property bool outputMuted: false
    property int inputVolume: 0
    property bool inputMuted: false
    property var outputDevices: []
    property var inputDevices: []
    property var activeOutput: null
    property var activeInput: null

    signal dismissed
    signal outputVolumeRequested(int value)
    signal inputVolumeRequested(int value)
    signal outputMuteRequested
    signal inputMuteRequested
    signal outputDeviceRequested(var device)
    signal inputDeviceRequested(var device)

    visible: open
    grabFocus: true
    implicitWidth: Math.min(410, anchorWindow.width - tokens.spaceXl)
    implicitHeight: 326
    color: "transparent"

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow.width - width - tokens.spaceXs
    anchor.rect.y: anchorWindow.height + tokens.popupMargin

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => outputSection.focusSlider());
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
                text: "Audio"
                color: root.palette.fg
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textLg
                font.bold: true
            }

            AudioSection {
                id: outputSection
                width: parent.width
                height: 125
                palette: root.palette
                tokens: root.tokens
                title: "Output"
                icon: "󰓃"
                volume: root.outputVolume
                maximumVolume: 150
                muted: root.outputMuted
                devices: root.outputDevices
                activeDevice: root.activeOutput
                emptyText: "No output devices"
                onVolumeRequested: value => root.outputVolumeRequested(value)
                onMuteRequested: root.outputMuteRequested()
                onDeviceRequested: device => root.outputDeviceRequested(device)
            }

            Rectangle {
                width: parent.width
                height: 1
                color: root.palette.bg3
            }

            AudioSection {
                width: parent.width
                height: 125
                palette: root.palette
                tokens: root.tokens
                title: "Input"
                icon: "󰍬"
                volume: root.inputVolume
                muted: root.inputMuted
                microphone: true
                devices: root.inputDevices
                activeDevice: root.activeInput
                emptyText: "No input devices"
                onVolumeRequested: value => root.inputVolumeRequested(value)
                onMuteRequested: root.inputMuteRequested()
                onDeviceRequested: device => root.inputDeviceRequested(device)
            }
        }
    }
}
