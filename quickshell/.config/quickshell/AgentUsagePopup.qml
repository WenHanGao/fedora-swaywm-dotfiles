import QtQuick
import Quickshell

PopupWindow {
    id: root

    required property var anchorWindow
    required property var anchorItem
    required property var palette
    required property var tokens
    property bool open: false
    property bool available: false
    property string plan: ""
    property real primaryUsed: 0
    property int primaryWindow: 0
    property double primaryReset: 0
    property real secondaryUsed: 0
    property int secondaryWindow: 0
    property double secondaryReset: 0
    property double totalTokens: 0
    property bool claudeAvailable: false
    property string claudeModel: ""
    property double claudeInputTokens: 0
    property double claudeOutputTokens: 0
    property double now: Date.now()
    property string selectedProvider: "codex"
    property bool selectorOpen: false

    signal dismissed

    visible: open
    grabFocus: true
    implicitWidth: Math.min(330, anchorWindow.width - tokens.spaceXl)
    implicitHeight: selectorOpen ? 490 : 410
    color: "transparent"

    // Keep the popup centered below its pill while remaining on-screen.
    anchor.window: anchorWindow
    anchor.rect.x: Math.max(tokens.spaceXs, Math.min(
        anchorWindow.width - width - tokens.spaceXs,
        Math.round(anchorItem.mapToItem(null, 0, 0).x
            + anchorItem.width / 2 - width / 2)))
    anchor.rect.y: Math.round(anchorItem.mapToItem(null, 0, 0).y
        + anchorItem.height + tokens.popupMargin)

    function windowLabel(minutes) {
        if (minutes >= 10080)
            return "Weekly limit";
        if (minutes >= 60 && minutes % 60 === 0)
            return (minutes / 60) + "-hour limit";
        return minutes + "-minute limit";
    }

    function resetLabel(epochSeconds) {
        if (epochSeconds <= 0)
            return "Reset time unavailable";
        const remaining = Math.max(0, epochSeconds * 1000 - root.now);
        const minutes = Math.ceil(remaining / 60000);
        if (minutes < 60)
            return "Resets in " + minutes + "m";
        if (minutes < 1440)
            return "Resets in " + Math.floor(minutes / 60) + "h "
                + (minutes % 60) + "m";
        return "Resets " + Qt.formatDateTime(new Date(epochSeconds * 1000),
            "ddd HH:mm");
    }

    function formatTokens(value) {
        if (value >= 1000000)
            return (value / 1000000).toFixed(1) + "M";
        if (value >= 1000)
            return (value / 1000).toFixed(1) + "K";
        return Math.round(value).toString();
    }

    function shortModel(model) {
        if (!model)
            return "Local session";
        return model.replace(/^claude-/, "").replace(/-\d{8}$/, "");
    }

    function selectProvider(provider) {
        selectedProvider = provider;
        selectorOpen = false;
    }

    onVisibleChanged: {
        if (visible) {
            now = Date.now();
            selectorOpen = false;
            Qt.callLater(() => card.forceActiveFocus());
        } else if (open) {
            dismissed();
        }
    }

    Timer {
        interval: 60000
        running: root.visible
        repeat: true
        onTriggered: root.now = Date.now()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        focus: true
        radius: root.tokens.radiusLg
        color: root.palette.bg2
        border.color: root.palette.bg3
        border.width: 1

        Keys.onEscapePressed: {
            if (root.selectorOpen)
                root.selectorOpen = false;
            else
                root.dismissed();
        }

        Column {
            anchors {
                fill: parent
                margins: root.tokens.spaceLg
            }
            spacing: root.tokens.spaceMd

            Text {
                text: "AI agent usage"
                color: root.palette.fg
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textLg
                font.bold: true
            }

            Rectangle {
                width: parent.width
                height: 38
                radius: root.tokens.radiusMd
                color: root.palette.bg_green

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: root.tokens.spaceMd
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Codex"
                    color: root.palette.green
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: true
                }

                Text {
                    anchors {
                        right: parent.right
                        rightMargin: root.tokens.spaceMd
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.available
                        ? Math.round(root.primaryUsed) + "% 5h · "
                            + Math.round(root.secondaryUsed) + "% week"
                        : "No usage yet"
                    color: root.available ? root.palette.fg : root.palette.grey1
                    font.family: root.tokens.monoFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: root.available
                }
            }

            Rectangle {
                width: parent.width
                height: 38
                radius: root.tokens.radiusMd
                color: root.palette.bg_yellow

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: root.tokens.spaceMd
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Claude"
                    color: root.palette.orange
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: true
                }

                Text {
                    anchors {
                        right: parent.right
                        rightMargin: root.tokens.spaceMd
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.claudeAvailable
                        ? root.formatTokens(root.claudeInputTokens
                            + root.claudeOutputTokens) + " tokens · "
                            + root.shortModel(root.claudeModel)
                        : "Not detected"
                    color: root.claudeAvailable ? root.palette.fg : root.palette.grey1
                    font.family: root.tokens.monoFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: root.claudeAvailable
                }
            }

            Text {
                text: "Provider details"
                color: root.palette.aqua
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textXs
                font.bold: true
            }

            Rectangle {
                id: providerSelector
                width: parent.width
                height: 34
                radius: root.tokens.radiusMd
                color: selectorMouse.containsMouse
                    ? root.palette.bg3 : root.palette.bg1
                border.color: root.selectorOpen ? root.palette.aqua : root.palette.bg3
                border.width: 1

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: root.tokens.spaceMd
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.selectedProvider === "codex" ? "Codex" : "Claude"
                    color: root.palette.fg
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: true
                }

                Text {
                    anchors {
                        right: parent.right
                        rightMargin: root.tokens.spaceMd
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.selectorOpen ? "󰅀" : "󰅂"
                    color: root.palette.grey1
                    font.family: root.tokens.iconFont
                    font.pixelSize: root.tokens.textMd
                }

                MouseArea {
                    id: selectorMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectorOpen = !root.selectorOpen
                }
            }

            Rectangle {
                visible: root.selectorOpen
                width: parent.width
                height: 68
                radius: root.tokens.radiusMd
                color: root.palette.bg1
                border.color: root.palette.bg3
                border.width: 1

                Column {
                    anchors.fill: parent

                    Repeater {
                        model: [
                            { id: "codex", name: "Codex" },
                            { id: "claude", name: "Claude" }
                        ]

                        Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 34
                            color: root.selectedProvider === modelData.id
                                ? root.palette.bg3 : optionMouse.containsMouse
                                    ? root.palette.bg2 : "transparent"

                            Text {
                                anchors {
                                    left: parent.left
                                    leftMargin: root.tokens.spaceMd
                                    verticalCenter: parent.verticalCenter
                                }
                                text: modelData.name
                                color: root.palette.fg
                                font.family: root.tokens.uiFont
                                font.pixelSize: root.tokens.textSm
                            }

                            Text {
                                visible: root.selectedProvider === modelData.id
                                anchors {
                                    right: parent.right
                                    rightMargin: root.tokens.spaceMd
                                    verticalCenter: parent.verticalCenter
                                }
                                text: "󰄬"
                                color: root.palette.green
                                font.family: root.tokens.iconFont
                                font.pixelSize: root.tokens.textMd
                            }

                            MouseArea {
                                id: optionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectProvider(modelData.id)
                            }
                        }
                    }
                }
            }

            Item {
                visible: root.selectedProvider === "codex"
                width: parent.width
                height: 18

                Text {
                    text: "Codex limits"
                    color: root.palette.blue
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    text: root.plan ? root.plan.charAt(0).toUpperCase()
                        + root.plan.slice(1) : "Local session"
                    color: root.palette.grey1
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                }
            }

            Text {
                visible: root.selectedProvider === "codex" && !root.available
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Usage appears after Codex reports its first rate-limit update."
                color: root.palette.grey1
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textSm
            }

            UsageRow {
                visible: root.selectedProvider === "codex" && root.available
                width: parent.width
                colors: root.palette
                tokens: root.tokens
                title: root.windowLabel(root.primaryWindow)
                resetText: root.resetLabel(root.primaryReset)
                used: root.primaryUsed
            }

            UsageRow {
                visible: root.selectedProvider === "codex" && root.available
                width: parent.width
                colors: root.palette
                tokens: root.tokens
                title: root.windowLabel(root.secondaryWindow)
                resetText: root.resetLabel(root.secondaryReset)
                used: root.secondaryUsed
            }

            Item {
                visible: root.selectedProvider === "codex" && root.available
                width: parent.width
                height: codexSessionLabel.implicitHeight

                Text {
                    id: codexSessionLabel
                    text: "Current session"
                    color: root.palette.grey1
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                }

                Text {
                    anchors.right: parent.right
                    text: root.formatTokens(root.totalTokens) + " tokens"
                    color: root.palette.fg
                    font.family: root.tokens.monoFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: true
                }
            }

            Item {
                visible: root.selectedProvider === "claude"
                width: parent.width
                height: 18

                Text {
                    text: "Claude session"
                    color: root.palette.orange
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: true
                }

                Text {
                    anchors.right: parent.right
                    text: root.claudeAvailable
                        ? root.shortModel(root.claudeModel) : "Not detected"
                    color: root.palette.grey1
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                }
            }

            Text {
                visible: root.selectedProvider === "claude" && !root.claudeAvailable
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Usage appears after the first Claude Code session."
                color: root.palette.grey1
                font.family: root.tokens.uiFont
                font.pixelSize: root.tokens.textSm
            }

            Item {
                visible: root.selectedProvider === "claude" && root.claudeAvailable
                width: parent.width
                height: 18

                Text {
                    text: "Input tokens"
                    color: root.palette.grey1
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                }

                Text {
                    anchors.right: parent.right
                    text: root.formatTokens(root.claudeInputTokens)
                    color: root.palette.fg
                    font.family: root.tokens.monoFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: true
                }
            }

            Item {
                visible: root.selectedProvider === "claude" && root.claudeAvailable
                width: parent.width
                height: 18

                Text {
                    text: "Output tokens"
                    color: root.palette.grey1
                    font.family: root.tokens.uiFont
                    font.pixelSize: root.tokens.textSm
                }

                Text {
                    anchors.right: parent.right
                    text: root.formatTokens(root.claudeOutputTokens)
                    color: root.palette.fg
                    font.family: root.tokens.monoFont
                    font.pixelSize: root.tokens.textSm
                    font.bold: true
                }
            }
        }
    }
}
