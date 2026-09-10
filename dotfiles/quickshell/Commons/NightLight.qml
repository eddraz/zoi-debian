pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool enabled: false
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string statePath: stateDir + "/night-light"

    function toggle() {
        enabled = !enabled;
        persist();
    }

    function persist() {
        Quickshell.execDetached(["mkdir", "-p", stateDir]);
        stateFile.setText(enabled ? "1\n" : "0\n");
    }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onLoaded: {
            const value = String(text()).trim();
            if (value === "1")
                root.enabled = true;
            else if (value === "0")
                root.enabled = false;
        }
    }
}
