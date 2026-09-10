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

        Rectangle {
            required property int index
            readonly property bool selected: root.cursor === index
            readonly property bool current: Keyboard.index === index

            width: root.width
            height: 42
            radius: Style.radius
            color: selected ? Color.focusFill : Color.surface
            border.width: selected ? 1 : 0
            border.color: Color.accent
            Behavior on color { ColorAnimation { duration: Style.animDuration } }

            // Active indicator pill on left (cursor)
            Rectangle {
                width: 3
                height: selected ? 20 : 0
                radius: 1.5
                color: Color.accent
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: selected
                Behavior on height { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic } }
            }

            // Keycap badge [1], [2]
            IndexBadge {
                id: badge
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
                    color: current ? Color.accent : Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    font.bold: true
                    text: Keyboard.names[index] || Keyboard.labels[index] || "Distribución"
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: {
                        const code = Keyboard.labels[index] || "";
                        if (code === "LATAM")
                            return "Español Latinoamericano (tecla Ñ)";
                        if (code === "US")
                            return "Inglés Internacional estándar";
                        return "Distribución de teclado " + code;
                    }
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
                color: current ? Color.focusFill : (selected ? Color.surface : Color.background)
                border.width: 1
                border.color: current ? Color.accent : (selected ? Color.subtleBorder : "transparent")

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption - 1
                    font.bold: true
                    color: current ? Color.accent : Color.popupMuted
                    text: current ? "ACTIVA" : (Keyboard.labels[index] || "ELEGIR")
                }
            }

            HoverMouse {
                onClicked: {
                    root.cursor = index;
                    Keyboard.setIndex(index);
                }
            }
        }
    }
}
