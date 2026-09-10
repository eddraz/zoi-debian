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
        cursor = KeyNav.nextStart([0], cursor, back);
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
            height: 36
            radius: Style.radius
            color: selected ? Color.focusFill : Color.surface
            border.width: 1
            border.color: selected ? Color.accent : (current ? Color.accent : "transparent")
            Behavior on color { ColorAnimation { duration: Style.animDuration } }
            Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

            // Active indicator pill on left (cursor)
            Rectangle {
                width: 3
                height: parent.height - 10
                radius: 1.5
                color: Color.accent
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                visible: selected
            }

            // Keycap badge [1], [2]
            IndexBadge {
                id: badge
                slot: index
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
            }

            // Layout short code pill (e.g. LATAM, US)
            Rectangle {
                id: codePill
                anchors.left: badge.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(38, codeLabel.implicitWidth + 10)
                height: 20
                radius: 4
                color: current ? Color.accent : Color.crust
                border.width: 1
                border.color: current ? Color.accent : Color.subtleBorder
                Behavior on color { ColorAnimation { duration: Style.animDuration } }

                Text {
                    id: codeLabel
                    anchors.centerIn: parent
                    color: current ? Color.background : Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBadge
                    font.bold: true
                    text: Keyboard.labels[index] || ""
                }
            }

            // Full layout name
            Text {
                anchors.left: codePill.right
                anchors.leftMargin: 8
                anchors.right: radioIndicator.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                color: current ? Color.accent : Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                font.bold: current
                text: Keyboard.names[index] || ""
            }

            // Radio button indicator on right (single selection)
            Rectangle {
                id: radioIndicator
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: current ? Color.accent : "transparent"
                border.width: 1.5
                border.color: current ? Color.accent : Color.popupMuted
                Behavior on color { ColorAnimation { duration: Style.animDuration } }
                Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: Color.background
                    visible: current
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
