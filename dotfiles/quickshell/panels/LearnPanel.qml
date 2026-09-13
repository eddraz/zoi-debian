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
    readonly property string docsBin: home + "/.local/bin/qs-docs"

    readonly property var items: [
        { "id": "zoi", "name": "ZOI", "desc": "Índice del manual", "file": "README.md", "url": "" },
        { "id": "install", "name": "Install", "desc": "Bootstrap y paquetes", "file": "install.md", "url": "" },
        { "id": "features", "name": "Features", "desc": "Qué hace cada parte", "file": "features.md", "url": "" },
        { "id": "configuration", "name": "Configuration", "desc": "Dónde está cada config", "file": "configuration.md", "url": "" },
        { "id": "shortcuts", "name": "Shortcuts", "desc": "Mapa de atajos", "file": "shortcuts.md", "url": "" },
        { "id": "architecture", "name": "Architecture", "desc": "PluginRegistry, IPC, shell", "file": "architecture.md", "url": "" },
        { "id": "troubleshooting", "name": "Troubleshooting", "desc": "Fallos frecuentes", "file": "troubleshooting.md", "url": "" },
        { "id": "herdr", "name": "Herdr", "desc": "Multiplexer de agentes", "file": "herdr.md", "url": "" },
        { "id": "sway", "name": "Sway", "desc": "Wiki del compositor", "file": "", "url": "https://github.com/swaywm/sway/wiki" },
        { "id": "quickshell", "name": "Quickshell", "desc": "Guía y API QML", "file": "", "url": "https://quickshell.outfoxxed.me/docs/guide/" },
        { "id": "helix", "name": "Helix Editor", "desc": "Manual oficial", "file": "", "url": "https://docs.helix-editor.com/" },
        { "id": "fish", "name": "Fish", "desc": "Documentación del shell", "file": "", "url": "https://fishshell.com/docs/current/index.html" },
        { "id": "bash", "name": "Bash", "desc": "Manual GNU Bash", "file": "", "url": "https://www.gnu.org/software/bash/manual/html_node/index.html" }
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
        Popups.closeAll();
        if (it.url)
            Quickshell.execDetached(["xdg-open", it.url]);
        else
            Quickshell.execDetached([docsBin, it.file || "README.md"]);
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
            title: modelData.name
            description: modelData.desc
            badge: modelData.url ? "web" : "md"
            onClicked: {
                root.cursor = index;
                root.runItem(index);
            }
        }
    }
}
