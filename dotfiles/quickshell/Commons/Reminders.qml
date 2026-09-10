pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int count: 0
    property var items: []
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/qs-reminder"

    function refresh() {
        if (!listProc.running)
            listProc.running = true;
    }

    function add(minutes, message) {
        const args = [helper, "add", String(minutes)];
        if (message)
            args.push(message);
        Quickshell.execDetached(args);
        Qt.callLater(refresh);
        later.restart();
    }

    function cancel(id) {
        Quickshell.execDetached([helper, "cancel", id]);
        Qt.callLater(refresh);
        later.restart();
    }

    function parse(text) {
        try {
            const data = JSON.parse(String(text || "{}"));
            count = Number(data.count || 0);
            items = Array.isArray(data.items) ? data.items : [];
        } catch (e) {
        }
    }

    Process {
        id: listProc
        command: [root.helper, "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        id: later
        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
