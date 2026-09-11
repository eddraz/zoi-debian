pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 6
    width: parent ? parent.width : 320
    property int cursor: Keyboard.index

    readonly property int count: Keyboard.labels.length

    onVisibleChanged: if (visible) {
        cursor = Keyboard.index;
        Keyboard.refresh();
    }

    function nextSection(back) {
        if (count <= 0) return;
        cursor = back ? (cursor - 1 + count) % count : (cursor + 1) % count;
    }

    function focusItem(entry) {
        cursor = entry.index;
        Keyboard.setIndex(entry.index);
    }

    readonly property var searchEntries: {
        const e = [];
        for (let i = 0; i < count; i++)
            e.push({ "label": (Keyboard.labels[i] || "") + " " + (Keyboard.names[i] || ""), "index": i });
        return e;
    }

    function handleKey(event) {
        const jump = KeyNav.jump(event, count);
        if (jump >= 0) {
            cursor = jump;
            Keyboard.setIndex(jump);
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
            Keyboard.setIndex(cursor);
            return true;
        }
        return false;
    }

    Repeater {
        model: root.count

        ActionListItem {
            required property int index
            readonly property bool current: Keyboard.index === index

            width: root.width
            selected: root.cursor === index
            slot: index
            highlighted: current
            title: Keyboard.names[index] || Keyboard.labels[index] || "Distribución"
            description: {
                const code = Keyboard.labels[index] || "";
                if (code === "LATAM")
                    return "Español Latinoamericano (tecla Ñ)";
                if (code === "US")
                    return "Inglés Internacional estándar";
                return "Distribución de teclado " + code;
            }
            badge: current ? "ACTIVA" : (Keyboard.labels[index] || "ELEGIR")
            onClicked: {
                root.cursor = index;
                Keyboard.setIndex(index);
            }
        }
    }
}
