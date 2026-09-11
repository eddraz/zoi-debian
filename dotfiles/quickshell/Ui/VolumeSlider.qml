pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"

// Reusable volume/progress slider row for AudioPanel.
// Encapsulates: IndexBadge · label · slider bar · percentage text.
Item {
    id: root

    property bool selected: false
    property int slot: 0
    property string label: "VOL"
    property real percent: 0            // 0-100
    property bool muted: false
    property color accentColor: Color.accent
    property bool ready: true

    signal adjust(real delta)
    signal setVolume(real fraction)

    width: parent ? parent.width : 252
    height: 30

    Rectangle {
        anchors.fill: parent
        radius: Style.radius
        color: root.selected ? Color.focusFill : Color.surface
        border.width: root.selected ? 1 : 0
        border.color: root.accentColor
        Behavior on color { ColorAnimation { duration: Style.animDuration } }
    }

    Row {
        spacing: 8
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        IndexBadge {
            slot: root.slot
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: root.muted ? Color.urgent : Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            font.bold: true
            text: root.muted ? "MUTE" : root.label
        }

        Rectangle {
            id: sliderTrack
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 96
            height: 8
            radius: 4
            color: Color.crust
            border.width: root.selected ? 1 : 0
            border.color: root.accentColor

            Rectangle {
                height: parent.height
                width: parent.width * (root.muted ? 0 : root.percent / 100)
                radius: 4
                color: root.accentColor
                Behavior on width { NumberAnimation { duration: 80 } }
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                cursorShape: Qt.PointingHandCursor
                onPressed: event => {
                    root.setVolume(event.x / sliderTrack.width);
                }
                onPositionChanged: event => {
                    if (pressed)
                        root.setVolume(event.x / sliderTrack.width);
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            color: Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            text: root.ready ? root.percent + "%" : "--"
        }
    }
}
