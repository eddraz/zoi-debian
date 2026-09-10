import QtQuick
import Quickshell.Bluetooth
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: Style.iconSize + 6
    implicitHeight: Style.barHeight

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevice: {
        const devices = Bluetooth.devices ? Bluetooth.devices.values : [];
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected)
                return devices[i];
        }
        return null;
    }

    readonly property string tipText: {
        if (!adapter)
            return "Bluetooth · N/A";
        if (!adapter.enabled)
            return "Bluetooth · Off";
        if (connectedDevice)
            return "Bluetooth · " + (connectedDevice.name || connectedDevice.deviceName || "Connected");
        return "Bluetooth";
    }

    StatusIcon {
        anchors.centerIn: parent
        icon: !adapter || !adapter.enabled ? "bluetooth-off" : "bluetooth"
        stroke: {
            if (!adapter || !adapter.enabled)
                return Color.muted;
            if (root.connectedDevice)
                return Color.accent;
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
            if (event.button === Qt.RightButton && adapter)
                adapter.enabled = !adapter.enabled;
            else
                root.togglePanel();
        }
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, root.tipText, "Super+U");
            else
                HoverTip.hide();
        }
    }

    onTipTextChanged: if (mouse.containsMouse)
        HoverTip.update(root, tipText, "Super+U")
}
