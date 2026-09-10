pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Networking
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
        width: parent.width
        height: 24
        radius: Style.radius
        color: Networking.wifiEnabled ? Color.accent : (root.cursor === 0 ? Color.focusFill : Color.surface)

        IndexBadge {
            slot: 0
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Networking.wifiEnabled ? Color.background : Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            elide: Text.ElideRight
            text: (Networking.wifiEnabled ? "Disable Wi-Fi" : "Enable Wi-Fi")
        }

        HoverMouse {
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
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
                width: parent.width
                height: 24
                radius: Style.radius
                color: modelData.connected ? Color.accent : (root.cursor === index + 1 ? Color.focusFill : Color.surface)

                IndexBadge {
                    slot: index + 1
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 28
                    anchors.rightMargin: 8
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    color: modelData.connected ? Color.background : Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: {
                        const name = modelData.name || "Hidden";
                        const sig = Math.round(modelData.signalStrength || 0);
                        const mark = modelData.connected ? "on" : (modelData.known ? "saved" : String(sig) + "%");
                        return name + "  " + mark;
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
