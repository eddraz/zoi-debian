pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    property bool armed: false
    property var exclusiveKeep: null

    readonly property var player: {
        const values = Mpris.players ? Mpris.players.values : [];
        let fallback = null;
        for (let i = 0; i < values.length; i++) {
            const item = values[i];
            if (!item)
                continue;
            if (item.isPlaying)
                return item;
            if (!fallback)
                fallback = item;
        }
        return fallback;
    }

    readonly property bool active: player !== null
    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album: player ? (player.trackAlbum || "") : ""
    readonly property string identity: player ? (player.identity || "") : ""
    readonly property bool playing: player ? player.isPlaying : false

    function toggle() {
        if (player)
            player.togglePlaying();
    }

    function next() {
        if (player && player.canGoNext)
            player.next();
    }

    function previous() {
        if (player && player.canGoPrevious)
            player.previous();
    }

    function arm() {
        Popups.closeAll();
        armed = true;
    }

    function disarm() {
        armed = false;
    }

    function toggleArm() {
        if (armed)
            disarm();
        else
            arm();
    }

    function pauseItem(item) {
        if (!item || !item.isPlaying)
            return;
        if (item.canPause)
            item.pause();
        else if (item.canTogglePlaying)
            item.togglePlaying();
    }

    function pauseOthers(keep) {
        exclusiveKeep = keep;
        const values = Mpris.players ? Mpris.players.values : [];
        for (let i = 0; i < values.length; i++) {
            const item = values[i];
            if (item && item !== keep)
                pauseItem(item);
        }
    }

    function claim(keep) {
        if (!keep || !keep.isPlaying)
            return;
        pauseOthers(keep);
    }

    function enforceExclusive() {
        if (Radio.starting)
            return;
        const values = Mpris.players ? Mpris.players.values : [];
        const playing = [];
        for (let i = 0; i < values.length; i++) {
            if (values[i] && values[i].isPlaying)
                playing.push(values[i]);
        }
        if (playing.length <= 1)
            return;
        let keep = exclusiveKeep;
        let found = false;
        for (let i = 0; i < playing.length; i++) {
            if (playing[i] === keep)
                found = true;
        }
        if (!found)
            keep = playing[playing.length - 1];
        pauseOthers(keep);
    }

    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            Component.onCompleted: root.claim(modelData)
            function onIsPlayingChanged() {
                if (modelData && modelData.isPlaying)
                    root.claim(modelData);
            }
        }
    }

    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: root.enforceExclusive()
    }

    IpcHandler {
        target: "media"

        function arm(): string {
            root.arm();
            return "ok";
        }

        function disarm(): string {
            root.disarm();
            return "ok";
        }

        function toggleArm(): string {
            root.toggleArm();
            return "ok";
        }
    }
}
