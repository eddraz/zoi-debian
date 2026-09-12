pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string current: ""
    property var images: []
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string statePath: stateDir + "/wallpaper"
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/qs-wallpaper"

    function refresh() {
        if (!listProc.running)
            listProc.running = true;
    }

    function apply(path) {
        if (!path)
            return;
        current = path;
        persist();
        Quickshell.execDetached([helper, "set", path]);
        Themes.currentId = "wallpaper";
        Themes.refreshFromWallpaper(path);
    }

    function persist() {
        Quickshell.execDetached(["mkdir", "-p", stateDir]);
        stateFile.setText(current + "\n");
    }

    function parseList(text) {
        const lines = String(text || "").split("\n");
        const list = [];
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line)
                list.push(line);
        }
        images = list;
    }

    FileView {
        id: stateFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onLoaded: {
            const value = String(text()).trim();
            if (value === "")
                return;
            root.current = value;
            Themes.wallpaperPath = value;
            // Only re-extract when the selector's active palette is Wallpaper.
            if (Themes.currentId === "wallpaper" && !Themes.wallpaperFromDisk)
                Themes.refreshFromWallpaper(value);
        }
    }

    Process {
        id: listProc
        command: [root.helper, "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseList(text)
        }
    }

    Component.onCompleted: root.refresh()
}
