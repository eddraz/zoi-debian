pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    property bool armed: false
    property var exclusiveKeep: null
    property var activePlayer: null

    function isIgnored(p) {
        if (!p)
            return true;
        const identity = (p.identity || "").toLowerCase();
        const title = (p.trackTitle || "").toLowerCase();
        if (title.indexOf("lofi radio") !== -1 || title.indexOf("qs-lofi") !== -1)
            return true;
        if (identity === "mpv" && (title === "" || title.indexOf("lofi") !== -1 || title.indexOf("qs-lofi") !== -1))
            return true;
        return false;
    }

    readonly property var player: {
        const values = Mpris.players ? Mpris.players.values : [];
        const valid = [];
        for (let i = 0; i < values.length; i++) {
            const item = values[i];
            if (item && !root.isIgnored(item))
                valid.push(item);
        }
        if (valid.length === 0)
            return null;

        for (let i = 0; i < valid.length; i++) {
            if (valid[i].isPlaying)
                return valid[i];
        }

        if (root.activePlayer) {
            for (let i = 0; i < valid.length; i++) {
                if (valid[i] === root.activePlayer)
                    return root.activePlayer;
            }
        }

        return valid[0];
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
            if (item && item !== keep && !root.isIgnored(item))
                pauseItem(item);
        }
    }

    function claim(keep) {
        if (!keep || !keep.isPlaying || isIgnored(keep))
            return;
        activePlayer = keep;
        if (Radio.playing)
            Radio.stop();
        pauseOthers(keep);
    }

    function enforceExclusive() {
        if (Radio.starting)
            return;
        const values = Mpris.players ? Mpris.players.values : [];
        const playing = [];
        for (let i = 0; i < values.length; i++) {
            if (values[i] && values[i].isPlaying && !root.isIgnored(values[i]))
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
            Component.onCompleted: {
                if (modelData && !root.isIgnored(modelData))
                    root.claim(modelData);
            }
            function onIsPlayingChanged() {
                if (modelData && !root.isIgnored(modelData) && modelData.isPlaying)
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
