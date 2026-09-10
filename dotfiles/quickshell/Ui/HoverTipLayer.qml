import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Commons"

PanelWindow {
    id: root

    required property var modelData

    screen: modelData
    visible: HoverTip.text !== "" && HoverTip.screen === modelData
    color: "transparent"
    implicitHeight: 22
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "quickshell-tip"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }

    Rectangle {
        id: bubble

        y: 2
        height: 18
        width: tipLabel.implicitWidth + 10
        x: Math.max(4, Math.min(root.width - width - 4, HoverTip.centerX - width / 2))
        color: Color.popupBackground
        radius: 3
        border.width: 1
        border.color: Color.surface

        Text {
            id: tipLabel
            anchors.centerIn: parent
            color: Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            text: HoverTip.text
        }
    }
}
