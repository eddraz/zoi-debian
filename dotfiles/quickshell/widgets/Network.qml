import QtQuick
import Quickshell.Networking
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: Style.iconSize + 6
    implicitHeight: Style.barHeight

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

    readonly property var connectedWifi: {
        const wifi = root.wifiDevice;
        if (!wifi || !wifi.networks)
            return null;
        const values = wifi.networks.values;
        for (let i = 0; i < values.length; i++) {
            if (values[i].connected)
                return values[i];
        }
        return null;
    }

    readonly property string iconName: {
        if (root.wiredDevice)
            return "ethernet";
        if (!Networking.wifiEnabled)
            return "wifi-off";
        return "wifi";
    }

    readonly property string tipText: {
        if (connectedWifi)
            return connectedWifi.name || "Wi-Fi";
        if (wiredDevice)
            return "Ethernet " + (wiredDevice.address || "");
        if (!Networking.wifiEnabled)
            return "Wi-Fi off";
        return "Wi-Fi";
    }

    StatusIcon {
        anchors.centerIn: parent
        icon: root.iconName
        level: {
            if (connectedWifi && typeof connectedWifi.signalStrength === "number" && connectedWifi.signalStrength > 0)
                return connectedWifi.signalStrength / 100;
            if (root.wifiDevice && root.wifiDevice.connected)
                return 1.0;
            if (Networking.wifiEnabled)
                return 1.0;
            return 0;
        }
        stroke: {
            if (root.wiredDevice || (root.wifiDevice && root.wifiDevice.connected) || root.connectedWifi)
                return Color.barText;
            if (!Networking.wifiEnabled)
                return Color.muted;
            return Color.barText;
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Networking.wifiEnabled = !Networking.wifiEnabled;
            else
                root.togglePanel();
        }
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, root.tipText);
            else
                HoverTip.hide();
        }
    }

    onTipTextChanged: if (mouse.containsMouse)
        HoverTip.update(root, tipText)
}
