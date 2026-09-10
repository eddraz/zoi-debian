pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    visible: UPower.displayDevice.ready
    implicitWidth: Style.iconSize + 6
    implicitHeight: Style.barHeight

    readonly property int percent: {
        const device = UPower.displayDevice;
        if (!device.ready)
            return 0;
        if (device.energyCapacity > 0)
            return Math.round(device.energy / device.energyCapacity * 100);
        const value = device.percentage;
        return value <= 1 ? Math.round(value * 100) : Math.round(value);
    }
    readonly property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
    readonly property string tipText: "Power · " + (charging ? "Charging " : "Battery ") + percent + "%"

    StatusIcon {
        anchors.centerIn: parent
        icon: "battery"
        level: root.percent / 100
        charging: root.charging
        stroke: {
            if (root.percent <= 15)
                return Color.urgent;
            if (root.charging)
                return Color.green;
            return Color.barText;
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, root.tipText, "Super+P");
            else
                HoverTip.hide();
        }
    }

    onTipTextChanged: {
        if (mouse.containsMouse)
            HoverTip.update(root, tipText, "Super+P");
    }
}
