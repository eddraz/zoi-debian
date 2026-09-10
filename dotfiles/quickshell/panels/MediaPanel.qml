pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 10
    width: parent ? parent.width : 252
    property int cursor: 0

    function runSlot(id) {
        if (id === 0)
            Media.previous();
        else if (id === 1)
            Media.toggle();
        else
            Media.next();
    }

    function nextSection(back) {
        cursor = back ? (cursor - 1 + 3) % 3 : (cursor + 1) % 3;
    }

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: [
        { "label": "prev previous", "index": 0 },
        { "label": "play pause", "index": 1 },
        { "label": "next", "index": 2 }
    ]

    function handleKey(event) {
        const jump = KeyNav.jump(event, 3);
        if (jump >= 0) {
            cursor = jump;
            runSlot(jump);
            return true;
        }
        if (KeyNav.isLeft(event) || KeyNav.isPrev(event)) {
            cursor = Math.max(0, cursor - 1);
            return true;
        }
        if (KeyNav.isRight(event) || KeyNav.isNext(event)) {
            cursor = Math.min(2, cursor + 1);
            return true;
        }
        if (KeyNav.isActivate(event)) {
            runSlot(cursor);
            return true;
        }
        return false;
    }

    Rectangle {
        width: parent.width
        height: trackCol.implicitHeight + 16
        radius: Style.radius
        color: Color.surface
        border.width: 1
        border.color: Color.subtleBorder

        Column {
            id: trackCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 10
            spacing: 3

            Text {
                width: parent.width
                color: Color.accent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBadge
                font.bold: true
                elide: Text.ElideRight
                text: (Media.identity || "NO PLAYER").toUpperCase()
            }

            Text {
                width: parent.width
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBody
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: Media.title || "Not playing"
            }

            Text {
                visible: Media.artist !== ""
                width: parent.width
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: Media.artist + (Media.album ? " · " + Media.album : "")
            }
        }
    }

    Row {
        spacing: 6
        width: parent.width

        Repeater {
            model: [
                { "id": 0, "label": "Prev" },
                { "id": 1, "label": Media.playing ? "Pause" : "Play" },
                { "id": 2, "label": "Next" }
            ]

            Rectangle {
                required property var modelData
                readonly property bool selected: root.cursor === modelData.id

                width: (root.width - 12) / 3
                height: 30
                radius: Style.radius
                color: selected ? Color.focusFill : Color.surface
                border.width: 1
                border.color: selected ? Color.accent : "transparent"
                Behavior on color { ColorAnimation { duration: Style.animDuration } }
                Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

                IndexBadge {
                    slot: modelData.id
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 26
                    anchors.rightMargin: 6
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    font.bold: selected
                    elide: Text.ElideRight
                    text: modelData.label
                }

                HoverMouse {
                    onClicked: {
                        root.cursor = modelData.id;
                        root.runSlot(modelData.id);
                    }
                }
            }
        }
    }
}
