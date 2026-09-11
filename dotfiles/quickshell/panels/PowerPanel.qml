pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import "../Commons"
import "../Ui"

Column {
    id: root

    spacing: 10
    width: parent ? parent.width : 252
    property int cursor: 0

    readonly property var profiles: {
        const list = [PowerProfile.PowerSaver, PowerProfile.Balanced];
        if (PowerProfiles.hasPerformanceProfile)
            list.push(PowerProfile.Performance);
        return list;
    }

    readonly property int count: 1 + profiles.length

    onVisibleChanged: {
        if (visible) {
            cursor = 0;
            Brightness.refresh();
        }
    }

    function nextSection(back) {
        if (count <= 0) return;
        cursor = back ? (cursor - 1 + count) % count : (cursor + 1) % count;
    }

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: [
        { "label": "brightness", "index": 0 },
        { "label": "saver", "index": 1 },
        { "label": "balanced", "index": 2 },
        { "label": "performance perf", "index": 3 }
    ]

    function handleKey(event) {
        const jump = KeyNav.jump(event, count);
        if (jump >= 0) {
            cursor = jump;
            return true;
        }
        if (cursor === 0 && KeyNav.isLeft(event)) {
            Brightness.adjust(-0.05);
            return true;
        }
        if (cursor === 0 && KeyNav.isRight(event)) {
            Brightness.adjust(0.05);
            return true;
        }
        if (KeyNav.isNext(event) || (cursor !== 0 && KeyNav.isRight(event))) {
            cursor = Math.min(cursor + 1, count - 1);
            return true;
        }
        if (KeyNav.isPrev(event) || (cursor !== 0 && KeyNav.isLeft(event))) {
            cursor = Math.max(cursor - 1, 0);
            return true;
        }
        if (KeyNav.isActivate(event) && cursor >= 1) {
            PowerProfiles.profile = profiles[cursor - 1];
            return true;
        }
        return false;
    }

    readonly property var device: UPower.displayDevice
    readonly property int percent: {
        if (!device || !device.ready)
            return 0;
        if (device.energyCapacity > 0)
            return Math.round(device.energy / device.energyCapacity * 100);
        const value = device.percentage;
        return value <= 1 ? Math.round(value * 100) : Math.round(value);
    }
    readonly property bool charging: device && device.state === UPowerDeviceState.Charging
    readonly property string eta: {
        if (!device)
            return "";
        const secs = charging ? device.timeToFull : device.timeToEmpty;
        if (!secs || secs <= 0)
            return "";
        const minutes = Math.round(secs / 60);
        if (minutes < 60)
            return minutes + " min";
        return Math.floor(minutes / 60) + " h " + (minutes % 60) + " min";
    }

    function profileLabel(value) {
        if (value === PowerProfile.PowerSaver)
            return "Ahorro de Energía";
        if (value === PowerProfile.Performance)
            return "Alto Rendimiento";
        return "Equilibrado";
    }

    function profileDesc(value) {
        if (value === PowerProfile.PowerSaver)
            return "Reduce el consumo para extender la batería";
        if (value === PowerProfile.Performance)
            return "Máxima potencia de CPU y respuesta ágil";
        return "Balance estándar entre rendimiento y consumo";
    }

    Text {
        color: percent <= 15 ? Color.urgent : Color.popupText
        font.family: Style.fontFamily
        font.pixelSize: Style.fontBody
        font.bold: true
        text: (charging ? "Charging " : (UPower.onBattery ? "On battery " : "AC ")) + percent + "%"
    }

    Text {
        visible: root.eta !== ""
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: (root.charging ? "Full in " : "Left ") + root.eta
    }

    Rectangle {
        width: parent.width
        height: 8
        radius: 4
        color: Color.surface

        Rectangle {
            height: parent.height
            width: parent.width * Math.max(0, Math.min(root.percent, 100)) / 100
            radius: 4
            color: root.percent <= 15 ? Color.urgent : (root.charging ? Color.green : Color.accent)
        }
    }

    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Brightness"
    }

    VolumeSlider {
        selected: root.cursor === 0
        slot: 0
        label: "BRT"
        percent: Brightness.percent
        muted: false
        accentColor: Color.yellow
        onSetVolume: fraction => {
            root.cursor = 0;
            Brightness.setPercent(fraction * 100);
        }
    }

    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Perfiles de Energía"
    }

    Column {
        spacing: 6
        width: parent.width

        Repeater {
            model: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]

            ActionListItem {
                required property var modelData
                required property int index

                width: root.width
                visible: modelData !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                selected: root.cursor === index + 1
                slot: index + 1
                highlighted: PowerProfiles.profile === modelData
                title: root.profileLabel(modelData)
                description: root.profileDesc(modelData)
                badge: PowerProfiles.profile === modelData ? "ACTIVO" : "PERFIL"
                onClicked: {
                    root.cursor = index + 1;
                    PowerProfiles.profile = modelData;
                }
            }
        }
    }
}
