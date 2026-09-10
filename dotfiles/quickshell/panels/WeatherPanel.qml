pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 8
    width: parent ? parent.width : 252

    property int cursor: 0
    readonly property int count: 1 + Weather.days.length

    function nextSection(back) {
        if (count <= 0) return;
        cursor = back ? (cursor - 1 + count) % count : (cursor + 1) % count;
    }

    function focusItem(entry) {
        cursor = Math.max(0, Math.min(count - 1, entry.index));
    }

    readonly property var searchEntries: {
        const e = [{ "label": "refresh weather", "index": 0 }];
        for (let i = 0; i < Weather.days.length; i++)
            e.push({ "label": String(Weather.weekday(Weather.days[i].date) || "day"), "index": 1 + i });
        return e;
    }

    onVisibleChanged: {
        if (visible)
            cursor = 0;
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
        if (KeyNav.isActivate(event)) {
            Weather.refresh();
            return true;
        }
        return false;
    }

    Text {
        width: parent.width
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: Weather.city !== "" ? Weather.city : "Locating…"
    }

    Text {
        width: parent.width
        color: Color.popupText
        font.family: Style.fontFamily
        font.pixelSize: 22
        font.bold: true
        text: Weather.ready ? Weather.label : "…"
    }

    Text {
        width: parent.width
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: Weather.ready ? Weather.condition : "Fetching Open-Meteo"
    }

    Repeater {
        model: Weather.days

        Rectangle {
            required property var modelData
            required property int index
            width: root.width
            height: 42
            radius: Style.radius
            color: root.cursor === index + 1 ? Color.focusFill : Color.surface
            border.width: 1
            border.color: root.cursor === index + 1 ? Color.accent : Color.subtleBorder

            HoverMouse {
                z: -1
                onClicked: root.cursor = index + 1
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.right: weatherBadge.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    font.bold: true
                    text: Weather.weekday(modelData.date)
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: Weather.conditionFor(modelData.code)
                }
            }

            Rectangle {
                id: weatherBadge
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 20
                width: weatherBadgeText.implicitWidth + 12
                radius: 4
                color: Color.background
                border.width: 1
                border.color: Color.subtleBorder

                Text {
                    id: weatherBadgeText
                    anchors.centerIn: parent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption - 1
                    font.bold: true
                    color: Color.accent
                    text: Math.round(modelData.max) + "° / " + Math.round(modelData.min) + "°"
                }
            }
        }
    }
}
