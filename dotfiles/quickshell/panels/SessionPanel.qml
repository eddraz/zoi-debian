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
        { "id": "lock", "label": "Lock", "command": ["/usr/bin/qs", "ipc", "call", "lock", "lock"], "confirm": false },
        { "id": "suspend", "label": "Suspend", "command": ["systemctl", "suspend"], "confirm": false },
        { "id": "logout", "label": "Log out", "command": ["swaymsg", "exit"], "confirm": true },
        { "id": "reboot", "label": "Reboot", "command": ["systemctl", "reboot"], "confirm": true },
        { "id": "shutdown", "label": "Shut down", "command": ["systemctl", "poweroff"], "confirm": true }
    ]

    readonly property int count: 5 + actions.length

    signal openKeys
    signal openBar
    signal openTheme

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
        if (cursor === 0) {
            openKeys();
            return;
        }
        if (cursor === 1) {
            openBar();
            return;
        }
        if (cursor === 2) {
            Idle.toggle();
            return;
        }
        if (cursor === 3) {
            NightLight.toggle();
            return;
        }
        if (cursor === 4) {
            openTheme();
            return;
        }
        const action = actions[cursor - 5];
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
        cursor = KeyNav.nextStart([0, 5], cursor, back);
    }

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: {
        const e = [
            { "label": "shortcuts", "index": 0 },
            { "label": "bar", "index": 1 },
            { "label": "stay awake", "index": 2 },
            { "label": "night light", "index": 3 },
            { "label": "theme", "index": 4 }
        ];
        for (let i = 0; i < actions.length; i++)
            e.push({ "label": String(actions[i].label || actions[i].id), "index": 5 + i });
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
                    run(actions[cursor - 5].command);
                else
                    pendingId = "";
                return true;
            }
            return false;
        }
        const jump = KeyNav.jump(event, count);
        if (jump >= 0) {
            cursor = jump;
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

    Rectangle {
        width: parent.width
        height: 28
        radius: Style.radius
        color: root.cursor === 0 ? Color.focusFill : Color.surface
        border.width: 1
        border.color: root.cursor === 0 ? Color.accent : "transparent"
        Behavior on color { ColorAnimation { duration: Style.animDuration } }
        Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

        Rectangle {
            width: 3
            height: parent.height - 10
            radius: 1.5
            color: Color.accent
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: root.cursor === 0
        }

        IndexBadge {
            slot: 0
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            font.bold: root.cursor === 0
            elide: Text.ElideRight
            text: "Shortcuts"
        }

        HoverMouse {
            onClicked: {
                root.cursor = 0;
                root.openKeys();
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 28
        radius: Style.radius
        color: root.cursor === 1 ? Color.focusFill : Color.surface
        border.width: 1
        border.color: root.cursor === 1 ? Color.accent : "transparent"
        Behavior on color { ColorAnimation { duration: Style.animDuration } }
        Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

        Rectangle {
            width: 3
            height: parent.height - 10
            radius: 1.5
            color: Color.accent
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: root.cursor === 1
        }

        IndexBadge {
            slot: 1
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            font.bold: root.cursor === 1
            elide: Text.ElideRight
            text: "Bar"
        }

        HoverMouse {
            onClicked: {
                root.cursor = 1;
                root.openBar();
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 28
        radius: Style.radius
        color: root.cursor === 2 ? Color.focusFill : Color.surface
        border.width: 1
        border.color: root.cursor === 2 ? Color.accent : "transparent"
        Behavior on color { ColorAnimation { duration: Style.animDuration } }
        Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

        Rectangle {
            width: 3
            height: parent.height - 10
            radius: 1.5
            color: Color.accent
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: root.cursor === 2
        }

        IndexBadge {
            slot: 2
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            font.bold: root.cursor === 2
            elide: Text.ElideRight
            text: (Idle.stayAwake ? "Stay awake on" : "Stay awake off")
        }

        HoverMouse {
            onClicked: {
                root.cursor = 2;
                Idle.toggle();
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 28
        radius: Style.radius
        color: root.cursor === 3 ? Color.focusFill : Color.surface
        border.width: 1
        border.color: root.cursor === 3 ? Color.accent : "transparent"
        Behavior on color { ColorAnimation { duration: Style.animDuration } }
        Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

        Rectangle {
            width: 3
            height: parent.height - 10
            radius: 1.5
            color: Color.accent
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: root.cursor === 3
        }

        IndexBadge {
            slot: 3
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            font.bold: root.cursor === 3
            elide: Text.ElideRight
            text: (NightLight.enabled ? "Night light on" : "Night light off")
        }

        HoverMouse {
            onClicked: {
                root.cursor = 3;
                NightLight.toggle();
            }
        }
    }

    Rectangle {
        width: parent.width
        height: 28
        radius: Style.radius
        color: root.cursor === 4 ? Color.focusFill : Color.surface
        border.width: 1
        border.color: root.cursor === 4 ? Color.accent : "transparent"
        Behavior on color { ColorAnimation { duration: Style.animDuration } }
        Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

        Rectangle {
            width: 3
            height: parent.height - 10
            radius: 1.5
            color: Color.accent
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: root.cursor === 4
        }

        IndexBadge {
            slot: 4
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            font.bold: root.cursor === 4
            elide: Text.ElideRight
            text: "Theme"
        }

        HoverMouse {
            onClicked: {
                root.cursor = 4;
                root.openTheme();
            }
        }
    }

    Repeater {
        model: root.actions

        Column {
            required property var modelData
            required property int index
            width: root.width
            spacing: 4

            readonly property bool selected: root.cursor === index + 5

            Rectangle {
                width: parent.width
                height: 28
                radius: Style.radius
                color: {
                    if (modelData.id === "shutdown" && selected)
                        return Color.urgent;
                    if (selected)
                        return Color.focusFill;
                    if (modelData.id === "shutdown")
                        return Color.urgent;
                    return Color.surface;
                }
                border.width: 1
                border.color: selected ? (modelData.id === "shutdown" ? Color.urgent : Color.accent) : "transparent"
                Behavior on color { ColorAnimation { duration: Style.animDuration } }
                Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

                Rectangle {
                    width: 3
                    height: parent.height - 10
                    radius: 1.5
                    color: modelData.id === "shutdown" ? Color.background : Color.accent
                    anchors.left: parent.left
                    anchors.leftMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    visible: selected
                }

                IndexBadge {
                    slot: index + 5
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 28
                    anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    color: modelData.id === "shutdown" ? Color.background : Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    font.bold: selected
                    elide: Text.ElideRight
                    text: modelData.label
                }

                HoverMouse {
                    onClicked: {
                        root.cursor = index + 5;
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
