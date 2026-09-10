pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "Commons"

Scope {
    PanelWindow {
        id: inhibitWin

        visible: Idle.stayAwake
        color: "transparent"
        implicitWidth: 1
        implicitHeight: 1
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        mask: Region {}
        WlrLayershell.namespace: "quickshell-idle-inhibit"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
        }

        IdleInhibitor {
            enabled: Idle.stayAwake
            window: inhibitWin
        }
    }
}
