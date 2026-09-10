pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string devicePath: "/sys/class/backlight/amdgpu_bl0"
    property int raw: 0
    property int max: 255
    readonly property int percent: max > 0 ? Math.round(raw * 100 / max) : 0

    FileView {
        id: currentFile
        path: root.devicePath + "/brightness"
        watchChanges: true
        printErrors: false
        onLoaded: root.raw = parseInt(text(), 10) || 0
    }

    FileView {
        id: maxFile
        path: root.devicePath + "/max_brightness"
        printErrors: false
        onLoaded: root.max = parseInt(text(), 10) || 255
    }

    Process {
        id: applyProc
        onExited: root.refresh()
    }

    function refresh() {
        currentFile.reload();
        maxFile.reload();
    }

    function setPercent(value) {
        const pct = Math.max(1, Math.min(100, Math.round(value)));
        applyProc.command = ["brightnessctl", "set", pct + "%"];
        applyProc.running = true;
    }

    function adjust(delta) {
        root.setPercent(root.percent + Math.round(delta * 100));
    }
}
