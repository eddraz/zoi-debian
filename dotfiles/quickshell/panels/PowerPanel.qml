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

    Rectangle {
        width: parent.width
        height: 30
        radius: Style.radius
        color: root.cursor === 0 ? Color.focusFill : Color.surface
        border.width: root.cursor === 0 ? 1 : 0
        border.color: Color.accent
        Behavior on color { ColorAnimation { duration: Style.animDuration } }

        Row {
            spacing: 8
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            IndexBadge {
                slot: 0
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                font.bold: true
                text: "BRT"
            }

            Rectangle {
                id: slider
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 96
                height: 8
                radius: 4
                color: Color.crust
                border.width: root.cursor === 0 ? 1 : 0
                border.color: Color.yellow

                Rectangle {
                    height: parent.height
                    width: parent.width * Math.max(0, Math.min(Brightness.percent, 100)) / 100
                    radius: 4
                    color: Color.yellow
                    Behavior on width { NumberAnimation { duration: 80 } }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    cursorShape: Qt.PointingHandCursor
                    onPressed: event => {
                        root.cursor = 0;
                        Brightness.setPercent(event.x / slider.width * 100);
                    }
                    onPositionChanged: event => {
                        if (pressed)
                            Brightness.setPercent(event.x / slider.width * 100);
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: Brightness.percent + "%"
            }
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

            Rectangle {
                id: profileBox
                required property var modelData
                required property int index

                readonly property bool isSelected: root.cursor === index + 1
                readonly property bool isCurrent: PowerProfiles.profile === modelData

                width: root.width
                height: 42
                radius: Style.radius
                color: isSelected ? Color.focusFill : Color.surface
                border.width: isSelected ? 1 : 0
                border.color: Color.accent
                Behavior on color { ColorAnimation { duration: Style.animDuration } }
                visible: modelData !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile

                Rectangle {
                    width: 3
                    height: profileBox.isSelected ? 20 : 0
                    radius: 1.5
                    color: Color.accent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: profileBox.isSelected
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
                    anchors.right: statusBadge.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        color: profileBox.isCurrent ? Color.accent : Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontBody
                        font.bold: true
                        text: root.profileLabel(modelData)
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        color: Color.popupMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: root.profileDesc(modelData)
                    }
                }

                Rectangle {
                    id: statusBadge
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    height: 20
                    width: badgeText.implicitWidth + 12
                    radius: 4
                    color: profileBox.isCurrent ? Color.focusFill : (profileBox.isSelected ? Color.surface : Color.background)
                    border.width: 1
                    border.color: profileBox.isCurrent ? Color.accent : (profileBox.isSelected ? Color.subtleBorder : "transparent")

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption - 1
                        font.bold: true
                        color: profileBox.isCurrent ? Color.accent : Color.popupMuted
                        text: profileBox.isCurrent ? "ACTIVO" : "PERFIL"
                    }
                }

                HoverMouse {
                    onClicked: {
                        root.cursor = index + 1;
                        PowerProfiles.profile = modelData;
                    }
                }
            }
        }
    }
}
