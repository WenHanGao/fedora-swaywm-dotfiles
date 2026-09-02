import QtQuick

Item {
    id: root

    required property var palette
    required property var tokens
    property real value: 0
    property real dragValue: 0
    property bool awaitingUpdate: false
    readonly property real displayedValue: sliderMouse.pressed || awaitingUpdate
        ? dragValue : value

    signal valueCommitted(int value)

    implicitHeight: 34
    activeFocusOnTab: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Down) {
            root.valueCommitted(Math.max(1, Math.round(root.displayedValue - 5)));
            event.accepted = true;
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Up) {
            root.valueCommitted(Math.min(100, Math.round(root.displayedValue + 5)));
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
        return Math.max(1, Math.min(100,
            Math.round(position / sliderTrack.width * 100)));
    }

    Text {
        id: brightnessIcon
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        width: 28
        text: "󰃠"
        color: root.palette.yellow
        font.family: root.tokens.iconFont
        font.pixelSize: 18
    }

    Item {
        id: sliderTrack
        anchors {
            left: brightnessIcon.right
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
                parent.width * root.displayedValue / 100))
            height: 5
            radius: 3
            color: root.palette.yellow
        }

        Rectangle {
            x: Math.max(0, Math.min(parent.width - width,
                parent.width * root.displayedValue / 100 - width / 2))
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
                root.valueCommitted(Math.round(root.dragValue));
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
