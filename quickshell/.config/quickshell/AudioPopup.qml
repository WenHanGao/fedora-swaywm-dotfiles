import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorWindow
    required property var palette
    property bool open: false
    property int outputVolume: 0
    property bool outputMuted: false
    property int inputVolume: 0
    property bool inputMuted: false
    property var outputDevices: []
    property var inputDevices: []

    signal dismissed
    signal outputVolumeRequested(int value)
    signal inputVolumeRequested(int value)
    signal outputMuteRequested
    signal inputMuteRequested
    signal outputDeviceRequested(string id)
    signal inputDeviceRequested(string id)

    visible: open
    grabFocus: true
    implicitWidth: 390
    implicitHeight: 326
    color: "transparent"

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow.width - width - 1
    anchor.rect.y: anchorWindow.height + 8

    onVisibleChanged: {
        if (!visible)
            root.dismissed();
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.palette.bg1
        border.color: root.palette.bg3
        border.width: 1

        Column {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: 8

            Text {
                text: "Audio"
                color: root.palette.fg
                font.family: "Cascadia Mono NF"
                font.pixelSize: 15
                font.bold: true
            }

            AudioSection {
                width: parent.width
                height: 125
                palette: root.palette
                title: "Output"
                icon: "󰓃"
                volume: root.outputVolume
                maximumVolume: 150
                muted: root.outputMuted
                devices: root.outputDevices
                emptyText: "No output devices"
                onVolumeRequested: value => root.outputVolumeRequested(value)
                onMuteRequested: root.outputMuteRequested()
                onDeviceRequested: id => root.outputDeviceRequested(id)
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
                title: "Input"
                icon: "󰍬"
                volume: root.inputVolume
                muted: root.inputMuted
                microphone: true
                devices: root.inputDevices
                emptyText: "No input devices"
                onVolumeRequested: value => root.inputVolumeRequested(value)
                onMuteRequested: root.inputMuteRequested()
                onDeviceRequested: id => root.inputDeviceRequested(id)
            }
        }
    }
}
