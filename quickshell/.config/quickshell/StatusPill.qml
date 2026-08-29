import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property string text: ""
    property bool active: false
    property bool interactive: true

    signal clicked
    signal wheelUp
    signal wheelDown

    implicitWidth: label.implicitWidth + 14
    implicitHeight: 24
    radius: 4
    color: active ? "#a7c080" : mouse.containsMouse && interactive ? "#475258" : "transparent"

    Text {
        id: label
        anchors.centerIn: parent
        text: root.icon + (root.icon !== "" && root.text !== "" ? " " : "") + root.text
        color: root.active ? "#2d353b" : "#d3c6aa"
        font.family: "Cascadia Mono NF"
        font.pixelSize: 13
        font.bold: root.active
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
