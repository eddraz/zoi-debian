pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Commons"

Scope {
    id: root

    property bool opened: false
    property bool armed: false
    property string kind: "volume"
    property int value: 0
    readonly property bool muted: kind === "volume" && Audio.muted

    function showVolume() {
        kind = "volume";
        value = Audio.percent;
        opened = true;
        hideTimer.restart();
    }

    function showBrightness() {
        Brightness.refresh();
        kind = "brightness";
        value = Brightness.percent;
        opened = true;
        hideTimer.restart();
    }

    Timer {
        interval: 500
        running: true
        repeat: false
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: Style.osdDuration
        onTriggered: root.opened = false
    }

    Connections {
        target: Audio
        function onPercentChanged() {
            if (root.armed)
                root.showVolume();
        }
        function onMutedChanged() {
            if (root.armed)
                root.showVolume();
        }
    }

    IpcHandler {
        target: "osd"

        function volume(): string {
            root.showVolume();
            return "ok";
        }

        function brightness(): string {
            root.showBrightness();
            return "ok";
        }

        function close(): string {
            root.opened = false;
            return "ok";
        }

        function ping(): string {
            return "ok";
        }
    }

    PanelWindow {
        visible: root.opened
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 48
            width: Style.osdBarWidth + 96
            height: 44
            color: Color.popupBackground
            radius: Style.radius

            Row {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.muted ? Color.urgent : Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    font.bold: true
                    text: root.kind === "brightness" ? "BRT" : (root.muted ? "MUTE" : "VOL")
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Style.osdBarWidth
                    height: 6
                    radius: 3
                    color: Color.surface

                    Rectangle {
                        height: parent.height
                        width: parent.width * (root.muted ? 0 : Math.max(0, Math.min(root.value, 100)) / 100)
                        radius: 3
                        color: root.kind === "brightness" ? Color.yellow : Color.accent
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    text: root.value + "%"
                }
            }
        }
    }
}
