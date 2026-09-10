pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink && sink.audio ? sink.audio : null
    readonly property real volume: audio ? audio.volume : 0
    readonly property bool muted: audio ? audio.muted : false
    readonly property bool ready: audio !== null
    readonly property int percent: Math.round(Math.max(0, Math.min(volume, 1)) * 100)

    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sourceAudio: source && source.audio ? source.audio : null
    readonly property real sourceVolume: sourceAudio ? sourceAudio.volume : 0
    readonly property bool sourceMuted: sourceAudio ? sourceAudio.muted : false
    readonly property bool sourceReady: sourceAudio !== null
    readonly property int sourcePercent: Math.round(Math.max(0, Math.min(sourceVolume, 1)) * 100)

    readonly property var sinks: {
        const values = Pipewire.nodes ? Pipewire.nodes.values : [];
        const list = [];
        for (let i = 0; i < values.length; i++) {
            const node = values[i];
            if (node && node.isSink && !node.isStream)
                list.push(node);
        }
        return list;
    }

    readonly property var sources: {
        const values = Pipewire.nodes ? Pipewire.nodes.values : [];
        const list = [];
        for (let i = 0; i < values.length; i++) {
            const node = values[i];
            if (!node || node.isSink || node.isStream)
                continue;
            if (String(node.name || "") === "quickshell")
                continue;
            list.push(node);
        }
        return list;
    }

    PwObjectTracker {
        objects: {
            const list = [];
            if (root.sink)
                list.push(root.sink);
            if (root.source)
                list.push(root.source);
            const values = Pipewire.nodes ? Pipewire.nodes.values : [];
            for (let i = 0; i < values.length; i++) {
                const node = values[i];
                if (!node || node.isStream)
                    continue;
                list.push(node);
            }
            return list;
        }
    }

    function setVolume(value) {
        if (!root.audio)
            return;
        root.audio.volume = Math.max(0, Math.min(1, value));
    }

    function adjust(delta) {
        root.setVolume(root.volume + delta);
    }

    function toggleMute() {
        if (!root.audio)
            return;
        root.audio.muted = !root.audio.muted;
    }

    function setSink(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    function setSourceVolume(value) {
        if (!root.sourceAudio)
            return;
        root.sourceAudio.volume = Math.max(0, Math.min(1, value));
    }

    function adjustSource(delta) {
        root.setSourceVolume(root.sourceVolume + delta);
    }

    function toggleSourceMute() {
        if (!root.sourceAudio)
            return;
        root.sourceAudio.muted = !root.sourceAudio.muted;
    }

    function setSource(node) {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }
}
