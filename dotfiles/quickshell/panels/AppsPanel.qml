pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 6
    width: parent ? parent.width : 320
    property int cursor: 0

    signal openBar
    signal openKeys
    signal openTheme

    readonly property var items: [
        {
            "id": "lofi",
            "name": "Lofi Radio",
            "desc": Radio.playing ? "Reproduciendo stream en vivo" : "Música relajante de fondo",
            "status": Radio.playing ? "ON" : "OFF",
            "active": Radio.playing
        },
        {
            "id": "stayawake",
            "name": "Modo Vigilia",
            "desc": Idle.stayAwake ? "Evita suspensión y bloqueo" : "Comportamiento normal de reposo",
            "status": Idle.stayAwake ? "ON" : "OFF",
            "active": Idle.stayAwake
        },
        {
            "id": "nightlight",
            "name": "Luz Nocturna",
            "desc": NightLight.enabled ? "Filtro cálido de pantalla activo" : "Temperatura de color estándar",
            "status": NightLight.enabled ? "ON" : "OFF",
            "active": NightLight.enabled
        },
        {
            "id": "theme",
            "name": "Selector de Temas",
            "desc": "Paleta de colores y estilos",
            "status": "Tema",
            "active": false
        },
        {
            "id": "bar",
            "name": "Bar",
            "desc": "Organizar barra y widgets",
            "status": "Super+Shift+B",
            "active": false
        },
        {
            "id": "clipboard",
            "name": "Portapapeles",
            "desc": "Historial de texto y recortes",
            "status": "Super+V",
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
        if (count <= 0) return;
        cursor = back ? (cursor - 1 + count) % count : (cursor + 1) % count;
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
        } else if (it.id === "stayawake") {
            Idle.toggle();
        } else if (it.id === "nightlight") {
            NightLight.toggle();
        } else if (it.id === "theme") {
            root.openTheme();
        } else if (it.id === "bar") {
            root.openBar();
        } else if (it.id === "clipboard") {
            Popups.closeAll();
            Quickshell.execDetached(["/usr/bin/qs", "ipc", "call", "clipboard", "toggle"]);
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

        ActionListItem {
            required property var modelData
            required property int index

            width: root.width
            selected: root.cursor === index
            slot: index
            highlighted: modelData.active
            useHighlightBg: modelData.id === "lofi" && modelData.active
            title: modelData.name
            description: modelData.desc
            badge: modelData.status
            onClicked: {
                root.cursor = index;
                root.runItem(index);
            }
        }
    }
}
