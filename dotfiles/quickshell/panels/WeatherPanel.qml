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
            height: 24
            radius: Style.radius
            color: Color.surface

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: Weather.weekday(modelData.date)
            }

            Text {
                anchors.centerIn: parent
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: Weather.conditionFor(modelData.code)
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: Math.round(modelData.max) + "° / " + Math.round(modelData.min) + "°"
            }
        }
    }
}
