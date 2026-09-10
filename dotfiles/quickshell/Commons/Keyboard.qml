pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int index: 0
    property var codes: ["latam", "us"]
    property var labels: ["LATAM", "US"]
    property var names: ["Spanish (Latin American)", "English (US)"]
    readonly property string label: (labels && labels.length > 0) ? labels[Math.max(0, Math.min(index, labels.length - 1))] : "US"
    readonly property string name: (names && names.length > 0) ? names[Math.max(0, Math.min(index, names.length - 1))] : "English"

    function cycle() {
        if (!labels || labels.length === 0)
            return;
        const nextIdx = (index + 1) % labels.length;
        setIndex(nextIdx);
    }

    function setIndex(value) {
        if (!labels || value < 0 || value >= labels.length)
            return;
        index = value;
        Quickshell.execDetached(["swaymsg", "input", "type:keyboard", "xkb_switch_layout", String(value)]);
        Qt.callLater(refresh);
    }

    function refresh() {
        if (!query.running)
            query.running = true;
    }

    function deriveLabel(fullName) {
        const s = String(fullName || "").toLowerCase();
        if (s.indexOf("latin") >= 0 || s.indexOf("latam") >= 0)
            return "LATAM";
        if (s.indexOf("spanish") >= 0 || s.indexOf("español") >= 0)
            return "ES";
        if (s.indexOf("us") >= 0 || s.indexOf("united states") >= 0)
            return "US";
        if (s.indexOf("english") >= 0 || s.indexOf("inglés") >= 0)
            return "EN";
        if (s.indexOf("french") >= 0 || s.indexOf("français") >= 0)
            return "FR";
        if (s.indexOf("german") >= 0 || s.indexOf("deutsch") >= 0)
            return "DE";
        if (s.indexOf("portuguese") >= 0 || s.indexOf("português") >= 0)
            return "PT";
        if (s.indexOf("russian") >= 0 || s.indexOf("русский") >= 0)
            return "RU";
        if (s.indexOf("japanese") >= 0)
            return "JP";
        return String(fullName || "").slice(0, 2).toUpperCase();
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
                if (Array.isArray(item.xkb_layout_names) && item.xkb_layout_names.length > 0) {
                    names = item.xkb_layout_names;
                    const newLabels = [];
                    for (let j = 0; j < item.xkb_layout_names.length; j++) {
                        newLabels.push(deriveLabel(item.xkb_layout_names[j]));
                    }
                    labels = newLabels;
                }
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

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
