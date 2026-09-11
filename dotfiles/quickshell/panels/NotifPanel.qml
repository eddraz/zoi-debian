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

    function nextSection(back) {
        if (count <= 0) return;
        cursor = back ? (cursor - 1 + count) % count : (cursor + 1) % count;
    }

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

    ActionListItem {
        selected: root.cursor === 0
        slot: 0
        highlighted: Notifs.dnd
        useHighlightBg: true
        highlightBg: Color.urgent
        title: "Modo No Molestar"
        description: Notifs.dnd ? "Notificaciones emergentes silenciadas" : "Notificaciones en pantalla permitidas"
        badge: Notifs.dnd ? "DND ON" : "DND OFF"
        onClicked: {
            root.cursor = 0;
            Notifs.toggleDnd();
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
