pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 8
    width: parent ? parent.width : 252

    function nextSection(back) {}

    function focusItem(entry) {}

    readonly property var searchEntries: [
        { "label": "do not disturb dnd mute", "index": 0 }
    ]

    function handleKey(event) {
        if (KeyNav.jump(event, 1) === 0) {
            Notifs.toggleDnd();
            return true;
        }
        if (KeyNav.isActivate(event)) {
            Notifs.toggleDnd();
            return true;
        }
        return false;
    }

    onVisibleChanged: if (visible)
        Notifs.clearUnread()

    Rectangle {
        width: parent.width
        height: 26
        radius: Style.radius
        color: Notifs.dnd ? Color.urgent : Color.surface

        IndexBadge {
            slot: 0
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Notifs.dnd ? Color.background : Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            elide: Text.ElideRight
            text: (Notifs.dnd ? "Do not disturb on" : "Do not disturb off")
        }

        HoverMouse {
            onClicked: Notifs.toggleDnd()
        }
    }

    Text {
        visible: Notifs.history.length === 0
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "No notifications"
    }

    Repeater {
        model: Notifs.history

        Column {
            required property var modelData
            width: root.width
            spacing: 2

            Text {
                width: parent.width
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                elide: Text.ElideRight
                text: modelData.app
            }

            Text {
                width: parent.width
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: modelData.summary
            }

            Text {
                visible: modelData.body !== ""
                width: parent.width
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                text: modelData.body
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Color.surface
            }
        }
    }
}
