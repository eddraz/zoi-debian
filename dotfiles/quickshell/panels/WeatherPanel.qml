pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"

Column {
    id: root

    spacing: 8
    width: parent ? parent.width : 252

    function nextSection(back) {}

    function focusItem(entry) {}

    readonly property var searchEntries: [
        { "label": "refresh weather", "index": 0 }
    ]

    function handleKey(event) {
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
            width: root.width
            height: 42
            radius: Style.radius
            color: Color.surface
            border.width: 1
            border.color: Color.subtleBorder

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
