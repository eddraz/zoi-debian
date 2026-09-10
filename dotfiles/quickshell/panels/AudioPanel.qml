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
        height: 30
        radius: Style.radius
        color: root.cursor === 0 ? Color.focusFill : Color.surface
        border.width: root.cursor === 0 ? 1 : 0
        border.color: Color.accent
        Behavior on color { ColorAnimation { duration: Style.animDuration } }

        Row {
            spacing: 8
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

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
                color: Color.crust
                border.width: root.cursor === 0 ? 1 : 0
                border.color: Color.accent

                Rectangle {
                    height: parent.height
                    width: parent.width * (Audio.muted ? 0 : Audio.percent / 100)
                    radius: 4
                    color: Color.accent
                    Behavior on width { NumberAnimation { duration: 80 } }
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
        height: 42
        radius: Style.radius
        color: Audio.muted ? Color.urgent : (root.cursor === 1 ? Color.focusFill : Color.surface)
        border.width: root.cursor === 1 ? 1 : 0
        border.color: Audio.muted ? Color.background : Color.accent
        Behavior on color { ColorAnimation { duration: Style.animDuration } }

        Rectangle {
            width: 3
            height: root.cursor === 1 ? 20 : 0
            radius: 1.5
            color: Audio.muted ? Color.background : Color.accent
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.cursor === 1
            Behavior on height { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic } }
        }

        IndexBadge {
            slot: 1
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.right: muteSinkBadge.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Audio.muted ? Color.background : Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBody
                font.bold: true
                text: "Silenciar Salida"
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Audio.muted ? Color.background : Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: Audio.muted ? "Audio actualmente silenciado" : "Audio reproduciéndose con normalidad"
            }
        }

        Rectangle {
            id: muteSinkBadge
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 20
            width: muteSinkText.implicitWidth + 12
            radius: 4
            color: Audio.muted ? Color.background : (root.cursor === 1 ? Color.surface : Color.background)
            border.width: 1
            border.color: Audio.muted ? Color.background : (root.cursor === 1 ? Color.subtleBorder : "transparent")

            Text {
                id: muteSinkText
                anchors.centerIn: parent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption - 1
                font.bold: true
                color: Audio.muted ? Color.urgent : Color.popupMuted
                text: Audio.muted ? "MUTED" : "ON"
            }
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
            id: sinkBox
            required property var modelData
            required property int index
            readonly property bool selected: root.cursor === root.sinkStart + index
            readonly property bool isCurrent: Audio.sink === modelData

            width: root.width
            height: 42
            radius: Style.radius
            color: selected ? Color.focusFill : Color.surface
            border.width: selected ? 1 : 0
            border.color: Color.accent
            Behavior on color { ColorAnimation { duration: Style.animDuration } }

            Rectangle {
                width: 3
                height: sinkBox.selected ? 20 : 0
                radius: 1.5
                color: Color.accent
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: sinkBox.selected
                Behavior on height { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic } }
            }

            IndexBadge {
                slot: root.sinkStart + index
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.right: sinkBadge.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: sinkBox.isCurrent ? Color.accent : Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    font.bold: true
                    text: modelData.description || modelData.nickname || modelData.name || "Salida de audio"
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: sinkBox.isCurrent ? "Dispositivo principal de salida" : "Haz clic para usar como salida"
                }
            }

            Rectangle {
                id: sinkBadge
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 20
                width: sinkBadgeText.implicitWidth + 12
                radius: 4
                color: sinkBox.isCurrent ? Color.focusFill : (sinkBox.selected ? Color.surface : Color.background)
                border.width: 1
                border.color: sinkBox.isCurrent ? Color.accent : (sinkBox.selected ? Color.subtleBorder : "transparent")

                Text {
                    id: sinkBadgeText
                    anchors.centerIn: parent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption - 1
                    font.bold: true
                    color: sinkBox.isCurrent ? Color.accent : Color.popupMuted
                    text: sinkBox.isCurrent ? "ACTIVO" : "SALIDA"
                }
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
        height: 30
        radius: Style.radius
        color: root.cursor === root.micVol ? Color.focusFill : Color.surface
        border.width: root.cursor === root.micVol ? 1 : 0
        border.color: Color.peach
        Behavior on color { ColorAnimation { duration: Style.animDuration } }

        Row {
            spacing: 8
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

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
                color: Color.crust
                border.width: root.cursor === root.micVol ? 1 : 0
                border.color: Color.peach

                Rectangle {
                    height: parent.height
                    width: parent.width * (Audio.sourceMuted ? 0 : Audio.sourcePercent / 100)
                    radius: 4
                    color: Color.peach
                    Behavior on width { NumberAnimation { duration: 80 } }
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
        height: 42
        radius: Style.radius
        color: Audio.sourceMuted ? Color.urgent : (root.cursor === root.micMute ? Color.focusFill : Color.surface)
        border.width: root.cursor === root.micMute ? 1 : 0
        border.color: Audio.sourceMuted ? Color.background : Color.accent
        Behavior on color { ColorAnimation { duration: Style.animDuration } }

        Rectangle {
            width: 3
            height: root.cursor === root.micMute ? 20 : 0
            radius: 1.5
            color: Audio.sourceMuted ? Color.background : Color.accent
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.cursor === root.micMute
            Behavior on height { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic } }
        }

        IndexBadge {
            slot: root.micMute
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.right: muteMicBadge.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Audio.sourceMuted ? Color.background : Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBody
                font.bold: true
                text: "Silenciar Micrófono"
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Audio.sourceMuted ? Color.background : Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: Audio.sourceMuted ? "Micrófono actualmente silenciado" : "Captura de voz activa"
            }
        }

        Rectangle {
            id: muteMicBadge
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 20
            width: muteMicText.implicitWidth + 12
            radius: 4
            color: Audio.sourceMuted ? Color.background : (root.cursor === root.micMute ? Color.surface : Color.background)
            border.width: 1
            border.color: Audio.sourceMuted ? Color.background : (root.cursor === root.micMute ? Color.subtleBorder : "transparent")

            Text {
                id: muteMicText
                anchors.centerIn: parent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption - 1
                font.bold: true
                color: Audio.sourceMuted ? Color.urgent : Color.popupMuted
                text: Audio.sourceMuted ? "MUTED" : "ON"
            }
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
            id: sourceBox
            required property var modelData
            required property int index
            readonly property bool selected: root.cursor === root.sourceStart + index
            readonly property bool isCurrent: Audio.source === modelData

            width: root.width
            height: 42
            radius: Style.radius
            color: selected ? Color.focusFill : Color.surface
            border.width: selected ? 1 : 0
            border.color: Color.accent
            Behavior on color { ColorAnimation { duration: Style.animDuration } }

            Rectangle {
                width: 3
                height: sourceBox.selected ? 20 : 0
                radius: 1.5
                color: Color.accent
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: sourceBox.selected
                Behavior on height { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic } }
            }

            IndexBadge {
                slot: root.sourceStart + index
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.right: sourceBadge.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: sourceBox.isCurrent ? Color.accent : Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    font.bold: true
                    text: modelData.description || modelData.nickname || modelData.name || "Micrófono"
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: sourceBox.isCurrent ? "Dispositivo principal de grabación" : "Haz clic para usar como micrófono"
                }
            }

            Rectangle {
                id: sourceBadge
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 20
                width: sourceBadgeText.implicitWidth + 12
                radius: 4
                color: sourceBox.isCurrent ? Color.focusFill : (sourceBox.selected ? Color.surface : Color.background)
                border.width: 1
                border.color: sourceBox.isCurrent ? Color.accent : (sourceBox.selected ? Color.subtleBorder : "transparent")

                Text {
                    id: sourceBadgeText
                    anchors.centerIn: parent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption - 1
                    font.bold: true
                    color: sourceBox.isCurrent ? Color.accent : Color.popupMuted
                    text: sourceBox.isCurrent ? "ACTIVO" : "ENTRADA"
                }
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
