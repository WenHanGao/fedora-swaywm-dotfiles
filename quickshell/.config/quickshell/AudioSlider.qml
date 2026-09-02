import QtQuick

Item {
    id: root

    required property var palette
    required property var tokens
    property real value: 0
    property real maximumValue: 100
    property bool muted: false
    property bool microphone: false
    property real dragValue: 0
    property bool awaitingUpdate: false
    readonly property real displayedValue: sliderMouse.pressed || awaitingUpdate
        ? dragValue : value

    signal valueCommitted(real value)
    signal muteClicked

    implicitHeight: 34
    activeFocusOnTab: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            root.valueCommitted(Math.max(0, Math.round(root.displayedValue - 5)));
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            root.valueCommitted(Math.min(root.maximumValue,
                Math.round(root.displayedValue + 5)));
            event.accepted = true;
        } else if (event.key === Qt.Key_Space) {
            root.muteClicked();
            event.accepted = true;
        }
    }

    Component.onCompleted: dragValue = value

    onValueChanged: {
        if (awaitingUpdate && Math.abs(value - dragValue) <= 1)
            awaitingUpdate = false;
        if (!sliderMouse.pressed && !awaitingUpdate)
            dragValue = value;
    }

    function valueAt(position) {
        return Math.max(0, Math.min(maximumValue,
            Math.round(position / sliderTrack.width * maximumValue)));
    }

    Text {
        id: muteButton
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: 28
        text: root.microphone ? (root.muted ? "󰍭" : "󰍬")
            : root.muted || root.displayedValue === 0 ? "󰖁"
                : root.displayedValue < 50 ? "󰕿" : "󰕾"
        color: root.muted ? root.palette.red : root.palette.green
        font.family: root.tokens.iconFont
        font.pixelSize: 18

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.muteClicked()
        }
    }

    Item {
        id: sliderTrack
        anchors {
            left: muteButton.right
            right: valueLabel.left
            verticalCenter: parent.verticalCenter
            leftMargin: 8
            rightMargin: 10
        }
        height: 20

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 5
            radius: 3
            color: root.palette.bg3
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, Math.min(parent.width,
                parent.width * root.displayedValue / root.maximumValue))
            height: 5
            radius: 3
            color: root.muted ? root.palette.grey1 : root.palette.green
        }

        Rectangle {
            x: Math.max(0, Math.min(parent.width - width,
                parent.width * root.displayedValue / root.maximumValue - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 13
            height: 13
            radius: 7
            color: root.palette.fg
        }

        Rectangle {
            anchors.fill: parent
            visible: root.activeFocus
            radius: 4
            color: "transparent"
            border.color: root.palette.aqua
            border.width: 1
        }

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onPressed: event => {
                settleTimer.stop();
                root.awaitingUpdate = false;
                root.dragValue = root.valueAt(event.x);
            }
            onPositionChanged: event => {
                if (pressed)
                    root.dragValue = root.valueAt(event.x);
            }
            onReleased: {
                root.awaitingUpdate = true;
                settleTimer.restart();
                root.valueCommitted(root.dragValue);
            }
        }
    }

    Timer {
        id: settleTimer
        interval: 750
        onTriggered: root.awaitingUpdate = false
    }

    Text {
        id: valueLabel
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: 38
        text: Math.round(root.displayedValue) + "%"
        horizontalAlignment: Text.AlignRight
        color: root.palette.fg
        font.family: root.tokens.monoFont
        font.pixelSize: root.tokens.textSm
    }
}
