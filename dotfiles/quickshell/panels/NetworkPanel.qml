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

    function nextSection(back) {
        cursor = KeyNav.nextStart([0, Math.min(1, networks.length)], cursor, back);
    }

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: {
        const e = [{ "label": "wifi enable disable", "index": 0 }];
        for (let i = 0; i < networks.length; i++)
            e.push({ "label": String(networks[i].name || "network"), "index": i + 1 });
        return e;
    }

    // Tab focus cycling among interactive elements
    property int wifiTabFocus: -1   // -1 = list mode, 0 = wifi toggle, 1 = test button
    readonly property var tabTargets: ["wifiToggleBtn", "wifiTestBtn"]

    function focusTabItem(direction) {
        const n = tabTargets.length;
        if (n === 0) return false;
        if (wifiTabFocus < 0) {
            wifiTabFocus = direction > 0 ? 0 : n - 1;
        } else {
            wifiTabFocus = (wifiTabFocus + (direction > 0 ? 1 : -1) + n) % n;
        }
        const id = tabTargets[wifiTabFocus];
        if (id === "wifiToggleBtn") wifiToggleBtn.forceActiveFocus();
        else if (id === "wifiTestBtn") wifiTestBtn.forceActiveFocus();
        return true;
    }

    function handleKey(event) {
        if (passwordSsid !== "")
            return false;
        const jump = KeyNav.jump(event, 1 + networks.length);
        if (jump >= 0) {
            cursor = jump;
            return true;
        }
        const count = 1 + networks.length;
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
            const net = networks[cursor - 1];
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
    property bool wifiTesting: false
    property string wifiQualityError: ""
    property var wifiTabOrder: ["wifiToggle", "wifiTest", "listEnd"]

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
            root.wifiTabFocus = -1;
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

    Rectangle {
        id: wifiToggleBtn
        width: parent.width
        height: 42
        radius: Style.radius
        color: Networking.wifiEnabled ? Color.accent : (root.cursor === 0 ? Color.focusFill : Color.surface)
        border.width: root.cursor === 0 ? 1 : 0
        border.color: Networking.wifiEnabled ? Color.background : Color.accent
        activeFocusOnTab: true
        Behavior on color { ColorAnimation { duration: Style.animDuration } }

        Rectangle {
            width: 3
            height: root.cursor === 0 ? 20 : 0
            radius: 1.5
            color: Networking.wifiEnabled ? Color.background : Color.accent
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.cursor === 0
            Behavior on height { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic } }
        }

        IndexBadge {
            slot: 0
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 32
            anchors.right: wifiBadge.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Networking.wifiEnabled ? Color.background : Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBody
                font.bold: true
                text: "Wi-Fi"
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: Networking.wifiEnabled ? Color.background : Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: Networking.wifiEnabled ? "Conexión inalámbrica activa y escaneando" : "Adaptador Wi-Fi apagado"
            }
        }

        Rectangle {
            id: wifiBadge
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 20
            width: wifiBadgeText.implicitWidth + 12
            radius: 4
            color: Networking.wifiEnabled ? Color.background : (root.cursor === 0 ? Color.surface : Color.background)
            border.width: 1
            border.color: Networking.wifiEnabled ? Color.background : (root.cursor === 0 ? Color.subtleBorder : "transparent")

            Text {
                id: wifiBadgeText
                anchors.centerIn: parent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption - 1
                font.bold: true
                color: Networking.wifiEnabled ? Color.accent : Color.popupMuted
                text: Networking.wifiEnabled ? "ON" : "OFF"
            }
        }

        HoverMouse {
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
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
            color: root.wifiTabFocus === 1 ? Color.focusFill : Color.surface
            border.width: 1
            border.color: root.wifiTabFocus === 1 ? Color.accent : Color.subtleBorder
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
                onClicked: root.refreshWifi()
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

            Rectangle {
                id: netBox
                width: parent.width
                height: 42
                radius: Style.radius
                color: root.cursor === index + 1 ? Color.focusFill : Color.surface
                border.width: root.cursor === index + 1 ? 1 : 0
                border.color: Color.accent
                Behavior on color { ColorAnimation { duration: Style.animDuration } }

                Rectangle {
                    width: 3
                    height: root.cursor === index + 1 ? 20 : 0
                    radius: 1.5
                    color: Color.accent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.cursor === index + 1
                    Behavior on height { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic } }
                }

                IndexBadge {
                    slot: index + 1
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 32
                    anchors.right: netBadge.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        color: modelData.connected ? Color.accent : Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontBody
                        font.bold: true
                        text: modelData.name || "Red Oculta"
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        color: Color.popupMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: {
                            const sig = Math.round(modelData.signalStrength || 0);
                            if (modelData.connected)
                                return "Conectada · Señal al " + sig + "%";
                            if (modelData.known)
                                return "Red guardada · Señal al " + sig + "%";
                            if (root.needsPassword(modelData))
                                return "Red protegida · Señal al " + sig + "%";
                            return "Red abierta · Señal al " + sig + "%";
                        }
                    }
                }

                Rectangle {
                    id: netBadge
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    height: 20
                    width: netBadgeText.implicitWidth + 12
                    radius: 4
                    color: modelData.connected ? Color.focusFill : (root.cursor === index + 1 ? Color.surface : Color.background)
                    border.width: 1
                    border.color: modelData.connected ? Color.accent : (root.cursor === index + 1 ? Color.subtleBorder : "transparent")

                    Text {
                        id: netBadgeText
                        anchors.centerIn: parent
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption - 1
                        font.bold: true
                        color: modelData.connected ? Color.accent : Color.popupMuted
                        text: modelData.connected ? "CONECTADO" : (modelData.known ? "GUARDADA" : Math.round(modelData.signalStrength || 0) + "%")
                    }
                }

                HoverMouse {
                    onClicked: {
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
                    border.width: 1
                    border.color: Color.overlay

                    TextInput {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        color: Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        echoMode: TextInput.Password
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
                    width: 52
                    height: 24
                    radius: Style.radius
                    color: Color.accent

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
