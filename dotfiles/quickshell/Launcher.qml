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
    property var allApps: []

    readonly property int appCount: DesktopEntries.applications ? DesktopEntries.applications.values.length : 0

    onAppCountChanged: rebuildApps()

    function rebuildApps() {
        const values = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        const list = [];
        for (let i = 0; i < values.length; i++) {
            const entry = values[i];
            if (!entry || entry.noDisplay || !entry.name)
                continue;
            list.push(entry);
        }
        list.sort((a, b) => {
            const an = String(a.name).toLowerCase();
            const bn = String(b.name).toLowerCase();
            return an < bn ? -1 : (an > bn ? 1 : 0);
        });
        allApps = list;
    }

    readonly property var filtered: {
        const needle = query.trim().toLowerCase();
        const src = allApps;
        if (!needle)
            return src;
        const list = [];
        for (let i = 0; i < src.length; i++) {
            const entry = src[i];
            const name = String(entry.name || "").toLowerCase();
            const generic = String(entry.genericName || "").toLowerCase();
            const comment = String(entry.comment || "").toLowerCase();
            let keywords = "";
            const keys = entry.keywords || [];
            for (let k = 0; k < keys.length; k++)
                keywords += " " + String(keys[k]).toLowerCase();
            if (name.indexOf(needle) >= 0 || generic.indexOf(needle) >= 0 || comment.indexOf(needle) >= 0 || keywords.indexOf(needle) >= 0)
                list.push(entry);
        }
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
        if (!scroller || filtered.length === 0)
            return;
        scroller.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function open(): void {
        if (allApps.length === 0)
            rebuildApps();
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

    Component.onCompleted: Qt.callLater(rebuildApps)

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
        readonly property int listHeight: {
            const rows = Math.max(root.filtered.length, 1);
            const content = rows * (root.rowHeight + root.rowGap);
            return Math.min(content, Math.max(48, maxCardHeight - Style.pad * 2 - 30 - 8));
        }

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
                            if (scroller)
                                scroller.contentY = 0;
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                                if (root.filtered.length > 0)
                                    root.selectedIndex = (root.selectedIndex + 1) % root.filtered.length;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
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

                ListView {
                    id: scroller
                    width: parent.width
                    height: win.listHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    spacing: root.rowGap
                    reuseItems: true
                    model: root.filtered
                    currentIndex: root.selectedIndex

                    Text {
                        visible: root.filtered.length === 0
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        color: Color.popupMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: root.allApps.length === 0 ? "Cargando…" : "No apps"
                    }

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: scroller.width
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
