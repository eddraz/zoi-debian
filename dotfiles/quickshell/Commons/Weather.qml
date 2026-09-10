pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string city: ""
    property real temp: 0
    property int code: -1
    property bool isDay: true
    property var days: []
    property bool ready: false
    readonly property int degrees: Math.round(temp)
    readonly property string label: ready ? (degrees + "°") : "…"
    readonly property string condition: conditionFor(code)
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/qs-weather"

    function conditionFor(value) {
        const n = Number(value);
        if (n === 0)
            return isDay ? "Clear" : "Clear night";
        if (n <= 3)
            return "Cloudy";
        if (n <= 48)
            return "Fog";
        if (n <= 57)
            return "Drizzle";
        if (n <= 67)
            return "Rain";
        if (n <= 77)
            return "Snow";
        if (n <= 82)
            return "Showers";
        if (n >= 95)
            return "Storm";
        return "Weather";
    }

    function weekday(dateStr) {
        if (!dateStr)
            return "";
        const d = new Date(dateStr + "T12:00:00");
        return Qt.locale().dayName(d.getDay(), Locale.ShortFormat);
    }

    function refresh() {
        if (!fetch.running)
            fetch.running = true;
    }

    function parse(text) {
        try {
            const data = JSON.parse(String(text || "{}"));
            city = data.city || "";
            temp = Number(data.temp || 0);
            code = Number(data.code);
            isDay = !!data.isDay;
            days = Array.isArray(data.days) ? data.days : [];
            ready = true;
        } catch (e) {
        }
    }

    Process {
        id: fetch
        command: [root.helper]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        interval: 20 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
