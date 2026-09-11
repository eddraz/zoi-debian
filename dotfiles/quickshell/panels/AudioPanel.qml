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
        if (count <= 0) return;
        cursor = back ? (cursor - 1 + count) % count : (cursor + 1) % count;
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

    // ---- Output section ----
    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Output"
    }

    VolumeSlider {
        selected: root.cursor === 0
        slot: 0
        label: "VOL"
        percent: Audio.percent
        muted: Audio.muted
        accentColor: Color.accent
        onSetVolume: fraction => {
            root.cursor = 0;
            Audio.setVolume(fraction);
        }
    }

    // Mute output button
    ActionListItem {
        selected: root.cursor === 1
        slot: 1
        highlighted: Audio.muted
        useHighlightBg: true
        highlightBg: Color.urgent
        title: "Silenciar Salida"
        description: Audio.muted ? "Audio actualmente silenciado" : "Audio reproduciéndose con normalidad"
        badge: Audio.muted ? "MUTED" : "ON"
        badgeTextColor: Audio.muted ? Color.urgent : Color.popupMuted
        onClicked: {
            root.cursor = 1;
            Audio.toggleMute();
        }
    }

    // Sink devices
    Repeater {
        model: Audio.sinks

        ActionListItem {
            required property var modelData
            required property int index

            width: root.width
            selected: root.cursor === root.sinkStart + index
            slot: root.sinkStart + index
            highlighted: Audio.sink === modelData
            title: modelData.description || modelData.nickname || modelData.name || "Salida de audio"
            description: Audio.sink === modelData ? "Dispositivo principal de salida" : "Haz clic para usar como salida"
            badge: Audio.sink === modelData ? "ACTIVO" : "SALIDA"
            onClicked: {
                root.cursor = root.sinkStart + index;
                Audio.setSink(modelData);
            }
        }
    }

    // ---- Microphone section ----
    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Microphone"
    }

    VolumeSlider {
        selected: root.cursor === root.micVol
        slot: root.micVol
        label: "MIC"
        percent: Audio.sourcePercent
        muted: Audio.sourceMuted
        accentColor: Color.peach
        ready: Audio.sourceReady
        onSetVolume: fraction => {
            root.cursor = root.micVol;
            Audio.setSourceVolume(fraction);
        }
    }

    // Mute mic button
    ActionListItem {
        selected: root.cursor === root.micMute
        slot: root.micMute
        highlighted: Audio.sourceMuted
        useHighlightBg: true
        highlightBg: Color.urgent
        title: "Silenciar Micrófono"
        description: Audio.sourceMuted ? "Micrófono actualmente silenciado" : "Captura de voz activa"
        badge: Audio.sourceMuted ? "MUTED" : "ON"
        badgeTextColor: Audio.sourceMuted ? Color.urgent : Color.popupMuted
        onClicked: {
            root.cursor = root.micMute;
            Audio.toggleSourceMute();
        }
    }

    // Source devices
    Repeater {
        model: Audio.sources

        ActionListItem {
            required property var modelData
            required property int index

            width: root.width
            selected: root.cursor === root.sourceStart + index
            slot: root.sourceStart + index
            highlighted: Audio.source === modelData
            title: modelData.description || modelData.nickname || modelData.name || "Micrófono"
            description: Audio.source === modelData ? "Dispositivo principal de grabación" : "Haz clic para usar como micrófono"
            badge: Audio.source === modelData ? "ACTIVO" : "ENTRADA"
            onClicked: {
                root.cursor = root.sourceStart + index;
                Audio.setSource(modelData);
            }
        }
    }
}
