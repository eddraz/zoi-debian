pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Commons"
import "EmojiSearch.js" as EmojiSearch

Scope {
    id: root

    property bool opened: false
    property string query: ""
    property int selectedIndex: 0
    property var emojis: []

    readonly property int columns: 8
    readonly property int cell: 40
    readonly property int limit: 192
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/qs-emoji-paste"

    readonly property var filtered: {
        if (!opened)
            return [];
        return EmojiSearch.filterEmojis(emojis, query, limit);
    }

    onFilteredChanged: {
        if (selectedIndex >= filtered.length)
            selectedIndex = Math.max(0, filtered.length - 1);
        Qt.callLater(ensureVisible);
    }

    onSelectedIndexChanged: ensureVisible()

    function ensureVisible() {
        if (!scroller)
            return;
        const row = Math.floor(selectedIndex / columns);
        const y = row * (cell + 4);
        if (y < scroller.contentY)
            scroller.contentY = y;
        else if (y + cell > scroller.contentY + scroller.height)
            scroller.contentY = Math.max(0, y + cell - scroller.height);
    }

    function open(): void {
        query = "";
        selectedIndex = 0;
        opened = true;
        if (scroller)
            scroller.contentY = 0;
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

    function pick(emoji): void {
        if (!emoji)
            return;
        close();
        Quickshell.execDetached([helper, emoji]);
    }

    Connections {
        target: Popups
        function onClosed() {
            root.close();
        }
    }

    IpcHandler {
        target: "emojis"

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

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/emojis.json"
        printErrors: false
        onLoaded: root.emojis = EmojiSearch.parseEmojis(text())
    }

    PanelWindow {
        id: win
        visible: root.opened
        color: "transparent"
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-emojis"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        readonly property int topGap: 72
        readonly property int maxCardHeight: Math.max(160, height - topGap - Style.pad * 2)

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: win.topGap
            width: Math.min(Style.popupMaxWidth, win.width - Style.pad * 2)
            height: Math.min(Style.pad * 2 + 30 + 8 + scroller.height, win.maxCardHeight)
            color: Color.popupBackground
            radius: Style.radius
            border.width: 1
            border.color: Color.surface
            clip: true

            MouseArea {
                anchors.fill: parent
            }

            Column {
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
                            scroller.contentY = 0;
                        }
                        Keys.onPressed: event => {
                            const last = Math.max(0, root.filtered.length - 1);
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Right) {
                                root.selectedIndex = Math.min(root.selectedIndex + 1, last);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Left) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                root.selectedIndex = Math.min(root.selectedIndex + root.columns, last);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                root.selectedIndex = Math.max(0, root.selectedIndex - root.columns);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.filtered.length > 0)
                                    root.pick(root.filtered[root.selectedIndex].e);
                                event.accepted = true;
                            }
                        }
                    }
                }

                Flickable {
                    id: scroller
                    width: parent.width
                    height: Math.min(grid.implicitHeight + (emptyHint.visible ? 20 : 0), Math.max(48, win.maxCardHeight - Style.pad * 2 - 30 - 8))
                    contentWidth: width
                    contentHeight: grid.implicitHeight + (emptyHint.visible ? 20 : 0)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    interactive: contentHeight > height

                    Text {
                        id: emptyHint
                        visible: root.filtered.length === 0
                        color: Color.popupMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: "No emojis"
                    }

                    Grid {
                        id: grid
                        width: scroller.width
                        columns: root.columns
                        columnSpacing: 4
                        rowSpacing: 4

                        Repeater {
                            model: root.filtered

                            Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool selected: index === root.selectedIndex

                                width: (grid.width - 4 * (root.columns - 1)) / root.columns
                                height: root.cell
                                radius: Style.radius
                                color: selected ? Color.focusFill : Color.surface

                                Text {
                                    anchors.centerIn: parent
                                    font.family: "Noto Color Emoji"
                                    font.pixelSize: 20
                                    text: modelData.e
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.selectedIndex = index
                                    onClicked: root.pick(modelData.e)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
