import QtQuick

Column {
    id: root

    required property var colors
    required property var tokens
    property string title: ""
    property string resetText: ""
    property real used: 0
    readonly property color meterColor: used >= 90 ? colors.red
        : used >= 70 ? colors.yellow : colors.green

    spacing: tokens.spaceXs

    Item {
        width: parent.width
        height: 18

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            color: root.colors.fg
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textSm
            font.bold: true
        }

        Text {
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            text: Math.round(root.used) + "% used"
            color: root.meterColor
            font.family: root.tokens.monoFont
            font.pixelSize: root.tokens.textSm
            font.bold: true
        }
    }

    Rectangle {
        width: parent.width
        height: 7
        radius: height / 2
        color: root.colors.bg3

        Rectangle {
            width: parent.width * Math.max(0, Math.min(100, root.used)) / 100
            height: parent.height
            radius: parent.radius
            color: root.meterColor

            Behavior on width {
                NumberAnimation { duration: root.tokens.transitionNormal }
            }
        }
    }

    Text {
        text: root.resetText
        color: root.colors.grey1
        font.family: root.tokens.uiFont
        font.pixelSize: root.tokens.textXs
    }
}
