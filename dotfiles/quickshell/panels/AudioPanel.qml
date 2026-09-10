pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 10
    width: parent ? parent.width : 252
    property int cursor: 0

    readonly property int sinkStart: 2
    readonly property int micVol: 2 + Audio.sinks.length
    readonly property int micMute: micVol + 1
    readonly property int sourceStart: micMute + 1
    readonly property int count: sourceStart + Audio.sources.length

    onVisibleChanged: if (visible)
        cursor = 0

    function nextSection(back) {
        cursor = KeyNav.nextStart([0, micVol, sourceStart], cursor, back);
    }

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: {
        const e = [
            { "label": "volume output", "index": 0 },
            { "label": "mute speakers", "index": 1 }
        ];
        for (let i = 0; i < Audio.sinks.length; i++) {
            const n = Audio.sinks[i];
            e.push({ "label": String(n.description || n.nickname || n.name || "sink"), "index": sinkStart + i });
        }
        e.push({ "label": "microphone volume mic", "index": micVol });
        e.push({ "label": "mute mic", "index": micMute });
        for (let i = 0; i < Audio.sources.length; i++) {
            const n = Audio.sources[i];
            e.push({ "label": String(n.description || n.nickname || n.name || "source"), "index": sourceStart + i });
        }
        return e;
    }

    function handleKey(event) {
        const jump = KeyNav.jump(event, count);
        if (jump >= 0) {
            cursor = jump;
            return true;
        }
        if (cursor === 0 && KeyNav.isLeft(event)) {
            Audio.adjust(-0.05);
            return true;
        }
        if (cursor === 0 && KeyNav.isRight(event)) {
            Audio.adjust(0.05);
            return true;
        }
        if (cursor === micVol && KeyNav.isLeft(event)) {
            Audio.adjustSource(-0.05);
            return true;
        }
        if (cursor === micVol && KeyNav.isRight(event)) {
            Audio.adjustSource(0.05);
            return true;
        }
        if (KeyNav.isNext(event) || (cursor !== 0 && cursor !== micVol && KeyNav.isRight(event))) {
            cursor = Math.min(cursor + 1, Math.max(0, count - 1));
            return true;
        }
        if (KeyNav.isPrev(event) || (cursor !== 0 && cursor !== micVol && KeyNav.isLeft(event))) {
            cursor = Math.max(cursor - 1, 0);
            return true;
        }
        if (KeyNav.isActivate(event)) {
            if (cursor === 1)
                Audio.toggleMute();
            else if (cursor >= sinkStart && cursor < micVol)
                Audio.setSink(Audio.sinks[cursor - sinkStart]);
            else if (cursor === micMute)
                Audio.toggleSourceMute();
            else if (cursor >= sourceStart && cursor < count)
                Audio.setSource(Audio.sources[cursor - sourceStart]);
            return true;
        }
        return false;
    }

    function volumeRow(kind) {
        return kind;
    }

    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Output"
    }

    Rectangle {
        width: parent.width
        height: 28
        radius: Style.radius
        color: root.cursor === 0 ? Color.focusFill : Color.surface

        Row {
        spacing: 8
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6

        IndexBadge {
            slot: 0
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Audio.muted ? Color.urgent : Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            font.bold: true
            text: Audio.muted ? "MUTE" : "VOL"
        }

        Rectangle {
            id: slider
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 96
            height: 8
            radius: 4
            color: Color.surface
            border.width: root.cursor === 0 ? 1 : 0
            border.color: Color.accent

            Rectangle {
                height: parent.height
                width: parent.width * (Audio.muted ? 0 : Audio.percent / 100)
                radius: 4
                color: Color.accent
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                cursorShape: Qt.PointingHandCursor
                onPressed: event => {
                    root.cursor = 0;
                    Audio.setVolume(event.x / slider.width);
                }
                onPositionChanged: event => {
                    if (pressed)
                        Audio.setVolume(event.x / slider.width);
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            color: Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            text: Audio.percent + "%"
        }
        }
    }

    Rectangle {
        width: parent.width
        height: 24
        radius: Style.radius
        color: Audio.muted ? Color.urgent : (root.cursor === 1 ? Color.focusFill : Color.surface)

        IndexBadge {
            slot: 1
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Audio.muted ? Color.background : Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            elide: Text.ElideRight
            text: (Audio.muted ? "Unmute speakers" : "Mute speakers")
        }

        HoverMouse {
            onClicked: {
                root.cursor = 1;
                Audio.toggleMute();
            }
        }
    }

    Repeater {
        model: Audio.sinks

        Rectangle {
            required property var modelData
            required property int index
            readonly property bool selected: root.cursor === root.sinkStart + index

            width: root.width
            height: 24
            radius: Style.radius
            color: Audio.sink === modelData ? Color.accent : (selected ? Color.focusFill : Color.surface)

            IndexBadge {
                slot: root.sinkStart + index
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                anchors.fill: parent
                anchors.leftMargin: 28
                anchors.rightMargin: 8
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                color: Audio.sink === modelData ? Color.background : Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: (modelData.description || modelData.nickname || modelData.name)
            }

            HoverMouse {
                onClicked: {
                    root.cursor = root.sinkStart + index;
                    Audio.setSink(modelData);
                }
            }
        }
    }

    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Microphone"
    }

    Rectangle {
        width: parent.width
        height: 28
        radius: Style.radius
        color: root.cursor === root.micVol ? Color.focusFill : Color.surface

        Row {
        spacing: 8
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6

        IndexBadge {
            slot: root.micVol
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Audio.sourceMuted ? Color.urgent : Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            font.bold: true
            text: Audio.sourceMuted ? "MUTE" : "MIC"
        }

        Rectangle {
            id: micSlider
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 96
            height: 8
            radius: 4
            color: Color.surface
            border.width: root.cursor === root.micVol ? 1 : 0
            border.color: Color.accent

            Rectangle {
                height: parent.height
                width: parent.width * (Audio.sourceMuted ? 0 : Audio.sourcePercent / 100)
                radius: 4
                color: Color.peach
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                cursorShape: Qt.PointingHandCursor
                onPressed: event => {
                    root.cursor = root.micVol;
                    Audio.setSourceVolume(event.x / micSlider.width);
                }
                onPositionChanged: event => {
                    if (pressed)
                        Audio.setSourceVolume(event.x / micSlider.width);
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            color: Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            text: Audio.sourceReady ? Audio.sourcePercent + "%" : "--"
        }
        }
    }

    Rectangle {
        width: parent.width
        height: 24
        radius: Style.radius
        color: Audio.sourceMuted ? Color.urgent : (root.cursor === root.micMute ? Color.focusFill : Color.surface)

        IndexBadge {
            slot: root.micMute
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Audio.sourceMuted ? Color.background : Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            elide: Text.ElideRight
            text: (Audio.sourceMuted ? "Unmute mic" : "Mute mic")
        }

        HoverMouse {
            onClicked: {
                root.cursor = root.micMute;
                Audio.toggleSourceMute();
            }
        }
    }

    Repeater {
        model: Audio.sources

        Rectangle {
            required property var modelData
            required property int index
            readonly property bool selected: root.cursor === root.sourceStart + index

            width: root.width
            height: 24
            radius: Style.radius
            color: Audio.source === modelData ? Color.accent : (selected ? Color.focusFill : Color.surface)

            IndexBadge {
                slot: root.sourceStart + index
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                anchors.fill: parent
                anchors.leftMargin: 28
                anchors.rightMargin: 8
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                color: Audio.source === modelData ? Color.background : Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: modelData.description || modelData.nickname || modelData.name
            }

            HoverMouse {
                onClicked: {
                    root.cursor = root.sourceStart + index;
                    Audio.setSource(modelData);
                }
            }
        }
    }
}
