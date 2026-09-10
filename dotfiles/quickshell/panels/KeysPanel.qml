pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    width: parent ? parent.width : 404
    implicitHeight: column.implicitHeight
    property string query: ""
    property bool findOpen: false

    function beginSearch() {
        findOpen = true;
        Qt.callLater(() => searchField.forceActiveFocus());
    }

    property int cursor: 0

    function nextSection(back) {
        if (flatCount <= 0) return;
        cursor = back ? (cursor - 1 + flatCount) % flatCount : (cursor + 1) % flatCount;
    }

    function handleEscape() {
        if (findOpen || query !== "") {
            findOpen = false;
            query = "";
            return true;
        }
        return false;
    }

    onFindOpenChanged: Popups.isSearching = findOpen

    onVisibleChanged: {
        if (visible) {
            query = "";
            findOpen = false;
            cursor = 0;
            Popups.isSearching = false;
        }
    }

    readonly property int flatCount: {
        let n = 0;
        for (let s = 0; s < filteredSections.length; s++)
            n += (filteredSections[s].rows || []).length;
        return n;
    }

    function flatIndex(sectionIdx, rowIdx) {
        let n = 0;
        for (let s = 0; s < sectionIdx; s++)
            n += (filteredSections[s].rows || []).length;
        return n + rowIdx;
    }

    function focusItem(entry) {
        cursor = Math.max(0, Math.min(Math.max(0, flatCount - 1), entry.index));
    }

    readonly property var searchEntries: {
        const e = [];
        let n = 0;
        for (let s = 0; s < filteredSections.length; s++) {
            const rows = filteredSections[s].rows || [];
            for (let r = 0; r < rows.length; r++) {
                e.push({ "label": String(rows[r].keys || "") + " " + String(rows[r].action || ""), "index": n });
                n++;
            }
        }
        return e;
    }

    function handleKey(event) {
        if (searchField.activeFocus)
            return false;
        const jump = KeyNav.jump(event, flatCount);
        if (jump >= 0) {
            cursor = jump;
            return true;
        }
        if (KeyNav.isNext(event) || KeyNav.isDown(event)) {
            cursor = Math.min(Math.max(0, flatCount - 1), cursor + 1);
            return true;
        }
        if (KeyNav.isPrev(event) || KeyNav.isUp(event)) {
            cursor = Math.max(0, cursor - 1);
            return true;
        }
        return false;
    }

    readonly property var filteredSections: {
        const needle = query.trim().toLowerCase();
        const out = [];
        for (let s = 0; s < sections.length; s++) {
            const section = sections[s];
            const rows = [];
            const src = section.rows || [];
            for (let r = 0; r < src.length; r++) {
                const row = src[r];
                if (!needle) {
                    rows.push(row);
                    continue;
                }
                const keys = String(row.keys || "").toLowerCase();
                const action = String(row.action || "").toLowerCase();
                const title = String(section.title || "").toLowerCase();
                if (keys.indexOf(needle) >= 0 || action.indexOf(needle) >= 0 || title.indexOf(needle) >= 0)
                    rows.push(row);
            }
            if (rows.length > 0)
                out.push({ "title": section.title, "rows": rows });
        }
        return out;
    }

    readonly property var sections: [
        {
            "title": "Apps",
            "rows": [
                { "keys": "Super+Return", "action": "Terminal" },
                { "keys": "Super+Shift+Return", "action": "LibreWolf" },
                { "keys": "Super+Space", "action": "App launcher" },
                { "keys": "Super+A", "action": "Native Apps panel" },
                { "keys": "Super+V", "action": "Clipboard history" },
                { "keys": "Super+.", "action": "Emoji picker (latam: Super+Shift+,)" },
                { "keys": "Alt+Shift / LATAM chip", "action": "Cycle keyboard layout" },
                { "keys": "Super+Shift+W", "action": "Close window" },
                { "keys": "Super+Shift+C", "action": "Reload Sway" },
                { "keys": "Super+Shift+E", "action": "Exit Sway" },
                { "keys": "Super+Escape", "action": "Session menu" },
                { "keys": "Stay awake", "action": "Apps: inhibit idle/lock" },
                { "keys": "Screensaver", "action": "TTE ZOI after 2.5 min idle" },
                { "keys": "Night light", "action": "Apps: warm display 4000K" },
                { "keys": "pkexec", "action": "Polkit: themed password dialog" },
                { "keys": "Theme", "action": "Apps: colors, wallpaper, screensaver text" }
            ]
        },
        {
            "title": "Focus & move",
            "rows": [
                { "keys": "Super+H J K L", "action": "Focus (vim)" },
                { "keys": "Super+Arrows", "action": "Focus" },
                { "keys": "Super+Shift+H J K L", "action": "Move window" },
                { "keys": "Super+Shift+Arrows", "action": "Move window" },
                { "keys": "Super+Shift+A", "action": "Focus parent" },
                { "keys": "Super+D", "action": "Focus tiling/floating" },
                { "keys": "Super+Shift+Space", "action": "Toggle floating" }
            ]
        },
        {
            "title": "Workspaces",
            "rows": [
                { "keys": "Super+1 … 0", "action": "Workspace 1–10" },
                { "keys": "Super+Tab", "action": "Next workspace" },
                { "keys": "Super+Shift+Tab", "action": "Previous workspace" },
                { "keys": "Super+Shift+1 … 0", "action": "Move to workspace" }
            ]
        },
        {
            "title": "Layout",
            "rows": [
                { "keys": "Super+B", "action": "Split horizontal" },
                { "keys": "Super+Ctrl+V", "action": "Split vertical" },
                { "keys": "Super+E", "action": "Toggle split" },
                { "keys": "Super+S", "action": "Stacking" },
                    { "keys": "Super+W", "action": "Tabbed" },
                                { "keys": "Super+F", "action": "Fullscreen" },
                { "keys": "Super+R", "action": "Resize mode" },
                { "keys": "H J K L / Arrows", "action": "Resize (in mode)" },
                { "keys": "Enter / Esc", "action": "Leave resize" }
            ]
        },
        {
            "title": "Scratchpad",
            "rows": [
                { "keys": "Super+Shift+-", "action": "Send to scratchpad" },
                { "keys": "Super+-", "action": "Show scratchpad" }
            ]
        },
        {
            "title": "Bar panels",
            "rows": [
                { "keys": "Super+A", "action": "Native Apps" },
                { "keys": "Super+C", "action": "Calendar" },
                { "keys": "Super+T", "action": "Weather" },
                { "keys": "Super+N", "action": "Notifications" },
                { "keys": "Right-click bell / DND chip", "action": "Do not disturb" },
                { "keys": "Super+Shift+N", "action": "Reminder" },
                { "keys": "Super+M", "action": "Audio / volume" },
                { "keys": "Super+Ctrl+R", "action": "Reproductor / Media" },
                { "keys": "Super+P", "action": "Power / battery" },
                { "keys": "Super+I", "action": "Network / Wi-Fi" },
                { "keys": "Super+U", "action": "Bluetooth" },
                { "keys": "Super+Escape", "action": "Session" },
                { "keys": "Super+Q", "action": "Close panel" }
            ]
        },
        {
            "title": "System",
            "rows": [
                { "keys": "Volume keys", "action": "Mute / volume" },
                { "keys": "Media keys", "action": "Play / prev / next (MPRIS)" },
                { "keys": "Super+Shift+R", "action": "Lofi Radio: Play / Stop" },
                { "keys": "Super+Ctrl+R (1 2 3)", "action": "Reproductor: prev / play / next" },
                                                                { "keys": "Brightness keys", "action": "Brightness + OSD" },
                { "keys": "Print / Super+Shift+S", "action": "Screenshot region" },
                { "keys": "Alt+Print", "action": "Start/stop recording" },
                { "keys": "Super + drag", "action": "Move floating" },
                { "keys": "Super+Q", "action": "Close panel" },
                { "keys": "H J K L / Arrows", "action": "Navigate panels" },
                { "keys": "Enter / Space", "action": "Activate option" }
            ]
        }
    ]

    Column {
        id: column
        width: root.width
        spacing: 10

        Rectangle {
            visible: root.findOpen
            width: parent.width
            height: root.findOpen ? 30 : 0
            radius: Style.radius
            color: Color.surface
            border.width: 1
            border.color: searchField.activeFocus ? Color.accent : Color.overlay

            Text {
                anchors.fill: parent
                anchors.leftMargin: 10
                verticalAlignment: Text.AlignVCenter
                visible: searchField.text === ""
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: "Search shortcuts"
            }

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
                onTextChanged: root.query = text
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.findOpen = false;
                        root.query = "";
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Down) {
                        root.cursor = Math.min(Math.max(0, root.flatCount - 1), root.cursor + 1);
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Up) {
                        root.cursor = Math.max(0, root.cursor - 1);
                        event.accepted = true;
                        return;
                    }
                }
            }
        }

        Repeater {
            model: root.filteredSections

            Column {
                required property var modelData
                required property int index
                readonly property int sectionIdx: index
                width: column.width
                spacing: 4

                Text {
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    font.bold: true
                    text: modelData.title
                }

                Repeater {
                    model: modelData.rows

                    Rectangle {
                        required property var modelData
                        required property int index
                        readonly property int flat: root.flatIndex(sectionIdx, index)
                        width: column.width
                        height: Math.max(keysText.implicitHeight, actionText.implicitHeight) + 6
                        radius: Style.radius
                        color: root.cursor === flat ? Color.focusFill : "transparent"
                        border.width: root.cursor === flat ? 1 : 0
                        border.color: Color.accent

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 8

                            Text {
                                id: keysText
                                anchors.verticalCenter: parent.verticalCenter
                                width: (column.width - 12) * 0.48
                                color: Color.accent
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontCaption
                                text: modelData.keys
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                id: actionText
                                anchors.verticalCenter: parent.verticalCenter
                                width: (column.width - 12) * 0.48
                                color: Color.popupText
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontCaption
                                text: modelData.action
                                wrapMode: Text.WordWrap
                            }
                        }

                        HoverMouse {
                            z: -1
                            onClicked: root.cursor = flat
                        }
                    }
                }
            }
        }
    }
}
