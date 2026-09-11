pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 10
    width: parent ? parent.width : 252

    property int cursor: 0

    function nextSection(back) {
        const count = 1 + devices.length;
        if (count <= 0) return;
        cursor = back ? (cursor - 1 + count) % count : (cursor + 1) % count;
    }

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: {
        const e = [{ "label": "bluetooth enable disable", "index": 0 }];
        for (let i = 0; i < devices.length; i++)
            e.push({ "label": deviceName(devices[i]), "index": i + 1 });
        return e;
    }

    function handleKey(event) {
        const jump = KeyNav.jump(event, 1 + devices.length);
        if (jump >= 0) {
            cursor = jump;
            return true;
        }
        const count = 1 + devices.length;
        if (KeyNav.isNext(event) || KeyNav.isRight(event)) {
            cursor = Math.min(cursor + 1, Math.max(0, count - 1));
            return true;
        }
        if (KeyNav.isPrev(event) || KeyNav.isLeft(event)) {
            cursor = Math.max(cursor - 1, 0);
            return true;
        }
        if (KeyNav.isActivate(event)) {
            if (cursor === 0) {
                if (adapter) adapter.enabled = !adapter.enabled;
                return true;
            }
            const device = devices[cursor - 1];
            if (!device) return true;
            if (device.connected) device.disconnect();
            else if (device.paired) device.connect();
            else device.pair();
            return true;
        }
        return false;
    }

    property bool weStartedScan: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: {
        const values = Bluetooth.devices ? Bluetooth.devices.values : [];
        const list = [];
        for (let i = 0; i < values.length; i++)
            list.push(values[i]);
        list.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            if (a.paired !== b.paired)
                return a.paired ? -1 : 1;
            const an = (a.name || a.deviceName || "").toLowerCase();
            const bn = (b.name || b.deviceName || "").toLowerCase();
            return an < bn ? -1 : (an > bn ? 1 : 0);
        });
        return list.slice(0, 8);
    }

    onVisibleChanged: {
        if (!adapter)
            return;
        if (visible) {
            if (!adapter.discovering) {
                adapter.discovering = true;
                weStartedScan = true;
            }
        } else if (weStartedScan) {
            adapter.discovering = false;
            weStartedScan = false;
        }
    }

    function deviceName(device) {
        return device.name || device.deviceName || device.address;
    }

    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: {
            if (!adapter)
                return "No adapter";
            if (!adapter.enabled)
                return "Bluetooth off";
            if (adapter.discovering)
                return "Scanning…";
            return "Bluetooth on";
        }
    }

    // Bluetooth toggle button — uses useHighlightBg for the ON state
    ActionListItem {
        visible: adapter !== null
        selected: root.cursor === 0
        slot: 0
        highlighted: adapter && adapter.enabled
        useHighlightBg: true
        title: "Bluetooth"
        description: adapter ? (adapter.enabled ? (adapter.discovering ? "Buscando dispositivos…" : "Adaptador activo y visible") : "Adaptador inalámbrico apagado") : "Sin adaptador"
        badge: adapter && adapter.enabled ? "ON" : "OFF"
        onClicked: {
            if (adapter)
                adapter.enabled = !adapter.enabled;
        }
    }

    Repeater {
        model: root.devices

        ActionListItem {
            required property var modelData
            required property int index

            width: root.width
            selected: root.cursor === index + 1
            slot: index + 1
            highlighted: modelData.connected
            title: root.deviceName(modelData)
            description: modelData.connected ? "Conectado · Audio y control listos" : (modelData.pairing ? "Emparejando dispositivo…" : (modelData.paired ? "Dispositivo guardado en el sistema" : "Dispositivo descubierto"))
            badge: modelData.connected ? "CONECTADO" : (modelData.paired ? "VINCULADO" : "NUEVO")
            onClicked: {
                if (modelData.connected)
                    modelData.disconnect();
                else if (modelData.paired)
                    modelData.connect();
                else
                    modelData.pair();
            }
        }
    }
}
