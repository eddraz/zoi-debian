pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string city: ""
    property string country: ""
    property string countryCode: ""
    property real temp: 0
    property int code: -1
    property bool isDay: true
    property var days: []
    property bool ready: false
    readonly property int degrees: Math.round(temp)
    readonly property string label: ready ? (degrees + "°") : "…"
    readonly property string condition: conditionFor(code)
    readonly property string icon: iconFor(code, isDay)
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

    function iconFor(value, day) {
        const n = Number(value);
        if (!Number.isFinite(n) || n < 0)
            return "cloud";
        if (n === 0)
            return day ? "sun" : "moon";
        if (n <= 3)
            return "cloud";
        if (n <= 48)
            return "fog";
        if (n <= 67 || (n >= 80 && n <= 82))
            return "rain";
        if (n <= 77)
            return "snow";
        if (n >= 95)
            return "storm";
        return "cloud";
    }

    function weekday(dateStr) {
        if (!dateStr)
            return "";
        const d = new Date(dateStr + "T12:00:00");
        return Qt.locale().dayName(d.getDay(), Locale.ShortFormat);
    }

    function refresh() {
        if (fetch.running)
            fetch.running = false;
        startTimer.restart();
    }

    function parse(text) {
        try {
            const raw = String(text || "").trim();
            if (!raw)
                return;
            const data = JSON.parse(raw);
            const tempVal = Number(data.temp);
            if (!data || !Number.isFinite(tempVal))
                return;
            city = data.city || "";
            country = data.country || "";
            countryCode = data.countryCode || "";
            temp = tempVal;
            code = Number.isFinite(Number(data.code)) ? Number(data.code) : -1;
            isDay = !!data.isDay;
            days = Array.isArray(data.days) ? data.days : [];
            ready = true;
        } catch (e) {
        }
    }

    Process {
        id: fetch
        command: ["/usr/bin/python3", "-u", root.helper]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        id: startTimer
        interval: 0
        repeat: false
        onTriggered: fetch.running = true
    }

    Timer {
        interval: 20 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
