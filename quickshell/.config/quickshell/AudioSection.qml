import QtQuick

Item {
    id: root

    required property var palette
    property string title: ""
    property string icon: ""
    property int volume: 0
    property int maximumVolume: 100
    property bool muted: false
    property bool microphone: false
    property var devices: []
    property string emptyText: "No devices"

    signal volumeRequested(int value)
    signal muteRequested
    signal deviceRequested(string id)

    Text {
        id: titleLabel
        anchors {
            top: parent.top
            left: parent.left
        }
        text: root.icon + "  " + root.title
        color: root.palette.aqua
        font.family: "Cascadia Mono NF"
        font.pixelSize: 13
        font.bold: true
    }

    AudioSlider {
        id: volumeSlider
        anchors {
            top: titleLabel.bottom
            left: parent.left
            right: parent.right
            topMargin: 3
        }
        palette: root.palette
        value: root.volume
        maximumValue: root.maximumVolume
        muted: root.muted
        microphone: root.microphone
        onValueCommitted: value => root.volumeRequested(value)
        onMuteClicked: root.muteRequested()
    }

    Text {
        anchors {
            top: volumeSlider.bottom
            left: parent.left
            topMargin: 2
        }
        visible: root.devices.length === 0
        text: root.emptyText
        color: root.palette.grey1
        font.family: "Cascadia Mono NF"
        font.pixelSize: 11
    }

    ListView {
        id: deviceList
        anchors {
            top: volumeSlider.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: 2
        }
        visible: root.devices.length > 0
        clip: true
        spacing: 2
        model: root.devices

        delegate: Rectangle {
            required property var modelData
            width: deviceList.width
            height: 30
            radius: 5
            color: modelData.active ? root.palette.green
                : deviceMouse.containsMouse ? root.palette.bg3 : "transparent"

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
                    text: modelData.active ? "󰄬" : " "
                    color: modelData.active ? root.palette.bg0 : root.palette.grey1
                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 13
                }

                Text {
                    width: parent.width - 28
                    text: modelData.name
                    elide: Text.ElideRight
                    color: modelData.active ? root.palette.bg0 : root.palette.fg
                    font.family: "Cascadia Mono NF"
                    font.pixelSize: 11
                    font.bold: modelData.active
                }
            }

            MouseArea {
                id: deviceMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.deviceRequested(modelData.id)
            }
        }
    }
}
