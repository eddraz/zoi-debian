pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "Commons"

Scope {
    id: root

    property bool opened: false
    property string query: ""
    property int selectedIndex: 0

    readonly property var filtered: {
        if (!opened)
            return [];
        const needle = query.trim().toLowerCase();
        const values = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        const list = [];
        for (let i = 0; i < values.length; i++) {
            const entry = values[i];
            if (!entry || entry.noDisplay || !entry.name)
                continue;
            if (needle !== "") {
                const name = String(entry.name).toLowerCase();
                const generic = String(entry.genericName || "").toLowerCase();
                const comment = String(entry.comment || "").toLowerCase();
                let keywords = "";
                const keys = entry.keywords || [];
                for (let k = 0; k < keys.length; k++)
                    keywords += " " + String(keys[k]).toLowerCase();
                if (name.indexOf(needle) < 0 && generic.indexOf(needle) < 0 && comment.indexOf(needle) < 0 && keywords.indexOf(needle) < 0)
                    continue;
            }
            list.push(entry);
        }
        list.sort((a, b) => {
            const an = String(a.name).toLowerCase();
            const bn = String(b.name).toLowerCase();
            return an < bn ? -1 : (an > bn ? 1 : 0);
        });
        return list;
    }

    readonly property int rowHeight: 32
    readonly property int rowGap: 4

    onFilteredChanged: {
        if (selectedIndex >= filtered.length)
            selectedIndex = Math.max(0, filtered.length - 1);
        Qt.callLater(ensureVisible);
    }

    onSelectedIndexChanged: ensureVisible()

    function ensureVisible() {
        if (!scroller)
            return;
        const y = selectedIndex * (rowHeight + rowGap);
        if (y < scroller.contentY)
            scroller.contentY = y;
        else if (y + rowHeight > scroller.contentY + scroller.height)
            scroller.contentY = Math.max(0, y + rowHeight - scroller.height);
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

    Connections {
        target: Popups
        function onClosed() {
            root.close();
        }
    }

    function toggle(): void {
        if (opened)
            close();
        else
            open();
    }

    function launch(entry): void {
        if (!entry)
            return;
        entry.execute();
        close();
    }

    IpcHandler {
        target: "launcher"

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
        id: win
        visible: root.opened
        color: "transparent"
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-launcher"
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
                            scroller.contentY = 0;
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                                if (root.filtered.length > 0)
                                    root.selectedIndex = (root.selectedIndex + 1) % root.filtered.length;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                                if (root.filtered.length > 0)
                                    root.selectedIndex = (root.selectedIndex - 1 + root.filtered.length) % root.filtered.length;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.filtered.length > 0)
                                    root.launch(root.filtered[root.selectedIndex]);
                                event.accepted = true;
                            }
                        }
                    }
                }

                Flickable {
                    id: scroller
                    width: parent.width
                    height: Math.min(listColumn.implicitHeight, Math.max(48, win.maxCardHeight - Style.pad * 2 - 30 - 8))
                    contentWidth: width
                    contentHeight: listColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    interactive: contentHeight > height

                    Column {
                        id: listColumn
                        width: scroller.width
                        spacing: root.rowGap

                        Text {
                            visible: root.filtered.length === 0
                            color: Color.popupMuted
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontCaption
                            text: "No apps"
                        }

                        Repeater {
                            model: root.filtered

                            Rectangle {
                                required property var modelData
                                required property int index

                                width: listColumn.width
                                height: root.rowHeight
                                radius: Style.radius
                                color: index === root.selectedIndex ? Color.focusFill : Color.surface

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    IconImage {
                                        anchors.verticalCenter: parent.verticalCenter
                                        implicitSize: 20
                                        source: modelData.icon ? Quickshell.iconPath(modelData.icon) : ""
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 36
                                        elide: Text.ElideRight
                                        color: Color.popupText
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.fontCaption
                                        text: modelData.name
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.selectedIndex = index
                                    onClicked: root.launch(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
