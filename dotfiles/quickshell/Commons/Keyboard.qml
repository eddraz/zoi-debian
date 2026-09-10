pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int index: 0
    readonly property var codes: ["latam", "us"]
    readonly property var labels: ["LATAM", "US"]
    readonly property var names: ["Spanish (Latin American)", "English (US)"]
    readonly property string label: labels[Math.max(0, Math.min(index, labels.length - 1))]
    readonly property string name: names[Math.max(0, Math.min(index, names.length - 1))]

    function cycle() {
        index = (index + 1) % codes.length;
        Quickshell.execDetached(["swaymsg", "input", "type:keyboard", "xkb_switch_layout", "next"]);
        Qt.callLater(refresh);
    }

    function setIndex(value) {
        if (value < 0 || value >= codes.length)
            return;
        index = value;
        Quickshell.execDetached(["swaymsg", "input", "type:keyboard", "xkb_switch_layout", String(value)]);
    }

    function refresh() {
        if (!query.running)
            query.running = true;
    }

    function parse(text) {
        try {
            const data = JSON.parse(String(text || "[]"));
            for (let i = 0; i < data.length; i++) {
                const item = data[i];
                if (!item || item.type !== "keyboard")
                    continue;
                const id = String(item.identifier || "");
                if (id.indexOf("Translated") < 0 && id.indexOf("keyboard") < 0)
                    continue;
                if (typeof item.xkb_active_layout_index === "number") {
                    index = item.xkb_active_layout_index;
                    return;
                }
            }
        } catch (e) {
        }
    }

    Process {
        id: query
        command: ["swaymsg", "-t", "get_inputs"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Component.onCompleted: root.refresh()
}
