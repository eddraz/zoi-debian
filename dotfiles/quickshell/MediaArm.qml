pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "Commons"

Scope {
    PanelWindow {
        visible: Media.armed
        color: "transparent"
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-media-arm"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Media.armed ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Media.disarm()
        }

        Item {
            id: catcher
            anchors.fill: parent
            focus: Media.armed

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    Media.disarm();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_1) {
                    Media.previous();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_2) {
                    Media.toggle();
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_3) {
                    Media.next();
                    event.accepted = true;
                    return;
                }
            }
        }

        onVisibleChanged: if (visible)
            catcher.forceActiveFocus()
    }
}
