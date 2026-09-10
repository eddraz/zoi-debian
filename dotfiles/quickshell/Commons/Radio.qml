pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool playing: false
    property bool starting: false
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/qs-lofi"

    function toggle() {
        if (starting)
            return;
        if (playing) {
            Quickshell.execDetached([helper]);
            playing = false;
            return;
        }
        starting = true;
        Quickshell.execDetached([helper]);
        startGuard.restart();
        probeTimer.restart();
    }

    function refresh() {
        if (!probe.running)
            probe.running = true;
    }

    Process {
        id: probe
        command: ["pgrep", "-f", "mpv.*qs-lofi"]
        onExited: code => {
            const on = code === 0;
            root.playing = on;
            if (on)
                root.starting = false;
        }
    }

    Timer {
        id: probeTimer
        interval: 500
        onTriggered: root.refresh()
    }

    Timer {
        id: startGuard
        interval: 2500
        onTriggered: root.starting = false
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
