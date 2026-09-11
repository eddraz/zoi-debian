pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "KeysCombo.js" as Combo

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string storePath: home + "/.config/zoi/keys.json"
    readonly property string applyPath: home + "/.config/zoi/keys-apply.json"
    property var overrides: ({})
    property int revision: 0

    readonly property var catalog: [
        { "id": "terminal", "section": "Apps", "label": "Terminal (foot + fish)", "defaultKeys": "Super+Return", "command": "exec /usr/bin/foot /usr/bin/fish" },
        { "id": "browser", "section": "Apps", "label": "Default browser", "defaultKeys": "Super+Shift+Return", "command": "exec {home}/.local/bin/qs-browser" },
        { "id": "files", "section": "Apps", "label": "File manager (Yazi)", "defaultKeys": "Super+Shift+F", "command": "exec {home}/.local/bin/qs-files" },
        { "id": "keys", "section": "Apps", "label": "Shortcuts overlay", "defaultKeys": "Super+/", "command": "exec /usr/bin/qs ipc call popups toggle keys" },
        { "id": "trigger", "section": "Apps", "label": "Trigger", "defaultKeys": "Super+G", "command": "exec /usr/bin/qs ipc call popups toggle trigger" },
        { "id": "launcher", "section": "Apps", "label": "App launcher", "defaultKeys": "Super+Space", "command": "exec /usr/bin/qs ipc call launcher toggle" },
        { "id": "apps-panel", "section": "Apps", "label": "Menú principal", "defaultKeys": "Super+Alt+Space", "command": "exec /usr/bin/qs ipc call popups toggle apps" },
        { "id": "clipboard", "section": "Apps", "label": "Clipboard history", "defaultKeys": "Super+V", "command": "exec /usr/bin/qs ipc call clipboard toggle" },
        { "id": "emojis", "section": "Apps", "label": "Emoji picker", "defaultKeys": "Super+.", "command": "exec /usr/bin/qs ipc call emojis toggle" },
        { "id": "kill-window", "section": "Apps", "label": "Close focused window", "defaultKeys": "Super+W", "command": "kill" },
        { "id": "kill-workspace", "section": "Apps", "label": "Close all windows on workspace", "defaultKeys": "Super+Shift+W", "command": "[workspace=\"__focused__\"] kill" },
        { "id": "reload", "section": "Apps", "label": "Reload Sway", "defaultKeys": "Super+Shift+C", "command": "reload" },
        { "id": "exit-sway", "section": "Apps", "label": "Exit Sway", "defaultKeys": "Super+Shift+E", "command": "exec swaynag -t warning -m 'Exit sway?' -B 'Yes' 'swaymsg exit'" },
        { "id": "session", "section": "Apps", "label": "Session menu", "defaultKeys": "Super+Escape", "command": "exec /usr/bin/qs ipc call session toggle" },
        { "id": "focus-left", "section": "Focus", "label": "Focus left", "defaultKeys": "Super+H", "command": "focus left" },
        { "id": "focus-down", "section": "Focus", "label": "Focus down", "defaultKeys": "Super+J", "command": "focus down" },
        { "id": "focus-up", "section": "Focus", "label": "Focus up", "defaultKeys": "Super+K", "command": "focus up" },
        { "id": "focus-right", "section": "Focus", "label": "Focus right", "defaultKeys": "Super+L", "command": "focus right" },
        { "id": "focus-left-arrow", "section": "Focus", "label": "Focus left (arrow)", "defaultKeys": "Super+Left", "command": "focus left" },
        { "id": "focus-down-arrow", "section": "Focus", "label": "Focus down (arrow)", "defaultKeys": "Super+Down", "command": "focus down" },
        { "id": "focus-up-arrow", "section": "Focus", "label": "Focus up (arrow)", "defaultKeys": "Super+Up", "command": "focus up" },
        { "id": "focus-right-arrow", "section": "Focus", "label": "Focus right (arrow)", "defaultKeys": "Super+Right", "command": "focus right" },
        { "id": "move-left", "section": "Focus", "label": "Move window left", "defaultKeys": "Super+Shift+H", "command": "move left" },
        { "id": "move-down", "section": "Focus", "label": "Move window down", "defaultKeys": "Super+Shift+J", "command": "move down" },
        { "id": "move-up", "section": "Focus", "label": "Move window up", "defaultKeys": "Super+Shift+K", "command": "move up" },
        { "id": "move-right", "section": "Focus", "label": "Move window right", "defaultKeys": "Super+Shift+L", "command": "move right" },
        { "id": "floating", "section": "Focus", "label": "Toggle floating", "defaultKeys": "Super+Shift+Space", "command": "floating toggle" },
        { "id": "focus-toggle", "section": "Focus", "label": "Focus tiling/floating", "defaultKeys": "Super+D", "command": "focus mode_toggle" },
        { "id": "focus-parent", "section": "Focus", "label": "Focus parent", "defaultKeys": "Super+Shift+A", "command": "focus parent" },
        { "id": "ws-1", "section": "Workspaces", "label": "Workspace 1", "defaultKeys": "Super+1", "command": "workspace number 1" },
        { "id": "ws-2", "section": "Workspaces", "label": "Workspace 2", "defaultKeys": "Super+2", "command": "workspace number 2" },
        { "id": "ws-3", "section": "Workspaces", "label": "Workspace 3", "defaultKeys": "Super+3", "command": "workspace number 3" },
        { "id": "ws-4", "section": "Workspaces", "label": "Workspace 4", "defaultKeys": "Super+4", "command": "workspace number 4" },
        { "id": "ws-5", "section": "Workspaces", "label": "Workspace 5", "defaultKeys": "Super+5", "command": "workspace number 5" },
        { "id": "ws-6", "section": "Workspaces", "label": "Workspace 6", "defaultKeys": "Super+6", "command": "workspace number 6" },
        { "id": "ws-7", "section": "Workspaces", "label": "Workspace 7", "defaultKeys": "Super+7", "command": "workspace number 7" },
        { "id": "ws-8", "section": "Workspaces", "label": "Workspace 8", "defaultKeys": "Super+8", "command": "workspace number 8" },
        { "id": "ws-9", "section": "Workspaces", "label": "Workspace 9", "defaultKeys": "Super+9", "command": "workspace number 9" },
        { "id": "ws-10", "section": "Workspaces", "label": "Workspace 10", "defaultKeys": "Super+0", "command": "workspace number 10" },
        { "id": "ws-next", "section": "Workspaces", "label": "Next workspace", "defaultKeys": "Super+Tab", "command": "workspace next_on_output" },
        { "id": "ws-prev", "section": "Workspaces", "label": "Previous workspace", "defaultKeys": "Super+Shift+Tab", "command": "workspace prev_on_output" },
        { "id": "split-h", "section": "Layout", "label": "Split horizontal", "defaultKeys": "Super+B", "command": "splith" },
        { "id": "split-v", "section": "Layout", "label": "Split vertical", "defaultKeys": "Super+Ctrl+V", "command": "splitv" },
        { "id": "toggle-split", "section": "Layout", "label": "Toggle split", "defaultKeys": "Super+E", "command": "layout toggle split" },
        { "id": "stacking", "section": "Layout", "label": "Stacking", "defaultKeys": "Super+S", "command": "layout stacking" },
        { "id": "fullscreen", "section": "Layout", "label": "Fullscreen", "defaultKeys": "Super+F", "command": "fullscreen" },
        { "id": "resize-mode", "section": "Layout", "label": "Resize mode", "defaultKeys": "Super+R", "command": "mode resize" },
        { "id": "scratch-send", "section": "Scratchpad", "label": "Send to scratchpad", "defaultKeys": "Super+Shift+-", "command": "move scratchpad" },
        { "id": "scratch-show", "section": "Scratchpad", "label": "Show scratchpad", "defaultKeys": "Super+-", "command": "scratchpad show" },
        { "id": "calendar", "section": "Panels", "label": "Calendar", "defaultKeys": "Super+C", "command": "exec /usr/bin/qs ipc call popups toggle calendar" },
        { "id": "weather", "section": "Panels", "label": "Weather", "defaultKeys": "Super+T", "command": "exec /usr/bin/qs ipc call popups toggle weather" },
        { "id": "notifs", "section": "Panels", "label": "Notifications", "defaultKeys": "Super+N", "command": "exec /usr/bin/qs ipc call popups toggle notifs" },
        { "id": "reminders", "section": "Panels", "label": "Reminders", "defaultKeys": "Super+Shift+N", "command": "exec /usr/bin/qs ipc call reminders toggle" },
        { "id": "audio", "section": "Panels", "label": "Audio", "defaultKeys": "Super+M", "command": "exec /usr/bin/qs ipc call popups toggle audio" },
        { "id": "media", "section": "Panels", "label": "Media", "defaultKeys": "Super+Ctrl+R", "command": "exec /usr/bin/qs ipc call popups toggle media" },
        { "id": "power", "section": "Panels", "label": "Power", "defaultKeys": "Super+P", "command": "exec /usr/bin/qs ipc call popups toggle power" },
        { "id": "network", "section": "Panels", "label": "Network", "defaultKeys": "Super+I", "command": "exec /usr/bin/qs ipc call popups toggle network" },
        { "id": "bluetooth", "section": "Panels", "label": "Bluetooth", "defaultKeys": "Super+U", "command": "exec /usr/bin/qs ipc call popups toggle bluetooth" },
        { "id": "close-panel", "section": "Panels", "label": "Close panel", "defaultKeys": "Super+Q", "command": "exec /usr/bin/qs ipc call popups close" },
        { "id": "bar-editor", "section": "Panels", "label": "Bar editor", "defaultKeys": "Super+Shift+B", "command": "exec /usr/bin/qs ipc call popups toggle bar" },
        { "id": "radio", "section": "System", "label": "Lofi Radio play/stop", "defaultKeys": "Super+Shift+R", "command": "exec /usr/bin/qs ipc call radio toggle" },
        { "id": "screenshot", "section": "System", "label": "Screenshot region", "defaultKeys": "Print", "command": "exec {home}/.local/bin/qs-screenshot" },
        { "id": "screenshot-mod", "section": "System", "label": "Screenshot region", "defaultKeys": "Super+Shift+S", "command": "exec {home}/.local/bin/qs-screenshot" },
        { "id": "record", "section": "System", "label": "Start/stop recording", "defaultKeys": "Alt+Print", "command": "exec {home}/.local/bin/qs-screenrecord" },
        { "id": "volume-keys", "section": "System", "label": "Mute / volume + OSD", "defaultKeys": "Volume keys", "command": "" },
        { "id": "brightness-keys", "section": "System", "label": "Brightness + OSD", "defaultKeys": "Brightness keys", "command": "" }
    ]

    function find(id) {
        for (let i = 0; i < catalog.length; i++) {
            if (catalog[i].id === id)
                return catalog[i];
        }
        return null;
    }

    function effectiveCombo(action) {
        if (!action)
            return null;
        if (action.id in overrides) {
            const raw = overrides[action.id];
            if (!raw)
                return null;
            return Combo.parse(raw);
        }
        return Combo.parse(action.defaultKeys);
    }

    function displayKeys(action) {
        const c = effectiveCombo(action);
        return c ? Combo.display(c) : "—";
    }

    function owner(combo) {
        if (!combo)
            return null;
        const want = Combo.comboId(combo);
        for (let i = 0; i < catalog.length; i++) {
            const cur = effectiveCombo(catalog[i]);
            if (cur && Combo.comboId(cur) === want)
                return catalog[i];
        }
        return null;
    }

    function comboFromEvent(event) {
        const key = event.key;
        if (key === Qt.Key_Shift || key === Qt.Key_Control || key === Qt.Key_Alt || key === Qt.Key_Meta || key === Qt.Key_Super_L || key === Qt.Key_Super_R)
            return null;
        let name = "";
        if (key === Qt.Key_Return || key === Qt.Key_Enter)
            name = "Return";
        else if (key === Qt.Key_Escape)
            name = "Escape";
        else if (key === Qt.Key_Tab)
            name = "Tab";
        else if (key === Qt.Key_Space)
            name = "space";
        else if (key === Qt.Key_Slash)
            name = "slash";
        else if (key === Qt.Key_Period)
            name = "period";
        else if (key === Qt.Key_Minus)
            name = "minus";
        else if (key === Qt.Key_Print)
            name = "Print";
        else if (key === Qt.Key_Left)
            name = "Left";
        else if (key === Qt.Key_Right)
            name = "Right";
        else if (key === Qt.Key_Up)
            name = "Up";
        else if (key === Qt.Key_Down)
            name = "Down";
        else if (key >= Qt.Key_A && key <= Qt.Key_Z)
            name = String.fromCharCode(key).toLowerCase();
        else if (key >= Qt.Key_0 && key <= Qt.Key_9)
            name = String.fromCharCode(key);
        else if (event.text && String(event.text).length === 1)
            name = String(event.text).toLowerCase();
        else
            return null;
        return {
            "logo": !!(event.modifiers & Qt.MetaModifier),
            "ctrl": !!(event.modifiers & Qt.ControlModifier),
            "alt": !!(event.modifiers & Qt.AltModifier),
            "shift": !!(event.modifiers & Qt.ShiftModifier),
            "key": name
        };
    }

    function assign(id, combo) {
        const action = find(id);
        if (!action || !action.command)
            return { "ok": false, "reason": "fixed", "action": action };
        const other = owner(combo);
        if (other && other.id !== id)
            return { "ok": false, "reason": "conflict", "action": other, "combo": combo };
        const next = Object.assign({}, overrides);
        next[id] = Combo.display(combo);
        overrides = next;
        persist();
        return { "ok": true };
    }

    function replace(id, combo) {
        const other = owner(combo);
        const next = Object.assign({}, overrides);
        if (other && other.id !== id)
            next[other.id] = "";
        next[id] = Combo.display(combo);
        overrides = next;
        persist();
    }

    function persist() {
        Quickshell.execDetached(["mkdir", "-p", home + "/.config/zoi"]);
        const data = { "version": 1, "bindings": overrides };
        storeFile.setText(JSON.stringify(data, null, 2) + "\n");
        writeApplyFile();
        Quickshell.execDetached([home + "/.local/bin/qs-keys-apply"]);
        revision++;
    }

    function writeApplyFile() {
        const empty = Object.keys(overrides).length === 0;
        if (empty) {
            applyFile.setText("{}\n");
            return;
        }
        const unbind = [];
        const bind = [];
        for (let i = 0; i < catalog.length; i++) {
            const action = catalog[i];
            if (!action.command)
                continue;
            const def = Combo.parse(action.defaultKeys);
            if (def)
                unbind.push(Combo.sway(def));
            const cur = effectiveCombo(action);
            if (cur)
                unbind.push(Combo.sway(cur));
        }
        for (let i = 0; i < catalog.length; i++) {
            const action = catalog[i];
            if (!action.command)
                continue;
            const cur = effectiveCombo(action);
            if (!cur)
                continue;
            bind.push({
                "key": Combo.sway(cur),
                "command": String(action.command).split("{home}").join(home)
            });
        }
        applyFile.setText(JSON.stringify({ "unbind": unbind, "bind": bind }, null, 2) + "\n");
    }

    function loadText(text) {
        try {
            const data = JSON.parse(String(text || "").trim() || "{}");
            overrides = data.bindings && typeof data.bindings === "object" ? data.bindings : {};
            revision++;
        } catch (e) {
            overrides = {};
        }
    }

    FileView {
        id: storeFile
        path: root.storePath
        watchChanges: true
        printErrors: false
        onLoaded: root.loadText(text())
        onFileChanged: reload()
    }

    FileView {
        id: applyFile
        path: root.applyPath
        printErrors: false
    }
}
