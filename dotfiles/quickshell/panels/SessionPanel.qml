pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 6
    width: parent ? parent.width : 252

    property string pendingId: ""
    property int cursor: 0
    property int confirmChoice: 1

    readonly property var actions: [
        { "id": "lock", "label": "Bloquear Pantalla", "desc": "Bloquea la sesión y suspende el monitor", "status": "Bloquear", "command": ["/usr/bin/qs", "ipc", "call", "lock", "lock"], "confirm": false },
        { "id": "suspend", "label": "Suspender", "desc": "Pone el equipo en bajo consumo RAM", "status": "Dormir", "command": ["systemctl", "suspend"], "confirm": false },
        { "id": "logout", "label": "Cerrar Sesión", "desc": "Finaliza la sesión actual de Sway", "status": "Salir", "command": ["swaymsg", "exit"], "confirm": true },
        { "id": "reboot", "label": "Reiniciar", "desc": "Reinicia el sistema operativo", "status": "Reiniciar", "command": ["systemctl", "reboot"], "confirm": true },
        { "id": "shutdown", "label": "Apagar Equipo", "desc": "Apaga el sistema de forma segura", "status": "Apagar", "command": ["systemctl", "poweroff"], "confirm": true }
    ]

    readonly property int count: actions.length

    onVisibleChanged: {
        if (visible) {
            cursor = 0;
            pendingId = "";
            confirmChoice = 1;
        } else {
            pendingId = "";
        }
    }

    function run(command) {
        Quickshell.execDetached(command);
        pendingId = "";
    }

    function activate() {
        if (cursor < 0 || cursor >= actions.length)
            return;
        const action = actions[cursor];
        if (action.confirm)
            pendingId = pendingId === action.id ? "" : action.id;
        else
            run(action.command);
    }

    function handleEscape() {
        if (pendingId !== "") {
            pendingId = "";
            return true;
        }
        return false;
    }

    function nextSection(back) {
        if (pendingId !== "") {
            confirmChoice = confirmChoice === 1 ? 0 : 1;
            return;
        }
        if (count <= 0) return;
        cursor = back ? (cursor - 1 + count) % count : (cursor + 1) % count;
    }

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: {
        const e = [];
        for (let i = 0; i < actions.length; i++)
            e.push({ "label": String(actions[i].label + " " + actions[i].desc), "index": i });
        return e;
    }

    function handleKey(event) {
        if (pendingId !== "") {
            if (KeyNav.isLeft(event) || KeyNav.isPrev(event)) {
                confirmChoice = 0;
                return true;
            }
            if (KeyNav.isRight(event) || KeyNav.isNext(event)) {
                confirmChoice = 1;
                return true;
            }
            if (KeyNav.isActivate(event)) {
                if (confirmChoice === 1)
                    run(actions[cursor].command);
                else
                    pendingId = "";
                return true;
            }
            return false;
        }
        const jump = KeyNav.jump(event, count);
        if (jump >= 0) {
            cursor = jump;
            if (actions[jump].confirm)
                pendingId = actions[jump].id;
            else
                run(actions[jump].command);
            return true;
        }
        if (KeyNav.isNext(event) || KeyNav.isRight(event)) {
            cursor = Math.min(cursor + 1, count - 1);
            return true;
        }
        if (KeyNav.isPrev(event) || KeyNav.isLeft(event)) {
            cursor = Math.max(cursor - 1, 0);
            return true;
        }
        if (KeyNav.isActivate(event)) {
            activate();
            return true;
        }
        return false;
    }

    Repeater {
        model: root.actions

        Column {
            required property var modelData
            required property int index
            width: root.width
            spacing: 4

            readonly property bool selected: root.cursor === index

            Rectangle {
                width: parent.width
                height: 42
                radius: Style.radius
                color: {
                    if (modelData.id === "shutdown" && selected)
                        return Color.urgent;
                    if (selected)
                        return Color.focusFill;
                    if (modelData.id === "shutdown")
                        return Color.surface;
                    return Color.surface;
                }
                border.width: selected ? 1 : 0
                border.color: modelData.id === "shutdown" ? (selected ? Color.foreground : Color.urgent) : Color.accent
                Behavior on color { ColorAnimation { duration: Style.animDuration } }
                Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

                Rectangle {
                    width: 3
                    height: selected ? 20 : 0
                    radius: 1.5
                    color: modelData.id === "shutdown" ? Color.background : Color.accent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: selected
                    Behavior on height { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic } }
                }

                IndexBadge {
                    slot: index
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 32
                    anchors.right: statusBadge.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        color: modelData.id === "shutdown" && selected ? Color.background : Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontBody
                        font.bold: true
                        text: modelData.label
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        color: modelData.id === "shutdown" && selected ? Color.background : Color.popupMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: modelData.desc
                    }
                }

                Rectangle {
                    id: statusBadge
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    height: 20
                    width: badgeText.implicitWidth + 12
                    radius: 4
                    color: selected ? (modelData.id === "shutdown" ? Color.background : Color.surface) : Color.background
                    border.width: 1
                    border.color: selected ? (modelData.id === "shutdown" ? Color.background : Color.subtleBorder) : "transparent"

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption - 1
                        font.bold: true
                        color: modelData.id === "shutdown" && selected ? Color.urgent : Color.popupMuted
                        text: modelData.status
                    }
                }

                HoverMouse {
                    onClicked: {
                        root.cursor = index;
                        if (modelData.confirm)
                            root.pendingId = root.pendingId === modelData.id ? "" : modelData.id;
                        else
                            root.run(modelData.command);
                    }
                }
            }

            Row {
                visible: root.pendingId === modelData.id
                spacing: 6
                width: parent.width

                Rectangle {
                    width: (parent.width - 6) / 2
                    height: 26
                    radius: Style.radius
                    color: root.confirmChoice === 0 ? Color.focusFill : Color.surface
                    border.width: 1
                    border.color: root.confirmChoice === 0 ? Color.accent : "transparent"
                    Behavior on color { ColorAnimation { duration: Style.animDuration } }
                    Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

                    Text {
                        anchors.centerIn: parent
                        color: Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        font.bold: root.confirmChoice === 0
                        text: "Cancel"
                    }

                    HoverMouse {
                        onClicked: root.pendingId = ""
                    }
                }

                Rectangle {
                    width: (parent.width - 6) / 2
                    height: 26
                    radius: Style.radius
                    color: Color.urgent
                    border.width: root.confirmChoice === 1 ? 2 : 0
                    border.color: Color.foreground
                    Behavior on color { ColorAnimation { duration: Style.animDuration } }

                    Text {
                        anchors.centerIn: parent
                        color: Color.background
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        font.bold: true
                        text: "Confirm"
                    }

                    HoverMouse {
                        onClicked: root.run(modelData.command)
                    }
                }
            }
        }
    }
}
