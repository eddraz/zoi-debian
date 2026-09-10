pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 8
    width: parent ? parent.width : 252

    property int cursor: 0
    readonly property int count: 1 + Notifs.history.length

    function nextSection(back) {}

    function focusItem(entry) {
        cursor = Math.max(0, Math.min(count - 1, entry.index));
    }

    readonly property var searchEntries: {
        const e = [{ "label": "do not disturb dnd mute", "index": 0 }];
        for (let i = 0; i < Notifs.history.length; i++) {
            const n = Notifs.history[i];
            e.push({ "label": String(n.summary || n.app || "notification"), "index": 1 + i });
        }
        return e;
    }

    onVisibleChanged: {
        if (visible) {
            cursor = 0;
            Notifs.clearUnread();
        }
    }

    function handleKey(event) {
        const jump = KeyNav.jump(event, count);
        if (jump >= 0) {
            cursor = jump;
            return true;
        }
        if (KeyNav.isNext(event) || KeyNav.isDown(event)) {
            cursor = Math.min(count - 1, cursor + 1);
            return true;
        }
        if (KeyNav.isPrev(event) || KeyNav.isUp(event)) {
            cursor = Math.max(0, cursor - 1);
            return true;
        }
        if (KeyNav.isActivate(event) && cursor === 0) {
            Notifs.toggleDnd();
            return true;
        }
        return false;
    }

    Rectangle {
        width: parent.width
        height: 42
        radius: Style.radius
        color: Notifs.dnd ? Color.urgent : (root.cursor === 0 ? Color.focusFill : Color.surface)
        border.width: 1
        border.color: Notifs.dnd ? Color.urgent : (root.cursor === 0 ? Color.accent : "transparent")
        Behavior on color { ColorAnimation { duration: Style.animDuration } }

        Rectangle {
            width: 3
            height: 20
            radius: 1.5
            color: Notifs.dnd ? Color.background : Color.accent
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: Notifs.dnd
        }

        IndexBadge {
            slot: 0
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.right: dndBadge.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Notifs.dnd ? Color.background : Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBody
                font.bold: true
                text: "Modo No Molestar"
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Notifs.dnd ? Color.background : Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: Notifs.dnd ? "Notificaciones emergentes silenciadas" : "Notificaciones en pantalla permitidas"
            }
        }

        Rectangle {
            id: dndBadge
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 20
            width: dndBadgeText.implicitWidth + 12
            radius: 4
            color: Notifs.dnd ? Color.background : Color.background
            border.width: 1
            border.color: Notifs.dnd ? Color.background : Color.subtleBorder

            Text {
                id: dndBadgeText
                anchors.centerIn: parent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption - 1
                font.bold: true
                color: Notifs.dnd ? Color.urgent : Color.popupMuted
                text: Notifs.dnd ? "DND ON" : "DND OFF"
            }
        }

        HoverMouse {
            onClicked: {
                root.cursor = 0;
                Notifs.toggleDnd();
            }
        }
    }

    Text {
        visible: Notifs.history.length === 0
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Sin notificaciones pendientes"
    }

    Repeater {
        model: Notifs.history

        Rectangle {
            required property var modelData
            required property int index
            width: root.width
            implicitHeight: notifCol.implicitHeight + 16
            radius: Style.radius
            color: root.cursor === index + 1 ? Color.focusFill : Color.surface
            border.width: 1
            border.color: root.cursor === index + 1 ? Color.accent : Color.subtleBorder

            Column {
                id: notifCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 10
                spacing: 4

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        width: parent.width - appBadge.width - 6
                        color: Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontBody
                        font.bold: true
                        elide: Text.ElideRight
                        text: modelData.summary || modelData.app || "Notificación"
                    }

                    Rectangle {
                        id: appBadge
                        height: 18
                        width: appBadgeText.implicitWidth + 8
                        radius: 3
                        color: Color.focusFill
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: appBadgeText
                            anchors.centerIn: parent
                            color: Color.accent
                            font.family: Style.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            text: modelData.app || "App"
                        }
                    }
                }

                Text {
                    visible: modelData.body !== ""
                    width: parent.width
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    text: modelData.body
                }
            }
        }
    }
}
