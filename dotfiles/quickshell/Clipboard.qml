pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Commons"

Scope {
    id: root

    property bool opened: false
    property string query: ""
    property int selectedIndex: 0
        property bool deleteFocused: false
    property var entries: []

    readonly property var filtered: {
        if (!opened)
            return [];
        const needle = query.trim().toLowerCase();
        if (needle === "")
            return entries.slice(0, 24);
        const out = [];
        for (let i = 0; i < entries.length && out.length < 24; i++) {
            if (String(entries[i].preview).toLowerCase().indexOf(needle) >= 0)
                out.push(entries[i]);
        }
        return out;
    }

    onFilteredChanged: {
        if (selectedIndex >= filtered.length)
            selectedIndex = Math.max(0, filtered.length - 1);
        deleteFocused = false;
    }

    onSelectedIndexChanged: deleteFocused = false

    function parseList(raw) {
        const lines = String(raw || "").split("\n");
        const list = [];
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (!line)
                continue;
            const tab = line.indexOf("\t");
            const preview = tab >= 0 ? line.slice(tab + 1) : line;
            list.push({
                "line": line,
                "preview": preview.indexOf("[binary") === 0 ? "Image" : preview
            });
        }
        entries = list;
    }

    function open(): void {
        query = "";
        selectedIndex = 0;
        opened = true;
        listProc.running = true;
        Qt.callLater(() => searchField.forceActiveFocus());
    }

    function close(): void {
        opened = false;
        query = "";
    }

    function toggle(): void {
        if (opened)
            close();
        else
            open();
    }

    readonly property string pasteHelper: Quickshell.env("HOME") + "/.local/bin/qs-clip-paste"
    readonly property string deleteHelper: Quickshell.env("HOME") + "/.local/bin/qs-clip-delete"

    function paste(entry): void {
        if (!entry)
            return;
        close();
        Quickshell.execDetached([root.pasteHelper, entry.line]);
    }

    function remove(entry): void {
        if (!entry)
            return;
        deleteProc.command = [root.deleteHelper, entry.line];
        deleteProc.running = true;
    }

    Connections {
        target: Popups
        function onClosed() {
            root.close();
        }
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseList(text)
        }
    }

    Process {
        id: deleteProc
        onExited: listProc.running = true
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): string {
            root.toggle();
            return "ok";
        }

        function open(): string {
            root.open();
            return "ok";
        }

        function close(): string {
            root.close();
            return "ok";
        }
    }

    PanelWindow {
        visible: root.opened
        color: "transparent"
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-clipboard"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 72
            width: 420
            implicitHeight: column.implicitHeight + Style.pad * 2
            color: Color.popupBackground
            radius: Style.radius
            border.width: 1
            border.color: Color.surface

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.pad
                spacing: 8

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: Style.radius
                    color: Color.surface
                    border.width: 1
                    border.color: Color.overlay

                    TextInput {
                        id: searchField
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        color: Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontBody
                        clip: true
                        text: root.query
                        onTextChanged: {
                            root.query = text;
                            root.selectedIndex = 0;
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                root.selectedIndex = Math.min(root.selectedIndex + 1, Math.max(0, root.filtered.length - 1));
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Right) {
                                root.deleteFocused = true;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Left) {
                                root.deleteFocused = false;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.filtered.length > 0) {
                                    if (root.deleteFocused)
                                        root.remove(root.filtered[root.selectedIndex]);
                                    else
                                        root.paste(root.filtered[root.selectedIndex]);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Delete) {
                                if (root.filtered.length > 0)
                                    root.remove(root.filtered[root.selectedIndex]);
                                event.accepted = true;
                            }
                        }
                    }
                }

                Text {
                    visible: root.filtered.length === 0
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: "Clipboard empty"
                }

                Repeater {
                    model: root.filtered

                    Row {
                        required property var modelData
                        required property int index
                        width: column.width
                        height: 32
                        spacing: 6

                        Rectangle {
                            width: parent.width - 38
                            height: 32
                            radius: Style.radius
                            color: index === root.selectedIndex && !root.deleteFocused ? Color.focusFill : Color.surface

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                                color: Color.popupText
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontCaption
                                text: modelData.preview
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    root.selectedIndex = index;
                                    root.deleteFocused = false;
                                }
                                onClicked: root.paste(modelData)
                            }
                        }

                        Rectangle {
                            width: 32
                            height: 32
                            radius: Style.radius
                            color: index === root.selectedIndex && root.deleteFocused ? Color.urgent : Color.surface

                            Text {
                                anchors.centerIn: parent
                                color: index === root.selectedIndex && root.deleteFocused ? Color.background : Color.muted
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontCaption
                                font.bold: true
                                text: "x"
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    root.selectedIndex = index;
                                    root.deleteFocused = true;
                                }
                                onClicked: root.remove(modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
