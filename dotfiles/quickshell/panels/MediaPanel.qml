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
        cursor = KeyNav.nextStart([0, 1, 2], cursor, back);
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

    Text {
        width: parent.width
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        elide: Text.ElideRight
        text: Media.identity || "No player"
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
                width: (root.width - 12) / 3
                height: 26
                radius: Style.radius
                color: root.cursor === modelData.id ? Color.focusFill : Color.surface

                IndexBadge {
                    slot: modelData.id
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
