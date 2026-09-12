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
    property int failCount: 0
    readonly property int degrees: Math.round(temp)
    readonly property string label: ready ? (degrees + "°") : "…"
    readonly property string condition: conditionFor(code)
    readonly property string icon: iconFor(code, isDay)
    readonly property string helper: Quickshell.env("HOME") + "/.local/bin/qs-weather"
    readonly property string cachePath: Quickshell.env("HOME") + "/.cache/quickshell/weather.json"
    readonly property var fetchCmd: ["/usr/bin/python3", "-u", helper]

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
        startTimer.interval = ready ? 250 : 2500;
        startTimer.restart();
    }

    function scheduleRetry() {
        failCount += 1;
        const caps = [3000, 5000, 10000, 20000, 30000, 60000];
        retryTimer.interval = caps[Math.min(failCount - 1, caps.length - 1)];
        retryTimer.restart();
    }

    function parse(text) {
        try {
            const raw = String(text || "").trim();
            if (!raw)
                return false;
            const data = JSON.parse(raw);
            const tempVal = Number(data.temp);
            if (!data || !Number.isFinite(tempVal))
                return false;
            city = data.city || "";
            country = data.country || "";
            countryCode = data.countryCode || "";
            temp = tempVal;
            code = Number.isFinite(Number(data.code)) ? Number(data.code) : -1;
            isDay = !!data.isDay;
            days = Array.isArray(data.days) ? data.days : [];
            ready = true;
            failCount = 0;
            return true;
        } catch (e) {
            return false;
        }
    }

    FileView {
        id: cacheFile
        path: root.cachePath
        watchChanges: true
        printErrors: false
        onLoaded: {
            if (!root.ready)
                root.parse(text());
        }
    }

    Process {
        id: fetch
        command: root.fetchCmd
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (!root.parse(text))
                    root.scheduleRetry();
            }
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const msg = String(text || "").trim();
                if (msg)
                    console.warn("qs-weather:", msg);
            }
        }
        onExited: code => {
            if (code !== 0 && !root.ready)
                root.scheduleRetry();
        }
    }

    Timer {
        id: startTimer
        interval: 2500
        repeat: false
        onTriggered: fetch.exec(root.fetchCmd)
    }

    Timer {
        id: retryTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (!fetch.running)
                root.refresh();
        }
    }

    Timer {
        interval: 20 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "weather"
        function refresh(): string {
            root.refresh();
            return "ok";
        }
    }

    Component.onCompleted: root.refresh()
}
