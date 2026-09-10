pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 6
    width: parent ? parent.width : 280
    property int cursor: 0

    signal openBar
    signal openKeys

    readonly property var items: [
        {
            "id": "lofi",
            "name": "Lofi Radio",
            "desc": Radio.playing ? "Reproduciendo stream en vivo" : "Música relajante de fondo",
            "status": Radio.playing ? "ON" : "OFF",
            "active": Radio.playing
        },
        {
            "id": "clipboard",
            "name": "Portapapeles",
            "desc": "Historial de texto y recortes",
            "status": "Super+V",
            "active": false
        },
        {
            "id": "bar",
            "name": "Plugin Registry",
            "desc": "Organizar barra y widgets",
            "status": "Super+Shift+B",
            "active": false
        },
        {
            "id": "emojis",
            "name": "Selector de Emojis",
            "desc": "Buscar y pegar emojis",
            "status": "Super+.",
            "active": false
        },
        {
            "id": "keys",
            "name": "Atajos de Teclado",
            "desc": "Guía rápida de combinaciones",
            "status": "Super+/",
            "active": false
        }
    ]

    readonly property int count: items.length

    onVisibleChanged: if (visible) cursor = 0

    function nextSection(back) {
        cursor = KeyNav.nextStart([0], cursor, back);
    }

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: {
        const e = [];
        for (let i = 0; i < items.length; i++) {
            const it = items[i];
            e.push({ "label": it.name + " " + it.desc, "index": i });
        }
        return e;
    }

    function runItem(index) {
        if (index < 0 || index >= items.length)
            return;
        const it = items[index];
        if (it.id === "lofi") {
            Radio.toggle();
        } else if (it.id === "clipboard") {
            Popups.closeAll();
            Quickshell.execDetached(["/usr/bin/qs", "ipc", "call", "clipboard", "toggle"]);
        } else if (it.id === "bar") {
            root.openBar();
        } else if (it.id === "emojis") {
            Popups.closeAll();
            Quickshell.execDetached(["/usr/bin/qs", "ipc", "call", "emojis", "toggle"]);
        } else if (it.id === "keys") {
            root.openKeys();
        }
    }

    function handleKey(event) {
        const jump = KeyNav.jump(event, count);
        if (jump >= 0) {
            cursor = jump;
            runItem(jump);
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
            runItem(cursor);
            return true;
        }
        return false;
    }

    Repeater {
        model: root.items

        Rectangle {
            id: rowBox
            required property var modelData
            required property int index

            readonly property bool selected: root.cursor === index
            readonly property bool isLofi: modelData.id === "lofi"
            readonly property bool isLofiOn: isLofi && Radio.playing

            width: root.width
            height: 40
            radius: Style.radius
            color: isLofiOn ? Color.accent : (selected ? Color.focusFill : Color.surface)
            border.width: selected ? 1 : 0
            border.color: isLofiOn ? Color.background : Color.accent

            IndexBadge {
                slot: index
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 28
                anchors.right: statusBadge.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: rowBox.isLofiOn ? Color.background : Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    font.bold: true
                    text: modelData.name
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: rowBox.isLofiOn ? Color.background : Color.popupMuted
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
                radius: Style.radius
                color: rowBox.isLofiOn ? Color.background : (rowBox.selected ? Color.surface : Color.background)

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption - 1
                    font.bold: true
                    color: rowBox.isLofiOn ? Color.accent : (modelData.active ? Color.accent : Color.popupMuted)
                    text: modelData.status
                }
            }

            HoverMouse {
                onClicked: {
                    root.cursor = index;
                    root.runItem(index);
                }
            }
        }
    }
}
