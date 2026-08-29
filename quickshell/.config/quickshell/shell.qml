import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.I3

ShellRoot {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar

            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 32
            color: "#2d353b"

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 8
                    rightMargin: 12
                }

                spacing: 6

                Repeater {
                    model: I3.workspaces

                    Rectangle {
                        required property var modelData
                        readonly property bool onThisOutput: modelData.monitor !== null
                            && modelData.monitor.name === bar.screen.name

                        visible: onThisOutput
                        Layout.preferredWidth: visible ? 28 : 0
                        Layout.preferredHeight: 24
                        radius: 4
                        color: modelData.active ? "#a7c080" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.number > 0 ? modelData.number : modelData.name
                            color: modelData.active ? "#2d353b"
                                : modelData.urgent ? "#e67e80" : "#d3c6aa"
                            font.pixelSize: 13
                            font.bold: modelData.active
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.activate()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: Qt.formatDateTime(clock.date, "ddd, MMM d  HH:mm")
                    color: "#d3c6aa"
                    font.pixelSize: 13
                }
            }
        }
    }
}
