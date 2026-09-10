pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string deviceName: ""
    property string deviceClass: "backlight"
    readonly property string devicePath: deviceName !== "" ? ("/sys/class/" + deviceClass + "/" + deviceName) : ""
    property int raw: 0
    property int max: 255
    readonly property int percent: max > 0 ? Math.round(raw * 100 / max) : 0

    Process {
        id: detectProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line) return;
                const parts = line.split(",");
                if (parts.length >= 5) {
                    root.deviceName = parts[0];
                    root.deviceClass = parts[1] || "backlight";
                    root.raw = parseInt(parts[2], 10) || 0;
                    root.max = parseInt(parts[4], 10) || 255;
                }
            }
        }
    }

    FileView {
        id: currentFile
        path: root.devicePath !== "" ? (root.devicePath + "/brightness") : ""
        watchChanges: root.devicePath !== ""
        printErrors: false
        onLoaded: {
            const val = parseInt(text(), 10);
            if (!isNaN(val)) root.raw = val;
        }
    }

    FileView {
        id: maxFile
        path: root.devicePath !== "" ? (root.devicePath + "/max_brightness") : ""
        printErrors: false
        onLoaded: {
            const val = parseInt(text(), 10);
            if (!isNaN(val) && val > 0) root.max = val;
        }
    }

    Process {
        id: applyProc
        onExited: root.refresh()
    }

    function refresh() {
        if (root.devicePath !== "") {
            currentFile.reload();
            maxFile.reload();
        } else {
            detectProc.running = true;
        }
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
