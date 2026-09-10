pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Commons"
import "Ui"

Scope {
    id: root

    property bool opened: false
    property string query: ""
    property int selectedIndex: 0
    property bool deleteFocused: false
    property bool confirmingClear: false
    property bool clearConfirmFocused: true   // true = Confirm, false = Cancelar
    property bool findOpen: false
    property var entries: []

    readonly property string pasteHelper: Quickshell.env("HOME") + "/.local/bin/qs-clip-paste"
    readonly property string deleteHelper: Quickshell.env("HOME") + "/.local/bin/qs-clip-delete"
    readonly property string wipeHelper: Quickshell.env("HOME") + "/.local/bin/qs-clip-wipe"

    readonly property var filtered: {
        if (!opened)
            return [];
        const needle = query.trim().toLowerCase();
        if (needle === "")
            return entries.slice(0, 50);
        const out = [];
        for (let i = 0; i < entries.length && out.length < 50; i++) {
            const item = entries[i];
            const title = String(item.title || "").toLowerCase();
            const sub = String(item.sub || "").toLowerCase();
            const preview = String(item.preview || "").toLowerCase();
            if (title.indexOf(needle) >= 0 || sub.indexOf(needle) >= 0 || preview.indexOf(needle) >= 0)
                out.push(item);
        }
        return out;
    }

    onFilteredChanged: {
        if (selectedIndex >= filtered.length)
            selectedIndex = Math.max(0, filtered.length - 1);
        deleteFocused = false;
    }

    onSelectedIndexChanged: deleteFocused = false
    onFindOpenChanged: Popups.isSearching = findOpen

    function parseList(raw) {
        const lines = String(raw || "").split("\n");
        const list = [];
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (!line)
                continue;
            const tab = line.indexOf("\t");
            const id = tab >= 0 ? line.slice(0, tab) : "";
            let preview = tab >= 0 ? line.slice(tab + 1) : line;

            const isBinary = preview.indexOf("[[ binary") === 0 || preview.indexOf("[binary") === 0;
            let isFile = false;
            let kind = "text";
            let displayTitle = preview;
            let displaySub = "";

            if (isBinary) {
                kind = "image";
                const clean = preview.replace(/^\[\[?\s*binary data\s*/, "").replace(/\s*\]\]?$/, "");
                displayTitle = "Imagen copiada";
                displaySub = clean || "Datos binarios";
            } else if (preview.indexOf("file://") === 0 || preview.indexOf("copy\nfile://") === 0) {
                kind = "file";
                isFile = true;
                let uri = preview.indexOf("copy\n") === 0 ? preview.slice(5) : preview;
                const firstLine = uri.split("\n")[0].trim();
                let path = firstLine.replace(/^file:\/\//, "");
                try {
                    path = decodeURIComponent(path);
                } catch (e) {}
                if (!path.startsWith("/"))
                    path = "/" + path;

                const lastSlash = path.lastIndexOf("/");
                const fileName = lastSlash >= 0 ? path.slice(lastSlash + 1) : path;
                displayTitle = fileName || path;
                displaySub = path;
            } else if (preview.startsWith("/") && preview.indexOf("\n") === -1 && preview.length < 256) {
                kind = "file";
                isFile = true;
                const lastSlash = preview.lastIndexOf("/");
                displayTitle = preview.slice(lastSlash + 1);
                displaySub = preview;
            } else {
                kind = "text";
                displayTitle = preview.replace(/\s+/g, " ");
                displaySub = "";
            }

            list.push({
                "line": line,
                "id": id,
                "kind": kind,
                "title": displayTitle,
                "sub": displaySub,
                "preview": preview,
                "isFile": isFile,
                "isImage": isBinary
            });
        }
        entries = list;
    }

    function open(): void {
        query = "";
        selectedIndex = 0;
        deleteFocused = false;
        confirmingClear = false;
        clearConfirmFocused = true;
        findOpen = false;
        opened = true;
        listProc.running = true;
        Qt.callLater(() => card.forceActiveFocus());
    }

    function beginSearch() {
        findOpen = true;
        Qt.callLater(() => searchField.forceActiveFocus());
    }

    function close(): void {
        opened = false;
        query = "";
        findOpen = false;
        Popups.isSearching = false;
        confirmingClear = false;
    }

    function toggle(): void {
        if (opened)
            close();
        else
            open();
    }

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

    function clearAll(): void {
        confirmingClear = false;
        wipeProc.running = true;
    }

    function handleKey(event): bool {
        if (event.key === Qt.Key_Escape) {
            if (root.confirmingClear) {
                root.confirmingClear = false;
                root.clearConfirmFocused = true;
            } else if (root.findOpen) {
                root.findOpen = false;
                root.query = "";
                card.forceActiveFocus();
            } else {
                root.close();
            }
            return true;
        }
        if (event.key === Qt.Key_Slash || event.text === "/") {
            if (!root.findOpen) {
                root.beginSearch();
                return true;
            }
            return false;
        }
        if (event.key === Qt.Key_0 && !root.findOpen) {
            if (root.entries.length > 0 && !root.confirmingClear) {
                root.confirmingClear = true;
                root.clearConfirmFocused = true;
                return true;
            }
            return false;
        }
        if (event.key === Qt.Key_L && (event.modifiers & Qt.ControlModifier)) {
            if (root.entries.length > 0 && !root.confirmingClear) {
                root.confirmingClear = true;
                root.clearConfirmFocused = true;
                return true;
            }
            return false;
        }
        if (root.confirmingClear) {
            if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                root.clearConfirmFocused = true;
                return true;
            }
            if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                root.clearConfirmFocused = false;
                return true;
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.clearConfirmFocused)
                    root.clearAll();
                else
                    root.confirmingClear = false;
                return true;
            }
            return false;
        }
        if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            root.selectedIndex = Math.min(root.selectedIndex + 1, Math.max(0, root.filtered.length - 1));
            return true;
        }
        if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            root.selectedIndex = Math.max(0, root.selectedIndex - 1);
            return true;
        }
        if (event.key === Qt.Key_PageDown) {
            root.selectedIndex = Math.min(root.selectedIndex + 5, Math.max(0, root.filtered.length - 1));
            return true;
        }
        if (event.key === Qt.Key_PageUp) {
            root.selectedIndex = Math.max(0, root.selectedIndex - 5);
            return true;
        }
        if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
            root.deleteFocused = true;
            return true;
        }
        if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
            root.deleteFocused = false;
            return true;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (root.filtered.length > 0) {
                if (root.deleteFocused)
                    root.remove(root.filtered[root.selectedIndex]);
                else
                    root.paste(root.filtered[root.selectedIndex]);
            }
            return true;
        }
        if (event.key === Qt.Key_Delete) {
            if (root.filtered.length > 0)
                root.remove(root.filtered[root.selectedIndex]);
            return true;
        }
        return false;
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

    Process {
        id: wipeProc
        command: [root.wipeHelper]
        onExited: {
            root.entries = [];
            root.selectedIndex = 0;
            listProc.running = true;
        }
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
        id: win
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

        Rectangle {
            anchors.fill: parent
            color: Color.dimOverlay
            opacity: root.opened ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Style.animSlow; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.opened ? 72 : 60
            width: 460
            focus: true
            Keys.onPressed: event => {
                if (!searchField.activeFocus)
                    event.accepted = root.handleKey(event);
            }
            implicitHeight: Math.min(column.implicitHeight + Style.pad * 2, (win.height > 200 ? win.height - 100 : 560))
            color: Color.popupBackground
            radius: Style.cardRadius
            border.width: 1
            border.color: Color.cardBorder
            clip: true

            opacity: root.opened ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Style.animSlow; easing.type: Easing.OutCubic } }
            Behavior on anchors.topMargin { NumberAnimation { duration: Style.animSlow; easing.type: Easing.OutCubic } }

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

                // Header
                Item {
                    width: parent.width
                    height: 26

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 14
                            radius: 1.5
                            color: Color.accent
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: Color.popupText
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontTitle
                            font.bold: true
                            text: "Portapapeles"
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 16
                            width: countLabel.implicitWidth + 10
                            radius: 3
                            color: Color.surface
                            border.width: 1
                            border.color: Color.subtleBorder

                            Text {
                                id: countLabel
                                anchors.centerIn: parent
                                color: Color.popupMuted
                                font.family: Style.fontFamily
                                font.pixelSize: 9
                                text: root.entries.length + (root.entries.length === 1 ? " elemento" : " elementos")
                            }
                        }
                    }

                    Rectangle {
                        id: searchBtn
                        anchors.right: clearBtn.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !root.findOpen
                        height: 18
                        width: searchHintRow.implicitWidth + 8
                        radius: 3
                        color: Color.surface
                        border.width: 1
                        border.color: Color.subtleBorder

                        Row {
                            id: searchHintRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                color: Color.popupMuted
                                font.family: Style.fontFamily
                                font.pixelSize: 9
                                text: "Buscar"
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                height: 12
                                width: 12
                                radius: 2
                                color: Color.mantle

                                Text {
                                    anchors.centerIn: parent
                                    color: Color.accent
                                    font.family: Style.fontFamily
                                    font.pixelSize: 8
                                    font.bold: true
                                    text: "/"
                                }
                            }
                        }

                        MouseArea {
                            id: searchBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.beginSearch()
                        }
                    }

                    Rectangle {
                        id: clearBtn
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.entries.length > 0 && !root.confirmingClear
                        height: 22
                        width: clearRow.implicitWidth + 14
                        radius: Style.radius
                        color: clearMouse.containsMouse ? Color.surface : "transparent"
                        border.width: 1
                        border.color: clearMouse.containsMouse ? Color.subtleBorder : "transparent"

                        Row {
                            id: clearRow
                            anchors.centerIn: parent
                            spacing: 5

                            IndexBadge {
                                slot: 9
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StatusIcon {
                                icon: "trash"
                                stroke: clearMouse.containsMouse ? Color.urgent : Color.popupMuted
                                width: 12
                                height: 12
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                color: clearMouse.containsMouse ? Color.urgent : Color.popupMuted
                                font.family: Style.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                text: "Vaciar historial"
                            }
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.clearConfirmFocused = true;
                                root.confirmingClear = true;
                            }
                        }
                    }
                }

                // Confirmation banner
                Rectangle {
                    visible: root.confirmingClear
                    width: parent.width
                    height: visible ? 34 : 0
                    radius: Style.radius
                    color: Color.surface
                    border.width: 1
                    border.color: Color.urgent

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 8

                        StatusIcon {
                            icon: "trash"
                            stroke: Color.urgent
                            width: 14
                            height: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: Color.popupText
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontCaption
                            font.bold: true
                            text: "¿Vaciar todo el historial?"
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 1
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 22
                            width: confLabel.implicitWidth + 14
                            radius: 3
                            color: Color.urgent
                            border.width: root.clearConfirmFocused ? 2 : 0
                            border.color: Color.foreground

                            Text {
                                id: confLabel
                                anchors.centerIn: parent
                                color: Color.crust
                                font.family: Style.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                text: "Confirmar"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.clearAll()
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 22
                            width: cancLabel.implicitWidth + 14
                            radius: 3
                            color: !root.clearConfirmFocused ? Color.focusFill : Color.mantle
                            border.width: !root.clearConfirmFocused ? 2 : 1
                            border.color: !root.clearConfirmFocused ? Color.accent : Color.subtleBorder

                            Text {
                                id: cancLabel
                                anchors.centerIn: parent
                                color: Color.popupMuted
                                font.family: Style.fontFamily
                                font.pixelSize: 9
                                text: "Cancelar"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.confirmingClear = false;
                                    root.clearConfirmFocused = true;
                                }
                            }
                        }
                    }
                }

                // Search Input Box (hidden until / like other panels)
                Rectangle {
                    visible: root.findOpen
                    width: parent.width
                    height: root.findOpen ? 32 : 0
                    radius: Style.radius
                    color: Color.crust
                    border.width: 1
                    border.color: searchField.activeFocus ? Color.accent : Color.subtleBorder

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        StatusIcon {
                            icon: "search"
                            stroke: searchField.activeFocus ? Color.accent : Color.popupMuted
                            width: 13
                            height: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 24 - (root.query !== "" ? 20 : 0)
                            height: parent.height

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.query === ""
                                color: Color.popupMuted
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontCaption
                                text: "Buscar en historial de portapapeles..."
                            }

                            TextInput {
                                id: searchField
                                anchors.fill: parent
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
                                        if (root.query !== "") {
                                            root.query = "";
                                        } else {
                                            root.findOpen = false;
                                            card.forceActiveFocus();
                                        }
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Down) {
                                        root.selectedIndex = Math.min(root.selectedIndex + 1, Math.max(0, root.filtered.length - 1));
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Up) {
                                        root.selectedIndex = Math.max(0, root.selectedIndex - 1);
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (root.filtered.length > 0) {
                                            root.paste(root.filtered[root.selectedIndex]);
                                        }
                                        event.accepted = true;
                                        return;
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.query !== ""
                            width: 16
                            height: 16
                            radius: 8
                            color: clearQueryMouse.containsMouse ? Color.surface : "transparent"

                            Text {
                                anchors.centerIn: parent
                                color: Color.popupMuted
                                font.family: Style.fontFamily
                                font.pixelSize: 11
                                text: "×"
                            }

                            MouseArea {
                                id: clearQueryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.query = "";
                                    searchField.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Empty state
                Rectangle {
                    visible: root.filtered.length === 0
                    width: parent.width
                    height: 72
                    radius: Style.radius
                    color: Color.crust
                    border.width: 1
                    border.color: Color.subtleBorder

                    Column {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: Color.popupMuted
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontCaption
                            font.bold: true
                            text: root.query === "" ? "El historial de portapapeles está vacío" : "Sin coincidencias"
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.query !== ""
                            color: Color.popupMuted
                            font.family: Style.fontFamily
                            font.pixelSize: 9
                            text: "No se encontraron elementos para \"" + root.query + "\""
                        }
                    }
                }

                // Scrollable ListView with max-height
                ListView {
                    id: listView
                    visible: root.filtered.length > 0
                    width: parent.width
                    height: Math.min(contentHeight, 380)
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 4
                    model: root.filtered
                    currentIndex: root.selectedIndex
                    onCurrentIndexChanged: listView.positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Rectangle {
                        id: itemRow
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === root.selectedIndex
                        readonly property bool isDeleteActive: isSelected && root.deleteFocused

                        width: listView.width
                        height: 42
                        radius: Style.radius
                        color: isSelected
                               ? (isDeleteActive ? Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.15) : Color.focusFill)
                               : (rowMouse.containsMouse ? Color.surface : Color.crust)
                        border.width: 1
                        border.color: isSelected
                                      ? (isDeleteActive ? Color.urgent : Color.accent)
                                      : (rowMouse.containsMouse ? Color.subtleBorder : "transparent")

                        // Left vertical accent bar
                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: isSelected && !isDeleteActive ? 3 : 0
                            height: 24
                            radius: 1.5
                            color: Color.accent
                            Behavior on width { NumberAnimation { duration: Style.animFast } }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            spacing: 8

                            // Index / Type Badge
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: modelData.isImage || modelData.isFile ? 32 : 20
                                height: 20
                                radius: 3
                                color: modelData.isImage
                                       ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.2)
                                       : (modelData.isFile ? Qt.rgba(Color.barText.r, Color.barText.g, Color.barText.b, 0.15) : Color.surface)
                                border.width: 1
                                border.color: modelData.isImage ? Color.accent : Color.subtleBorder

                                Text {
                                    anchors.centerIn: parent
                                    color: modelData.isImage ? Color.accent : (isSelected ? Color.popupText : Color.popupMuted)
                                    font.family: Style.fontFamily
                                    font.pixelSize: 8
                                    font.bold: true
                                    text: modelData.isImage ? "IMG" : (modelData.isFile ? "DOC" : String(index + 1))
                                }
                            }

                            // Texts (Title + Subtitle)
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - (modelData.isImage || modelData.isFile ? 32 : 20) - 8 - 32 - 6
                                spacing: 1

                                Text {
                                    width: parent.width
                                    elide: Text.ElideRight
                                    color: Color.popupText
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontCaption
                                    font.bold: isSelected
                                    text: modelData.title
                                }

                                Text {
                                    visible: modelData.sub !== ""
                                    width: parent.width
                                    elide: Text.ElideMiddle
                                    color: isSelected ? Color.popupText : Color.popupMuted
                                    font.family: Style.fontFamily
                                    font.pixelSize: 9
                                    text: modelData.sub
                                }
                            }

                            // Delete button with StatusIcon trash
                            Rectangle {
                                id: delBtn
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28
                                height: 28
                                radius: Style.radius
                                color: isDeleteActive
                                       ? Color.urgent
                                       : (delMouse.containsMouse ? Qt.rgba(Color.urgent.r, Color.urgent.g, Color.urgent.b, 0.2) : "transparent")
                                border.width: (delMouse.containsMouse || isDeleteActive) ? 1 : 0
                                border.color: Color.urgent

                                StatusIcon {
                                    anchors.centerIn: parent
                                    icon: "trash"
                                    width: 13
                                    height: 13
                                    stroke: isDeleteActive
                                            ? Color.crust
                                            : (delMouse.containsMouse ? Color.urgent : Color.popupMuted)
                                }

                                MouseArea {
                                    id: delMouse
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

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            anchors.rightMargin: 34
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                root.selectedIndex = index;
                                root.deleteFocused = false;
                            }
                            onClicked: root.paste(modelData)
                        }
                    }
                }

                // Footer divider
                Rectangle {
                    width: parent.width
                    height: 1
                    color: Color.surface
                    opacity: 0.5
                }

                // Footer hints
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    opacity: 0.75

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "↑↓"; font.pixelSize: 9; color: Color.accent; font.bold: true }
                        Text { text: "navegar"; font.family: Style.fontFamily; font.pixelSize: 9; color: Color.popupMuted }
                    }

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "↵"; font.pixelSize: 9; color: Color.accent; font.bold: true }
                        Text { text: "pegar"; font.family: Style.fontFamily; font.pixelSize: 9; color: Color.popupMuted }
                    }

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "→ / del"; font.pixelSize: 9; color: Color.urgent; font.bold: true }
                        Text { text: "eliminar"; font.family: Style.fontFamily; font.pixelSize: 9; color: Color.popupMuted }
                    }

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "0"; font.pixelSize: 9; color: Color.urgent; font.bold: true }
                        Text { text: "vaciar"; font.family: Style.fontFamily; font.pixelSize: 9; color: Color.popupMuted }
                    }

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "esc"; font.pixelSize: 8; color: Color.accent; font.bold: true }
                        Text { text: "cerrar"; font.family: Style.fontFamily; font.pixelSize: 9; color: Color.popupMuted }
                    }
                }
            }
        }
    }
}

