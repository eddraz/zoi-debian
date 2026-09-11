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
        selected: root.cursor === 0
        slot: 0
        highlighted: Networking.wifiEnabled
        useHighlightBg: true
        title: "Wi-Fi"
        description: Networking.wifiEnabled ? "Conexión inalámbrica activa y escaneando" : "Adaptador Wi-Fi apagado"
        badge: Networking.wifiEnabled ? "ON" : "OFF"
        onClicked: {
            root.cursor = 0;
            Networking.wifiEnabled = !Networking.wifiEnabled;
        }
    }

    // WiFi quality card
    Column {
        width: parent.width
        spacing: 4

        Rectangle {
            id: wifiTestBtn
            width: parent.width
            height: 28
            radius: Style.radius
            color: root.cursor === 1 ? Color.focusFill : Color.surface
            border.width: 1
            border.color: root.cursor === 1 ? Color.accent : Color.subtleBorder
            activeFocusOnTab: true

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                StatusIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: root.wifiTesting ? "tray" : "wifi"
                    stroke: Color.popupText
                    level: root.wifiSignal / 100
                    width: 14
                    height: 14
                    visible: !root.wifiTesting
                }

                Text {
                    id: leftText
                    anchors.verticalCenter: parent.verticalCenter
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    font.bold: true
                    text: root.wifiTesting ? "Midiendo Wi-Fi..." : "Probar calidad de Wi-Fi"
                }

                Item {
                    width: Math.max(8, parent.width - leftText.implicitWidth - rightText.implicitWidth - 36)
                    height: 1
                }

                Text {
                    id: rightText
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.wifiQuality >= 70 ? Color.green : (root.wifiQuality >= 40 ? Color.yellow : Color.urgent)
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption - 1
                    font.bold: true
                    visible: !root.wifiTesting && root.wifiQuality > 0
                    text: root.wifiQuality + "%"
                }
            }

            HoverMouse {
                onClicked: {
                    root.cursor = 1;
                    root.refreshWifi();
                }
            }
        }

        // Quality bar
        Rectangle {
            visible: root.wifiQuality > 0 || root.wifiTesting
            width: parent.width
            height: 6
            radius: 3
            color: Color.surface

            Rectangle {
                width: parent.width * (root.wifiQuality / 100)
                height: parent.height
                radius: 3
                color: root.wifiQuality >= 70 ? Color.green : (root.wifiQuality >= 40 ? Color.yellow : Color.urgent)
                Behavior on width { NumberAnimation { duration: Style.animSlow; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            visible: root.wifiSsid !== "" && !root.wifiTesting
            width: parent.width
            color: Color.popupMuted
            font.family: Style.fontFamily
            font.pixelSize: Style.fontBadge
            text: {
                if (root.wifiQualityError !== "")
                    return "Error: " + root.wifiQualityError;
                const sig = root.wifiSignal;
                return "SSID: " + root.wifiSsid + " · Señal " + sig + "%";
            }
        }
    }

    Repeater {
        model: root.networks

        Column {
            required property var modelData
            required property int index
            width: root.width
            spacing: 4

            ActionListItem {
                width: parent.width
                selected: root.cursor === index + 2
                slot: index + 2
                highlighted: modelData.connected
                title: modelData.name || "Red Oculta"
                description: {
                    const sig = Math.round((modelData.signalStrength || 0) * 100);
                    if (modelData.connected)
                        return "Conectada · Señal al " + sig + "%";
                    if (modelData.known)
                        return "Red guardada · Señal al " + sig + "%";
                    if (root.needsPassword(modelData))
                        return "Red protegida · Señal al " + sig + "%";
                    return "Red abierta · Señal al " + sig + "%";
                }
                badge: modelData.connected ? "CONECTADO" : (modelData.known ? "GUARDADA" : Math.round((modelData.signalStrength || 0) * 100) + "%")
                onClicked: {
                    root.cursor = index + 2;
                    if (modelData.connected) {
                        modelData.disconnect();
                        return;
                    }
                    if (root.needsPassword(modelData)) {
                        root.passwordSsid = modelData.name;
                        root.password = "";
                        return;
                    }
                    modelData.connect();
                }
            }

            Row {
                visible: root.passwordSsid === modelData.name
                spacing: 6
                width: parent.width

                Rectangle {
                    width: parent.width - 58
                    height: 24
                    radius: Style.radius
                    color: Color.surface
                    border.width: root.passFocusIndex === 0 ? 2 : 1
                    border.color: root.passFocusIndex === 0 ? Color.accent : Color.overlay

                    TextInput {
                        id: passInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        color: Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        echoMode: TextInput.Password
                        focus: root.passwordSsid === modelData.name && root.passFocusIndex === 0
                        text: root.password
                        onTextChanged: root.password = text
                        onAccepted: {
                            modelData.connectWithPsk(root.password);
                            root.passwordSsid = "";
                            root.password = "";
                        }
                    }
                }

                Rectangle {
                    id: joinBtn
                    width: 52
                    height: 24
                    radius: Style.radius
                    color: Color.accent
                    border.width: root.passFocusIndex === 1 ? 2 : 0
                    border.color: Color.foreground

                    Text {
                        anchors.centerIn: parent
                        color: Color.background
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: "Join"
                    }

                    HoverMouse {
                        onClicked: {
                            modelData.connectWithPsk(root.password);
                            root.passwordSsid = "";
                            root.password = "";
                        }
                    }
                }
            }
        }
    }
}
