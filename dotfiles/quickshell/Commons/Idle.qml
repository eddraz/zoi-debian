pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool stayAwake: false
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string statePath: stateDir + "/stay-awake"

    function toggle() {
        stayAwake = !stayAwake;
        persist();
    }

    function persist() {
        Quickshell.execDetached(["mkdir", "-p", stateDir]);
        stateFile.setText(stayAwake ? "1\n" : "0\n");
    }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onLoaded: {
            const value = String(text()).trim();
            if (value === "1")
                root.stayAwake = true;
            else if (value === "0")
                root.stayAwake = false;
        }
    }
}
