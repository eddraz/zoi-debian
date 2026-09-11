pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Io
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 10
    width: parent ? parent.width : 252

    property int cursor: 0

    function handleEscape() {
        if (passwordSsid !== "") {
            passwordSsid = "";
            password = "";
            return true;
        }
        return false;
    }

    property int passFocusIndex: 0

    function nextSection(back) {
        if (passwordSsid !== "") {
            passFocusIndex = passFocusIndex === 0 ? 1 : 0;
            return;
        }
        const count = 2 + networks.length;
        if (count <= 0) return;
        cursor = back ? (cursor - 1 + count) % count : (cursor + 1) % count;
    }

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: {
        const e = [
            { "label": "wifi enable disable wifi apagar encender", "index": 0 },
            { "label": "probar calidad test wifi speed signal", "index": 1 }
        ];
        for (let i = 0; i < networks.length; i++)
            e.push({ "label": String(networks[i].name || "network"), "index": i + 2 });
        return e;
    }

    function handleKey(event) {
        if (passwordSsid !== "")
            return false;
        if (event.key === Qt.Key_Q || event.text === "q" || event.text === "Q") {
            root.openWifiQr();
            return true;
        }
        const count = 2 + networks.length;
        const jump = KeyNav.jump(event, count);
        if (jump >= 0) {
            cursor = jump;
            return true;
        }
        if (KeyNav.isNext(event) || KeyNav.isRight(event)) {
            cursor = Math.min(cursor + 1, count - 1);
            return true;
        }
        if (KeyNav.isPrev(event) || KeyNav.isLeft(event)) {
            cursor = Math.max(cursor - 1, 0);
            return true;
        }
        if (KeyNav.isActivate(event)) {
            if (cursor === 0) {
                Networking.wifiEnabled = !Networking.wifiEnabled;
                return true;
            }
            if (cursor === 1) {
                root.refreshWifi();
                return true;
            }
            const net = networks[cursor - 2];
            if (!net) return true;
            if (net.connected) net.disconnect();
            else if (needsPassword(net)) {
                passwordSsid = net.name;
                password = "";
            } else net.connect();
            return true;
        }
        return false;
    }

    property string passwordSsid: ""
    property string password: ""

    // WiFi quality
    readonly property string wifiQualityHelper: Quickshell.env("HOME") + "/.local/bin/qs-wifi-quality"
    property int wifiQuality: 0
    property int wifiSignal: 0
    property string wifiSsid: ""

    function openWifiQr() {
        Quickshell.execDetached(["/usr/bin/qs", "ipc", "call", "wifiqr", "toggle"]);
    }
    property bool wifiTesting: false
    property string wifiQualityError: ""

    function refreshWifi() {
        if (wifiTesting)
            return;
        wifiTesting = true;
        wifiQualityError = "";
        wifiProc.running = true;
    }

    function parseWifi(text) {
        try {
            const d = JSON.parse(String(text || "{}"));
            wifiQuality = Number(d.quality || 0);
            wifiSignal = Number(d.signal || 0);
            wifiSsid = String(d.ssid || "");
            wifiTesting = false;
        } catch (e) {
            wifiQualityError = String(text || "").slice(0, 60);
            wifiTesting = false;
        }
    }

    Process {
        id: wifiProc
        command: [root.wifiQualityHelper]
        stdout: StdioCollector {
            onStreamFinished: root.parseWifi(text)
        }
    }


    readonly property var wifiDevice: {
        const devices = Networking.devices ? Networking.devices.values : [];
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return devices[i];
        }
        return null;
    }

    readonly property var wiredDevice: {
        const devices = Networking.devices ? Networking.devices.values : [];
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wired && devices[i].connected)
                return devices[i];
        }
        return null;
    }

    readonly property var networks: {
        const wifi = root.wifiDevice;
        if (!wifi || !wifi.networks)
            return [];
        const values = wifi.networks.values;
        const list = [];
        for (let i = 0; i < values.length; i++)
            list.push(values[i]);
        list.sort((a, b) => {
            if (a.connected !== b.connected)
                return a.connected ? -1 : 1;
            return (b.signalStrength || 0) - (a.signalStrength || 0);
        });
        return list.slice(0, 8);
    }

    onVisibleChanged: {
        if (visible) {
            root.cursor = 0;
            refreshWifi();
        }
        if (wifiDevice)
            wifiDevice.scannerEnabled = visible;
        if (!visible) {
            passwordSsid = "";
            password = "";
        }
    }

    function needsPassword(net) {
        return !net.known && net.security !== WifiSecurityType.Open && net.security !== WifiSecurityType.Unknown;
    }

    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: {
            if (wiredDevice)
                return "Ethernet " + (wiredDevice.address || "");
            if (!Networking.wifiHardwareEnabled)
                return "Wi-Fi hardware off";
            if (!Networking.wifiEnabled)
                return "Wi-Fi off";
            return "Wi-Fi on";
        }
    }

    ActionListItem {
        visible: Networking.wifiHardwareEnabled
        selected: root.cursor === 0
        slot: 0
        highlighted: Networking.wifiEnabled
        useHighlightBg: true
        title: "Wi-Fi"
        description: Networking.wifiEnabled ? "Red inalámbrica activa" : "Red inalámbrica apagada"
        badge: Networking.wifiEnabled ? "ON" : "OFF"
        onClicked: {
            Networking.wifiEnabled = !Networking.wifiEnabled;
            root.cursor = 0;
        }
    }

    ActionListItem {
        visible: Networking.wifiEnabled
        selected: root.cursor === 1
        slot: 1
        title: "Probar Calidad de Señal"
        description: {
            if (root.wifiTesting) return "Midiendo enlace…";
            if (root.wifiQualityError) return "Error: " + root.wifiQualityError;
            if (root.wifiQuality === 0) return "Desconocido (haz clic para probar)";
            return root.wifiQuality + "% · " + root.wifiSsid;
        }
        badge: "TEST"
        onClicked: {
            root.refreshWifi();
            root.cursor = 1;
        }
    }

    Repeater {
        model: root.networks

        ActionListItem {
            required property var modelData
            required property int index

            width: root.width
            selected: root.cursor === index + 2
            slot: index + 2
            highlighted: modelData.connected
            title: modelData.name || "Red oculta"
            description: {
                if (modelData.connected) return "Conectado (" + (modelData.signalStrength || 0) + "%)";
                if (root.needsPassword(modelData)) return "Requiere contraseña (" + (modelData.signalStrength || 0) + "%)";
                return "Red abierta o guardada (" + (modelData.signalStrength || 0) + "%)";
            }
            badge: modelData.connected ? "CONECTADO" : (modelData.known ? "GUARDADA" : (root.needsPassword(modelData) ? "SEGURA" : "ABIERTA"))
            onClicked: {
                root.cursor = index + 2;
                if (modelData.connected) modelData.disconnect();
                else if (root.needsPassword(modelData)) {
                    root.passwordSsid = modelData.name;
                    root.password = "";
                } else modelData.connect();
            }
        }
    }
}
