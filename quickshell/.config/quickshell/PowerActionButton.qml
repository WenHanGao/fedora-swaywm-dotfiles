import QtQuick

Rectangle {
    id: root

    required property var palette
    property string icon: ""
    property string label: ""
    property color accentColor: palette.green
    property bool confirmationPending: false
    property bool selected: false

    signal clicked

    implicitWidth: 112
    implicitHeight: 88
    radius: 8
    color: confirmationPending ? accentColor
        : selected || buttonMouse.containsMouse ? palette.bg2 : palette.bg0
    border.color: confirmationPending || selected ? accentColor : palette.bg3
    border.width: 1

    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            color: root.confirmationPending ? root.palette.bg0 : root.accentColor
            font.family: "Cascadia Mono NF"
            font.pixelSize: 28
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: root.confirmationPending ? root.palette.bg0 : root.palette.fg
            font.family: "Cascadia Mono NF"
            font.pixelSize: 12
            font.bold: root.confirmationPending
        }
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
