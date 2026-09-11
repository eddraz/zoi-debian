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

    readonly property string home: Quickshell.env("HOME")

    readonly property var items: [
        {
"id": "markdown",
            "name": "Markdown",
            "desc": "Abrir un .md con Inlyne",
            "status": "Inlyne",
            "active": false
        },
        {
            "id": "screenshot",
            "name": "Screenshot",
            "desc": "Región al portapapeles y a Imágenes",
            "status": "Print",
            "active": false
        },
        {
            "id": "record",
            "name": "Grabar pantalla",
            "desc": "Región con wf-recorder · Alt+Print para parar",
            "status": "Alt+Print",
            "active": false
        },
        {
            "id": "clipboard",
            "name": "Compartir clipboard",
            "desc": "Historial de recortes",
            "status": "Super+V",
            "active": false
        },
        {
            "id": "files",
            "name": "Compartir archivos",
            "desc": "Yazi en foot",
            "status": "Super+Shift+F",
            "active": false
        },
        {
            "id": "reminders",
            "name": "Reminders",
            "desc": Reminders.count > 0 ? (Reminders.count + " activos") : "Crear o ver avisos",
            "status": "Super+Shift+N",
            "active": Reminders.count > 0
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
            "desc": NightLight.enabled ? "Filtro cálido activo" : "Temperatura de color estándar",
            "status": NightLight.enabled ? "ON" : "OFF",
            "active": NightLight.enabled
        },
        {
            "id": "dnd",
            "name": "No molestar",
            "desc": Notifs.dnd ? "Notificaciones silenciadas" : "Notificaciones activas",
            "status": Notifs.dnd ? "ON" : "OFF",
            "active": Notifs.dnd
        }
    ]

    readonly property int count: items.length

    onVisibleChanged: if (visible) cursor = 0

    function nextSection(back) {
        if (count <= 0)
            return;
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
        if (it.id === "markdown") {
            Popups.closeAll();
            Quickshell.execDetached([home + "/.local/bin/qs-md-open"]);
        } else if (it.id === "screenshot") {
            Popups.closeAll();
            Quickshell.execDetached([home + "/.local/bin/qs-screenshot"]);
        } else if (it.id === "record") {
            Popups.closeAll();
            Quickshell.execDetached([home + "/.local/bin/qs-screenrecord"]);
        } else if (it.id === "clipboard") {
            Popups.closeAll();
            Quickshell.execDetached(["/usr/bin/qs", "ipc", "call", "clipboard", "toggle"]);
        } else if (it.id === "files") {
            Popups.closeAll();
            Quickshell.execDetached([home + "/.local/bin/qs-files"]);
        } else if (it.id === "reminders") {
            Popups.closeAll();
            Quickshell.execDetached(["/usr/bin/qs", "ipc", "call", "reminders", "toggle"]);
        } else if (it.id === "stayawake") {
            Idle.toggle();
        } else if (it.id === "nightlight") {
            NightLight.toggle();
        } else if (it.id === "dnd") {
            Notifs.toggleDnd();
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
