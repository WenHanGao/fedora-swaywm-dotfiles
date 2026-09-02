import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var anchorWindow
    required property var palette
    required property var tokens
    property bool open: false
    readonly property var applications: DesktopEntries.applications.values
        .filter(application => !application.noDisplay)
        .sort((left, right) => left.name.localeCompare(right.name))
    readonly property var filteredApplications: {
        const query = searchInput.text.trim().toLowerCase();
        if (query === "")
            return applications;

        return applications.filter(application => {
            const keywords = application.keywords ? application.keywords.join(" ") : "";
            const searchable = [application.name, application.genericName,
                application.comment, keywords].join(" ").toLowerCase();
            return searchable.includes(query);
        });
    }

    signal dismissed

    function launch(application) {
        if (application.runInTerminal) {
            const command = ["foot", "-e"];
            for (let index = 0; index < application.command.length; ++index)
                command.push(application.command[index]);
            Quickshell.execDetached({
                command: command,
                workingDirectory: application.workingDirectory
            });
        } else {
            application.execute();
        }

        dismissed();
    }

    function launchSelected() {
        if (filteredApplications.length === 0)
            return;

        const index = Math.max(0, Math.min(applicationList.currentIndex,
            filteredApplications.length - 1));
        launch(filteredApplications[index]);
    }

    visible: open
    screen: anchorWindow.screen
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

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            applicationList.currentIndex = 0;
            Qt.callLater(() => searchInput.forceActiveFocus());
        } else if (open) {
            dismissed();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(600, parent.width - root.tokens.spaceXl * 2)
        height: Math.min(540, parent.height - root.tokens.spaceXl * 2)
        radius: root.tokens.radiusLg
        color: root.palette.bg2
        border.color: root.palette.bg3
        border.width: 1

        MouseArea {
            anchors.fill: parent
        }

        Text {
            id: title
            anchors {
                top: parent.top
                left: parent.left
                topMargin: 18
                leftMargin: 20
            }
            text: "Applications"
            color: root.palette.fg
            font.family: root.tokens.uiFont
            font.pixelSize: 17
            font.bold: true
        }

        Text {
            anchors {
                right: parent.right
                verticalCenter: title.verticalCenter
                rightMargin: 20
            }
            text: "Esc to close"
            color: root.palette.grey1
            font.family: root.tokens.uiFont
            font.pixelSize: 11
        }

        Rectangle {
            id: searchBox
            anchors {
                top: title.bottom
                left: parent.left
                right: parent.right
                topMargin: 16
                leftMargin: 16
                rightMargin: 16
            }
            height: 44
            radius: root.tokens.radiusMd
            color: root.palette.bg0
            border.color: searchInput.activeFocus ? root.palette.green : root.palette.bg3
            border.width: 1

            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 13
                }
                text: "󰍉"
                color: root.palette.green
                font.family: root.tokens.iconFont
                font.pixelSize: 17
            }

            TextInput {
                id: searchInput
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 42
                    rightMargin: 12
                }
                color: root.palette.fg
                selectionColor: root.palette.green
                selectedTextColor: root.palette.bg0
                font.family: root.tokens.uiFont
                font.pixelSize: 14
                clip: true

                Text {
                    anchors.fill: parent
                    visible: parent.text === ""
                    text: "Search applications"
                    color: root.palette.grey1
                    font: parent.font
                    verticalAlignment: Text.AlignVCenter
                }

                onTextChanged: applicationList.currentIndex = 0

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.dismissed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        applicationList.currentIndex = Math.min(
                            applicationList.currentIndex + 1,
                            root.filteredApplications.length - 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        applicationList.currentIndex = Math.max(
                            applicationList.currentIndex - 1, 0);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.launchSelected();
                        event.accepted = true;
                    }
                }
            }
        }

        ListView {
            id: applicationList
            anchors {
                top: searchBox.bottom
                left: parent.left
                right: parent.right
                bottom: footer.top
                topMargin: 12
                leftMargin: 12
                rightMargin: 12
                bottomMargin: 8
            }
            clip: true
            spacing: 4
            model: root.filteredApplications
            currentIndex: 0

            delegate: Rectangle {
                id: applicationRow

                required property var modelData
                required property int index
                width: applicationList.width
                height: 48
                radius: root.tokens.radiusMd
                color: ListView.isCurrentItem ? root.palette.green
                    : applicationMouse.containsMouse ? root.palette.bg3 : "transparent"

                Rectangle {
                    id: iconFallback
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 10
                    }
                    width: 30
                    height: 30
                    radius: 6
                    visible: applicationIcon.status !== Image.Ready
                    color: applicationRow.ListView.isCurrentItem
                        ? root.palette.bg2 : root.palette.bg3

                    Text {
                        anchors.centerIn: parent
                        text: "󰀻"
                        color: applicationRow.ListView.isCurrentItem
                            ? root.palette.green : root.palette.grey1
                        font.family: root.tokens.iconFont
                        font.pixelSize: 17
                    }
                }

                Image {
                    id: applicationIcon
                    anchors.fill: iconFallback
                    source: applicationRow.modelData.icon === "" ? ""
                        : Quickshell.iconPath(applicationRow.modelData.icon, true)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }

                Column {
                    anchors {
                        left: iconFallback.right
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 2

                    Text {
                        width: parent.width
                        text: applicationRow.modelData.name
                        color: applicationRow.ListView.isCurrentItem
                            ? root.palette.bg0 : root.palette.fg
                        font.family: root.tokens.uiFont
                        font.pixelSize: 13
                        font.bold: applicationRow.ListView.isCurrentItem
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: applicationRow.modelData.genericName
                            || applicationRow.modelData.comment
                        color: applicationRow.ListView.isCurrentItem
                            ? root.palette.bg2 : root.palette.grey1
                        font.family: root.tokens.uiFont
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: applicationMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: applicationList.currentIndex = applicationRow.index
                    onClicked: root.launch(applicationRow.modelData)
                }
            }
        }

        Text {
            anchors.centerIn: applicationList
            visible: root.filteredApplications.length === 0
            text: "No matching applications"
            color: root.palette.grey1
            font.family: root.tokens.uiFont
            font.pixelSize: 13
        }

        Text {
            id: footer
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 20
                rightMargin: 20
                bottomMargin: 12
            }
            height: 18
            text: root.filteredApplications.length + " results  •  ↑↓ select  •  Enter launch"
            color: root.palette.grey1
            font.family: root.tokens.uiFont
            font.pixelSize: 10
        }
    }
}
