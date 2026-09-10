pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool dnd: false
    property var history: []
    property int unread: 0
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string statePath: stateDir + "/dnd"

    function record(notification) {
        const item = {
            "app": String(notification.appName || "Notification"),
            "summary": String(notification.summary || ""),
            "body": String(notification.body || ""),
            "time": Date.now()
        };
        const next = [item];
        for (let i = 0; i < history.length && next.length < 20; i++)
            next.push(history[i]);
        history = next;
        unread += 1;
    }

    function clearUnread() {
        unread = 0;
    }

    function toggleDnd() {
        dnd = !dnd;
        persist();
    }

    function persist() {
        Quickshell.execDetached(["mkdir", "-p", stateDir]);
        stateFile.setText(dnd ? "1\n" : "0\n");
    }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onLoaded: {
            const value = String(text()).trim();
            if (value === "1")
                root.dnd = true;
            else if (value === "0")
                root.dnd = false;
        }
    }
}
