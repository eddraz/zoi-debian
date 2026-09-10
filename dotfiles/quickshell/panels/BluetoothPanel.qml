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

    Rectangle {
        width: parent.width
        height: 42
        radius: Style.radius
        color: (adapter && adapter.enabled) ? Color.accent : (root.cursor === 0 ? Color.focusFill : Color.surface)
        visible: adapter !== null
        border.width: root.cursor === 0 ? 1 : 0
        border.color: (adapter && adapter.enabled) ? Color.background : Color.accent
        Behavior on color { ColorAnimation { duration: Style.animDuration } }

        Rectangle {
            width: 3
            height: root.cursor === 0 ? 20 : 0
            radius: 1.5
            color: (adapter && adapter.enabled) ? Color.background : Color.accent
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
            anchors.right: toggleBadge.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: adapter && adapter.enabled ? Color.background : Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBody
                font.bold: true
                text: "Bluetooth"
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                color: adapter && adapter.enabled ? Color.background : Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: adapter ? (adapter.enabled ? (adapter.discovering ? "Buscando dispositivos…" : "Adaptador activo y visible") : "Adaptador inalámbrico apagado") : "Sin adaptador"
            }
        }

        Rectangle {
            id: toggleBadge
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 20
            width: toggleBadgeText.implicitWidth + 12
            radius: 4
            color: adapter && adapter.enabled ? Color.background : (root.cursor === 0 ? Color.surface : Color.background)
            border.width: 1
            border.color: adapter && adapter.enabled ? Color.background : (root.cursor === 0 ? Color.subtleBorder : "transparent")

            Text {
                id: toggleBadgeText
                anchors.centerIn: parent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption - 1
                font.bold: true
                color: adapter && adapter.enabled ? Color.accent : Color.popupMuted
                text: adapter && adapter.enabled ? "ON" : "OFF"
            }
        }

        HoverMouse {
            onClicked: {
                if (adapter)
                    adapter.enabled = !adapter.enabled;
            }
        }
    }

    Repeater {
        model: root.devices

        Rectangle {
            id: deviceBox
            required property var modelData
            required property int index

            readonly property bool selected: root.cursor === index + 1

            width: root.width
            height: 42
            radius: Style.radius
            color: selected ? Color.focusFill : Color.surface
            border.width: selected ? 1 : 0
            border.color: Color.accent
            Behavior on color { ColorAnimation { duration: Style.animDuration } }

            Rectangle {
                width: 3
                height: deviceBox.selected ? 20 : 0
                radius: 1.5
                color: Color.accent
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: deviceBox.selected
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
                anchors.right: devBadge.left
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
                    text: root.deviceName(modelData)
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: modelData.connected ? "Conectado · Audio y control listos" : (modelData.pairing ? "Emparejando dispositivo…" : (modelData.paired ? "Dispositivo guardado en el sistema" : "Dispositivo descubierto"))
                }
            }

            Rectangle {
                id: devBadge
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 20
                width: devBadgeText.implicitWidth + 12
                radius: 4
                color: modelData.connected ? Color.focusFill : (deviceBox.selected ? Color.surface : Color.background)
                border.width: 1
                border.color: modelData.connected ? Color.accent : (deviceBox.selected ? Color.subtleBorder : "transparent")

                Text {
                    id: devBadgeText
                    anchors.centerIn: parent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption - 1
                    font.bold: true
                    color: modelData.connected ? Color.accent : Color.popupMuted
                    text: modelData.connected ? "CONECTADO" : (modelData.paired ? "VINCULADO" : "NUEVO")
                }
            }

            HoverMouse {
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
}
