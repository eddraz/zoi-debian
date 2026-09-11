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
    property int cursor: 0
    property bool capturing: false
    property bool conflictOpen: false
    property string captureId: ""
    property string statusLine: ""
    property string conflictKeys: ""
    property string conflictAction: ""
    property var pendingCombo: null

    function beginSearch() {
        if (capturing || conflictOpen)
            return;
        findOpen = true;
        Qt.callLater(() => searchField.forceActiveFocus());
    }

    function nextSection(back) {
        if (flatCount <= 0)
            return;
        cursor = back ? (cursor - 1 + flatCount) % flatCount : (cursor + 1) % flatCount;
    }

    function handleEscape() {
        if (conflictOpen) {
            cancelConflict();
            return true;
        }
        if (capturing) {
            capturing = false;
            captureId = "";
            statusLine = "";
            return true;
        }
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
            capturing = false;
            conflictOpen = false;
            statusLine = "";
            Popups.isSearching = false;
        }
    }

    readonly property var filteredSections: {
        KeysMap.revision;
        const needle = query.trim().toLowerCase();
        const out = [];
        let last = null;
        for (let i = 0; i < KeysMap.catalog.length; i++) {
            const action = KeysMap.catalog[i];
            const keys = KeysMap.displayKeys(action);
            if (needle) {
                const hay = (action.section + " " + action.label + " " + keys + " " + action.defaultKeys).toLowerCase();
                if (hay.indexOf(needle) < 0)
                    continue;
            }
            if (!last || last.title !== action.section) {
                last = { "title": action.section, "rows": [] };
                out.push(last);
            }
            last.rows.push(action);
        }
        return out;
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

    function actionAt(flat) {
        let n = 0;
        for (let s = 0; s < filteredSections.length; s++) {
            const rows = filteredSections[s].rows || [];
            for (let r = 0; r < rows.length; r++) {
                if (n === flat)
                    return rows[r];
                n++;
            }
        }
        return null;
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
                e.push({ "label": KeysMap.displayKeys(rows[r]) + " " + rows[r].label, "index": n });
                n++;
            }
        }
        return e;
    }

    function beginCapture(action) {
        if (!action)
            action = actionAt(cursor);
        if (!action)
            return;
        if (!action.command) {
            statusLine = "Ese atajo es de hardware / grupo y no se reasigna acá.";
            capturing = false;
            return;
        }
        capturing = true;
        captureId = action.id;
        conflictOpen = false;
        statusLine = "Oprimí el nuevo atajo para «" + action.label + "»  ·  Esc cancela";
    }

    function applyCombo(combo) {
        const result = KeysMap.assign(captureId, combo);
        if (result.ok) {
            capturing = false;
            captureId = "";
            statusLine = "";
            return;
        }
        if (result.reason === "conflict") {
            pendingCombo = combo;
            conflictKeys = formatCombo(combo);
            conflictAction = result.action.label;
            conflictOpen = true;
            capturing = false;
            statusLine = "";
            return;
        }
        capturing = false;
        statusLine = "No se puede reasignar.";
    }

    function formatCombo(combo) {
        if (!combo)
            return "—";
        const parts = [];
        if (combo.logo)
            parts.push("Super");
        if (combo.ctrl)
            parts.push("Ctrl");
        if (combo.alt)
            parts.push("Alt");
        if (combo.shift)
            parts.push("Shift");
        let key = combo.key || "";
        if (key === "slash")
            key = "/";
        else if (key === "period")
            key = ".";
        else if (key === "minus")
            key = "-";
        else if (key === "space")
            key = "Space";
        else if (key.length === 1)
            key = key.toUpperCase();
        parts.push(key);
        return parts.join("+");
    }

    function confirmReplace() {
        if (!conflictOpen || !pendingCombo || !captureId)
            return;
        KeysMap.replace(captureId, pendingCombo);
        conflictOpen = false;
        pendingCombo = null;
        captureId = "";
        statusLine = "";
    }

    function cancelConflict() {
        conflictOpen = false;
        pendingCombo = null;
        captureId = "";
        capturing = false;
        statusLine = "";
    }

    function handleKey(event) {
        if (conflictOpen) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.text === "y" || event.text === "Y") {
                confirmReplace();
                return true;
            }
            if (event.text === "n" || event.text === "N") {
                cancelConflict();
                return true;
            }
            return true;
        }
        if (capturing) {
            if (event.key === Qt.Key_Escape)
                return handleEscape();
            const combo = KeysMap.comboFromEvent(event);
            if (combo)
                applyCombo(combo);
            return true;
        }
        if (searchField.activeFocus)
            return false;
        const jump = KeyNav.jump(event, flatCount);
        if (jump >= 0) {
            cursor = jump;
            return true;
        }
        if (KeyNav.isNext(event) || KeyNav.isDown(event) || KeyNav.isRight(event)) {
            cursor = Math.min(Math.max(0, flatCount - 1), cursor + 1);
            return true;
        }
        if (KeyNav.isPrev(event) || KeyNav.isUp(event) || KeyNav.isLeft(event)) {
            cursor = Math.max(0, cursor - 1);
            return true;
        }
        if (KeyNav.isActivate(event)) {
            beginCapture();
            return true;
        }
        return false;
    }

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
                text: "Filtrar opciones..."
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
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.beginCapture();
                        event.accepted = true;
                    }
                }
            }
        }

        Text {
            visible: root.statusLine !== ""
            width: column.width
            wrapMode: Text.WordWrap
            color: root.capturing ? Color.accent : Color.popupMuted
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            text: root.statusLine
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
                        height: 42
                        radius: Style.radius
                        color: root.cursor === flat ? Color.focusFill : Color.surface
                        border.width: root.cursor === flat ? 1 : 0
                        border.color: Color.accent

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            IndexBadge {
                                anchors.verticalCenter: parent.verticalCenter
                                slot: flat
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 36
                                spacing: 2
                                Text {
                                    width: parent.width
                                    color: Color.accent
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontCaption
                                    font.bold: true
                                    text: KeysMap.displayKeys(modelData)
                                }
                                Text {
                                    width: parent.width
                                    color: Color.popupText
                                    font.family: Style.fontFamily
                                    font.pixelSize: Style.fontCaption
                                    text: modelData.label
                                }
                            }
                        }

                        HoverMouse {
                            onClicked: {
                                if (root.cursor === flat)
                                    root.beginCapture(modelData);
                                else
                                    root.cursor = flat;
                            }
                            onDoubleClicked: {
                                root.cursor = flat;
                                root.beginCapture(modelData);
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        visible: root.conflictOpen
        anchors.fill: parent
        color: Color.dimOverlay
        z: 20

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancelConflict()
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 16, 360)
            height: conflictCol.implicitHeight + 24
            radius: Style.cardRadius
            color: Color.popupBackground
            border.width: 1
            border.color: Color.urgent

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: conflictCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                Text {
                    width: parent.width
                    color: Color.urgent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontTitle
                    font.bold: true
                    text: "Este atajo ya existe"
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    text: root.conflictKeys + "  ejecuta:  " + root.conflictAction
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: "Reemplazar deja a «" + root.conflictAction + "» sin atajo."
                }

                Row {
                    spacing: 8
                    anchors.right: parent.right

                    Rectangle {
                        height: 32
                        width: 96
                        radius: Style.radius
                        color: Color.surface
                        border.width: 1
                        border.color: Color.subtleBorder

                        Text {
                            anchors.centerIn: parent
                            color: Color.popupText
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontCaption
                            text: "Cancelar"
                        }

                        HoverMouse {
                            onClicked: root.cancelConflict()
                        }
                    }

                    Rectangle {
                        height: 32
                        width: 110
                        radius: Style.radius
                        color: Color.urgent

                        Text {
                            anchors.centerIn: parent
                            color: Color.crust
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontCaption
                            font.bold: true
                            text: "Reemplazar"
                        }

                        HoverMouse {
                            onClicked: root.confirmReplace()
                        }
                    }
                }
            }
        }
    }
}
