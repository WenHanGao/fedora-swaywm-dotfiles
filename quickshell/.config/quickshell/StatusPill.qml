import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property string text: ""
    property bool active: false
    property bool interactive: true
    property color highlightColor: "#a7c080"
    property real iconOpacity: 1.0

    signal clicked
    signal wheelUp
    signal wheelDown

    implicitWidth: content.implicitWidth + 14
    implicitHeight: 24
    radius: 4
    color: active ? highlightColor : mouse.containsMouse && interactive ? "#475258" : "transparent"

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            color: root.active ? "#2d353b" : "#d3c6aa"
            opacity: root.iconOpacity
            font.family: "Cascadia Mono NF"
            font.pixelSize: 16
            font.bold: root.active
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text !== ""
            text: root.text
            color: root.active ? "#2d353b" : "#d3c6aa"
            font.family: "Cascadia Mono NF"
            font.pixelSize: 13
            font.bold: root.active
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
        onWheel: event => {
            if (event.angleDelta.y > 0)
                root.wheelUp();
            else if (event.angleDelta.y < 0)
                root.wheelDown();
        }
    }
}
