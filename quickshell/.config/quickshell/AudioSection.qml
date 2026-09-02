import QtQuick

Item {
    id: root

    required property var palette
    required property var tokens
    property string title: ""
    property string icon: ""
    property int volume: 0
    property int maximumVolume: 100
    property bool muted: false
    property bool microphone: false
    property var devices: []
    property var activeDevice: null
    property string emptyText: "No devices"

    signal volumeRequested(int value)
    signal muteRequested
    signal deviceRequested(var device)

    function focusSlider() {
        volumeSlider.forceActiveFocus();
    }

    Text {
        id: titleLabel
        anchors {
            top: parent.top
            left: parent.left
        }
        text: root.icon + "  " + root.title
        color: root.palette.aqua
        font.family: root.tokens.uiFont
        font.pixelSize: root.tokens.textMd
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
        tokens: root.tokens
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
        font.family: root.tokens.uiFont
        font.pixelSize: root.tokens.textSm
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
        activeFocusOnTab: true
        currentIndex: 0

        Keys.onReturnPressed: {
            if (currentIndex >= 0)
                root.deviceRequested(root.devices[currentIndex]);
        }
        Keys.onEnterPressed: {
            if (currentIndex >= 0)
                root.deviceRequested(root.devices[currentIndex]);
        }

        delegate: Rectangle {
            id: deviceRow
            required property var modelData
            readonly property bool active: modelData === root.activeDevice
            width: deviceList.width
            height: 30
            radius: root.tokens.radiusSm
            color: active ? root.palette.bg_green
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
                    text: deviceRow.active ? "󰄬" : " "
                    color: deviceRow.active ? root.palette.green : root.palette.grey1
                    font.family: root.tokens.iconFont
                    font.pixelSize: 13
                }

                Text {
                    width: parent.width - 28
                    text: modelData.description || modelData.nickname || modelData.name
                    elide: Text.ElideRight
                    color: root.palette.fg
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: deviceRow.active
                }
            }

            MouseArea {
                id: deviceMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.deviceRequested(modelData)
            }
        }
    }
}
