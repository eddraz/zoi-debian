pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 6
    width: parent ? parent.width : 252
    property int cursor: Keyboard.index

    readonly property int count: Keyboard.codes.length

    onVisibleChanged: if (visible) {
        cursor = Keyboard.index;
        Keyboard.refresh();
    }

    function nextSection(back) {
        cursor = KeyNav.nextStart([0], cursor, back);
    }

    function focusItem(entry) {
        cursor = entry.index;
        Keyboard.setIndex(entry.index);
    }

    readonly property var searchEntries: {
        const e = [];
        for (let i = 0; i < count; i++)
            e.push({ "label": Keyboard.labels[i] + " " + Keyboard.names[i], "index": i });
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
            height: 26
            radius: Style.radius
            color: current ? Color.accent : (selected ? Color.focusFill : Color.surface)

            IndexBadge {
                slot: index
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                anchors.fill: parent
                anchors.leftMargin: 28
                anchors.rightMargin: 8
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                color: current ? Color.background : Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: Keyboard.labels[index] + "  " + Keyboard.names[index]
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
