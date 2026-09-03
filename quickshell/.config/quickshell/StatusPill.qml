import QtQuick

Rectangle {
    id: root

    property string icon: ""
    property string secondaryIcon: ""
    property string text: ""
    property bool active: false
    property bool interactive: true
    required property var palette
    required property var tokens
    property color highlightColor: palette.green
    property real iconOpacity: 1.0
    property int maximumTextWidth: 160

    signal clicked
    signal wheelUp
    signal wheelDown

    implicitWidth: content.implicitWidth + tokens.spaceLg
    implicitHeight: tokens.controlHeight
    radius: tokens.radiusSm
    color: active ? highlightColor
        : mouse.containsMouse && interactive ? palette.bg3 : "transparent"

    Row {
        id: content
        anchors.centerIn: parent
        spacing: root.tokens.spaceXs

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            text: root.icon
            color: root.active ? root.palette.bg0 : root.palette.fg
            opacity: root.iconOpacity
            font.family: root.tokens.iconFont
            font.pixelSize: 18
            font.weight: root.active ? Font.Bold : Font.DemiBold
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.secondaryIcon !== ""
            text: root.secondaryIcon
            color: root.active ? root.palette.bg0 : root.palette.fg
            font.family: root.tokens.iconFont
            font.pixelSize: 18
            font.weight: root.active ? Font.Bold : Font.DemiBold
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.text !== ""
            text: root.text
            width: Math.min(implicitWidth, root.maximumTextWidth)
            elide: Text.ElideRight
            color: root.active ? root.palette.bg0 : root.palette.fg
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textMd
            font.weight: root.active ? Font.Bold : Font.DemiBold
        }
    }

    Behavior on color {
        ColorAnimation { duration: root.tokens.transitionFast }
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
