import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorWindow
    required property var palette
    required property var tokens
    property bool open: false
    property string currentProfile: "balanced"
    property bool performanceAvailable: true
    readonly property var profiles: [
        { name: "Power Saver", profile: "power-saver", icon: "󰌪" },
        { name: "Balanced", profile: "balanced", icon: "󰾅" }
    ].concat(performanceAvailable
        ? [{ name: "Performance", profile: "performance", icon: "󰓅" }] : [])

    signal dismissed
    signal profileRequested(string profile)

    function activateCurrentProfile() {
        if (profileList.currentIndex >= 0) {
            profileRequested(profiles[profileList.currentIndex].profile);
            dismissed();
        }
    }

    visible: open
    grabFocus: true
    implicitWidth: 250
    implicitHeight: 174
    color: "transparent"

    anchor.window: anchorWindow
    anchor.rect.x: anchorWindow.width - width - tokens.spaceXs
    anchor.rect.y: anchorWindow.height + tokens.popupMargin

    onVisibleChanged: {
        if (visible) {
            profileList.currentIndex = Math.max(0,
                profiles.findIndex(item => item.profile === currentProfile));
            Qt.callLater(() => profileList.forceActiveFocus());
        } else if (open) {
            dismissed();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.tokens.radiusLg
        color: root.palette.bg2
        border.color: root.palette.bg3
        border.width: 1

        Text {
            id: title
            anchors {
                top: parent.top
                left: parent.left
                topMargin: root.tokens.spaceMd
                leftMargin: root.tokens.spaceLg
            }
            text: "Power profile"
            color: root.palette.fg
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textMd
            font.bold: true
        }

        ListView {
            id: profileList
            anchors {
                top: title.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                margins: root.tokens.spaceSm
                topMargin: root.tokens.spaceSm
            }
            focus: true
            spacing: root.tokens.spaceXs
            model: root.profiles

            Keys.onEscapePressed: root.dismissed()
            Keys.onReturnPressed: root.activateCurrentProfile()
            Keys.onEnterPressed: root.activateCurrentProfile()

            delegate: Rectangle {
                id: profileRow
                required property var modelData
                required property int index
                readonly property bool selected: root.currentProfile === modelData.profile
                width: profileList.width
                height: 34
                radius: root.tokens.radiusMd
                color: selected ? root.palette.bg_green
                    : ListView.isCurrentItem || rowMouse.containsMouse
                        ? root.palette.bg3 : "transparent"
                border.color: ListView.isCurrentItem ? root.palette.green : "transparent"
                border.width: 1

                Row {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: root.tokens.spaceMd
                    }
                    spacing: root.tokens.spaceSm

                    Text {
                        text: modelData.icon
                        color: profileRow.selected ? root.palette.green : root.palette.aqua
                        font.family: root.tokens.iconFont
                        font.pixelSize: 16
                    }

                    Text {
                        text: modelData.name
                        color: root.palette.fg
                        font.family: root.tokens.uiFont
                        font.pixelSize: root.tokens.textSm
                        font.bold: profileRow.selected
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: profileList.currentIndex = profileRow.index
                    onClicked: {
                        root.profileRequested(modelData.profile);
                        root.dismissed();
                    }
                }
            }
        }
    }
}
