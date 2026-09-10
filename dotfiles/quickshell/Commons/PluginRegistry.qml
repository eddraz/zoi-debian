pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell/shell.json"

    property var layout: defaultLayout
    property var disabled: []
    property int revision: 0

    Timer {
        id: autoSaveTimer
        interval: 150
        repeat: false
        onTriggered: root.writeShell()
    }

    function scheduleSave() {
        autoSaveTimer.restart();
    }

    readonly property var defaultLayout: ({
        "left": ["session", "apps", "workspaces", "window"],
        "center": ["reminders", "clock", "weather"],
        "right": ["keyboard", "media", "audio", "power", "bluetooth", "network", "notifs", "dnd", "tray"]
    })

    readonly property var catalog: ({
        "apps": {
            "kinds": ["bar-widget", "panel"],
            "label": "Apps",
            "source": "../widgets/Apps.qml",
            "popup": "apps",
            "panel": "../panels/AppsPanel.qml",
            "title": "Native Apps",
            "defaultSection": "left",
            "cardWidth": 300
        },
        "workspaces": {
            "kinds": ["bar-widget"],
            "label": "Workspaces",
            "source": "../widgets/Workspaces.qml",
            "defaultSection": "left"
        },
        "window": {
            "kinds": ["bar-widget"],
            "label": "Window",
            "source": "../widgets/ActiveWindow.qml",
            "defaultSection": "left"
        },
        "clock": {
            "kinds": ["bar-widget", "panel"],
            "label": "Clock",
            "source": "../widgets/Clock.qml",
            "popup": "calendar",
            "panel": "../panels/CalendarPanel.qml",
            "centerCard": true,
            "defaultSection": "center"
        },
        "tray": {
            "kinds": ["bar-widget"],
            "label": "Tray",
            "source": "../widgets/Tray.qml",
            "defaultSection": "right"
        },
        "keyboard": {
            "kinds": ["bar-widget", "panel"],
            "label": "Keyboard",
            "source": "../widgets/KbLayout.qml",
            "popup": "keyboard",
            "panel": "../panels/KeyboardPanel.qml",
            "title": "Keyboard",
            "defaultSection": "right"
        },
        "weather": {
            "kinds": ["bar-widget", "panel"],
            "label": "Weather",
            "source": "../widgets/Weather.qml",
            "popup": "weather",
            "panel": "../panels/WeatherPanel.qml",
            "title": "Weather",
            "defaultSection": "center"
        },
        "media": {
            "kinds": ["bar-widget", "panel"],
            "label": "Media",
            "source": "../widgets/Player.qml",
            "popup": "media",
            "panel": "../panels/MediaPanel.qml",
            "title": "Media",
            "defaultSection": "right"
        },
        "reminders": {
            "kinds": ["bar-widget"],
            "label": "Reminders",
            "source": "../widgets/Reminder.qml",
            "ipc": ["reminders", "toggle"],
            "defaultSection": "center"
        },
        "dnd": {
            "kinds": ["bar-widget"],
            "label": "DND",
            "source": "../widgets/Dnd.qml",
            "defaultSection": "right"
        },
        "notifs": {
            "kinds": ["bar-widget", "panel"],
            "label": "Notifications",
            "source": "../widgets/NotifBell.qml",
            "popup": "notifs",
            "panel": "../panels/NotifPanel.qml",
            "title": "Notifications",
            "defaultSection": "right"
        },
        "network": {
            "kinds": ["bar-widget", "panel"],
            "label": "Network",
            "source": "../widgets/Network.qml",
            "popup": "network",
            "panel": "../panels/NetworkPanel.qml",
            "title": "Network",
            "defaultSection": "right"
        },
        "bluetooth": {
            "kinds": ["bar-widget", "panel"],
            "label": "Bluetooth",
            "source": "../widgets/Bluetooth.qml",
            "popup": "bluetooth",
            "panel": "../panels/BluetoothPanel.qml",
            "title": "Bluetooth",
            "defaultSection": "right"
        },
        "audio": {
            "kinds": ["bar-widget", "panel"],
            "label": "Audio",
            "source": "../widgets/Volume.qml",
            "popup": "audio",
            "panel": "../panels/AudioPanel.qml",
            "title": "Audio",
            "defaultSection": "right"
        },
        "power": {
            "kinds": ["bar-widget", "panel"],
            "label": "Power",
            "source": "../widgets/Battery.qml",
            "popup": "power",
            "panel": "../panels/PowerPanel.qml",
            "title": "Power",
            "defaultSection": "right"
        },
        "session": {
            "kinds": ["bar-widget", "panel"],
            "label": "Session",
            "source": "../widgets/Session.qml",
            "popup": "session",
            "panel": "../panels/SessionPanel.qml",
            "title": "Session",
            "defaultSection": "left"
        },
        "bar": {
            "kinds": ["panel"],
            "popup": "bar",
            "panel": "../panels/BarEditorPanel.qml",
            "title": "Bar",
            "centerCard": true,
            "cardWidth": 480
        },
        "keys": {
            "kinds": ["panel"],
            "popup": "keys",
            "panel": "../panels/KeysPanel.qml",
            "title": "Shortcuts",
            "centerCard": true,
            "cardWidth": 420
        },
        "wallpaper": {
            "kinds": ["panel"],
            "popup": "wallpaper",
            "panel": "../panels/WallpaperPanel.qml",
            "title": "Wallpaper",
            "centerCard": true,
            "cardWidth": 420
        },
        "theme": {
            "kinds": ["panel"],
            "popup": "theme",
            "panel": "../panels/ThemePanel.qml",
            "title": "Theme",
            "centerCard": true,
            "cardWidth": 420
        },
        "osd": {
            "kinds": ["service"],
            "source": "../Osd.qml"
        },
        "launcher": {
            "kinds": ["overlay"],
            "source": "../Launcher.qml"
        },
        "notifications": {
            "kinds": ["service"],
            "source": "../Notifications.qml"
        },
        "lock": {
            "kinds": ["service"],
            "source": "../Lock.qml"
        },
        "idle": {
            "kinds": ["service"],
            "source": "../Idle.qml"
        },
        "clipboard": {
            "kinds": ["overlay"],
            "source": "../Clipboard.qml"
        },
        "nightlight": {
            "kinds": ["service"],
            "source": "../NightLight.qml"
        },
        "polkit": {
            "kinds": ["service"],
            "source": "../Polkit.qml"
        },
        "emojis": {
            "kinds": ["overlay"],
            "source": "../Emojis.qml"
        },
        "media-arm": {
            "kinds": ["overlay"],
            "source": "../MediaArm.qml"
        },
        "reminders-overlay": {
            "kinds": ["overlay"],
            "source": "../ReminderOverlay.qml"
        }
    })

    readonly property var hostOrder: ["osd", "launcher", "notifications", "lock", "idle", "clipboard", "nightlight", "polkit", "emojis", "media-arm", "reminders-overlay"]

    readonly property var leftIds: {
        revision;
        return idsFor("left");
    }
    readonly property var centerIds: {
        revision;
        return idsFor("center");
    }
    readonly property var rightIds: {
        revision;
        return idsFor("right");
    }
    readonly property var hostIds: {
        const _ = root.revision;
        const out = [];
        for (let i = 0; i < hostOrder.length; i++) {
            const id = hostOrder[i];
            if (root.isDisabled(id))
                continue;
            const entry = catalog[id];
            if (entry && entry.source)
                out.push(id);
        }
        return out;
    }

    function isDisabled(id) {
        const list = disabled || [];
        return list.indexOf(id) !== -1;
    }

    function idsFor(section) {
        const _ = root.revision;
        const fromLayout = layout && layout[section];
        const ids = (fromLayout && fromLayout.length !== undefined) ? fromLayout : defaultLayout[section];
        const out = [];
        for (let i = 0; i < ids.length; i++) {
            const id = String(ids[i] || "");
            if (!id || root.isDisabled(id))
                continue;
            const entry = catalog[id];
            if (!entry || !entry.source)
                continue;
            if ((entry.kinds || []).indexOf("bar-widget") === -1)
                continue;
            out.push(id);
        }
        return out;
    }

    function widgetUrl(id) {
        const entry = catalog[String(id)];
        if (!entry || !entry.source)
            return "";
        return Qt.resolvedUrl(entry.source);
    }

    function hostUrl(id) {
        return root.widgetUrl(id);
    }

    function widgetMeta(id) {
        return catalog[String(id)] || null;
    }

    function panelByPopup(popup) {
        const name = String(popup || "");
        if (!name)
            return null;
        for (const id in catalog) {
            const entry = catalog[id];
            if (!entry || entry.popup !== name || !entry.panel)
                continue;
            if (root.isDisabled(id))
                return null;
            return entry;
        }
        return null;
    }

    function panelUrl(popup) {
        const entry = root.panelByPopup(popup);
        if (!entry)
            return "";
        return Qt.resolvedUrl(entry.panel);
    }

    function panelMeta(popup) {
        return root.panelByPopup(popup) || ({});
    }

    readonly property var sections: ["left", "center", "right"]

    function sectionIndexOf(id) {
        for (let s = 0; s < sections.length; s++) {
            const arr = layout && layout[sections[s]];
            if (Array.isArray(arr) && arr.indexOf(id) !== -1)
                return s;
        }
        return -1;
    }

    function sectionOf(id) {
        const idx = sectionIndexOf(id);
        return idx >= 0 ? sections[idx] : null;
    }

    function orderedIds(section) {
        const arr = (layout && Array.isArray(layout[section])) ? layout[section] : [];
        return arr.slice();
    }

    function availableBarIds(section) {
        const current = new Set();
        for (let s = 0; s < sections.length; s++) {
            const arr = layout && layout[sections[s]];
            if (Array.isArray(arr))
                for (let i = 0; i < arr.length; i++)
                    current.add(String(arr[i]));
        }
        const out = [];
        for (const id in catalog) {
            const entry = catalog[id];
            if (!entry || !entry.source)
                continue;
            if ((entry.kinds || []).indexOf("bar-widget") === -1)
                continue;
            if (current.has(id))
                continue;
            out.push(id);
        }
        return out;
    }

    function _mutateLayout(fn) {
        const next = {
            "left": orderedIds("left"),
            "center": orderedIds("center"),
            "right": orderedIds("right")
        };
        fn(next);
        if (JSON.stringify(next) === JSON.stringify(layout))
            return false;
        layout = next;
        revision++;
        scheduleSave();
        return true;
    }

    function moveWithinSection(section, fromIdx, toIdx) {
        return _mutateLayout(function (next) {
            const arr = next[section];
            if (!Array.isArray(arr) || fromIdx < 0 || fromIdx >= arr.length)
                return;
            toIdx = Math.max(0, Math.min(arr.length - 1, toIdx));
            if (fromIdx === toIdx)
                return;
            const item = arr.splice(fromIdx, 1)[0];
            arr.splice(toIdx, 0, item);
        });
    }

    function moveToSection(id, fromSection, toSection, toIdx) {
        if (!toSection)
            return false;
        togglePlugin(id, true);
        return _mutateLayout(function (next) {
            for (let s = 0; s < sections.length; s++) {
                const secList = next[sections[s]];
                if (Array.isArray(secList)) {
                    const i = secList.indexOf(id);
                    if (i >= 0)
                        secList.splice(i, 1);
                }
            }
            const dst = next[toSection];
            if (!Array.isArray(dst))
                return;
            let idx = (typeof toIdx === "number") ? toIdx : dst.length;
            idx = Math.max(0, Math.min(dst.length, idx));
            dst.splice(idx, 0, id);
        });
    }

    function moveWidget(id, toSection, toIdx) {
        return moveToSection(id, null, toSection, toIdx);
    }

    function shiftWidgetSection(id, dir) {
        const curIdx = sectionIndexOf(id);
        if (curIdx < 0)
            return false;
        const targetIdx = Math.max(0, Math.min(sections.length - 1, curIdx + dir));
        if (targetIdx === curIdx)
            return false;
        return moveToSection(id, sections[curIdx], sections[targetIdx]);
    }

    function togglePlugin(id, enabled) {
        const list = disabled.slice();
        const i = list.indexOf(id);
        if (enabled && i !== -1)
            list.splice(i, 1);
        if (!enabled && i === -1)
            list.push(id);
        if (JSON.stringify(list) === JSON.stringify(disabled))
            return false;
        disabled = list;
        revision++;
        scheduleSave();
        return true;
    }

    function writeShell() {
        autoSaveTimer.stop();
        const payload = {
            "version": 1,
            "bar": { "layout": { "left": orderedIds("left"), "center": orderedIds("center"), "right": orderedIds("right") } },
            "disabledPlugins": disabled.slice()
        };
        const json = JSON.stringify(payload, null, 2);
        const script = "p=\"$HOME/.config/quickshell/shell.json\"; " +
                          "tmp=\"${p}.tmp\"; " +
                          "printf '%s\\n' \"$1\" > \"$tmp\"; " +
                          "mv \"$tmp\" \"$p\"";
        Quickshell.execDetached(["bash", "-c", script, "qs-bar-write", json]);
        return payload;
    }

    function applyConfig(text) {
        const raw = String(text || "").trim();
        if (!raw)
            return;
        try {
            const parsed = JSON.parse(raw);
            if (!parsed || parsed.version !== 1)
                return;
            const nextLayout = (parsed.bar && parsed.bar.layout) ? parsed.bar.layout : defaultLayout;
            const nextDisabled = Array.isArray(parsed.disabledPlugins) ? parsed.disabledPlugins : [];
            if (JSON.stringify(nextLayout) === JSON.stringify(layout) && JSON.stringify(nextDisabled) === JSON.stringify(disabled))
                return;
            layout = nextLayout;
            disabled = nextDisabled;
            revision++;
        } catch (e) {
            console.warn("PluginRegistry: shell.json parse failed:", e);
        }
    }

    Component.onDestruction: {
        if (autoSaveTimer.running)
            root.writeShell();
    }

    FileView {
        path: root.configPath
        watchChanges: true
        printErrors: false
        onLoaded: root.applyConfig(text())
        onFileChanged: reload()
    }
}
