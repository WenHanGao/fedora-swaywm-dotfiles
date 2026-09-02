import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var targetScreen
    required property var palette
    required property var tokens
    property bool open: false
    property string pendingAction: ""
    property int selectedAction: 0

    signal dismissed
    signal actionRequested(string action)

    visible: open && targetScreen !== null
    screen: targetScreen
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function moveSelection(offset) {
        pendingAction = "";
        confirmationTimer.stop();
        selectedAction = (selectedAction + offset + 3) % 3;
    }

    function choose(action) {
        if (action === "lock") {
            actionRequested(action);
            dismissed();
        } else if (pendingAction === action) {
            pendingAction = "";
            actionRequested(action);
            dismissed();
        } else {
            pendingAction = action;
            confirmationTimer.restart();
        }
    }

    function activateSelected() {
        choose(selectedAction === 0 ? "lock" : selectedAction === 1 ? "reboot" : "shutdown");
    }

    onVisibleChanged: {
        if (visible) {
            selectedAction = 0;
            pendingAction = "";
            Qt.callLater(() => card.forceActiveFocus());
        } else if (open) {
            dismissed();
        }
    }

    Timer {
        id: confirmationTimer
        interval: 3000
        onTriggered: root.pendingAction = ""
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(430, root.width - root.tokens.spaceXl * 2)
        height: 182
        focus: true
        radius: root.tokens.radiusLg
        color: root.palette.bg2
        border.color: root.palette.bg3
        border.width: 1

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                root.moveSelection(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                root.moveSelection(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                    || event.key === Qt.Key_Space) {
                root.activateSelected();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                root.dismissed();
                event.accepted = true;
            }
        }

        Text {
            anchors {
                top: parent.top
                horizontalCenter: parent.horizontalCenter
                topMargin: root.tokens.spaceLg
            }
            text: root.pendingAction === ""
                ? "Power menu" : "Activate again to confirm"
            color: root.pendingAction === "" ? root.palette.fg : root.palette.red
            font.family: root.tokens.uiFont
            font.pixelSize: root.tokens.textMd
            font.bold: true
        }

        Row {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: root.tokens.spaceLg
            }
            spacing: root.tokens.spaceSm

            PowerActionButton {
                palette: root.palette
                tokens: root.tokens
                icon: "󰌾"
                label: "Lock"
                selected: root.selectedAction === 0
                onClicked: root.choose("lock")
            }

            PowerActionButton {
                palette: root.palette
                tokens: root.tokens
                icon: "󰜉"
                label: root.pendingAction === "reboot" ? "Confirm" : "Reboot"
                accentColor: root.palette.red
                confirmationPending: root.pendingAction === "reboot"
                selected: root.selectedAction === 1
                onClicked: root.choose("reboot")
            }

            PowerActionButton {
                palette: root.palette
                tokens: root.tokens
                icon: "󰐥"
                label: root.pendingAction === "shutdown" ? "Confirm" : "Shutdown"
                accentColor: root.palette.red
                confirmationPending: root.pendingAction === "shutdown"
                selected: root.selectedAction === 2
                onClicked: root.choose("shutdown")
            }
        }
    }
}
