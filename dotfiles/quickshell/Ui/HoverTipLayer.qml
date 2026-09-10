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
    implicitHeight: 24
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
        height: 20
        width: contentRow.implicitWidth + 12
        x: Math.max(4, Math.min(root.width - width - 4, HoverTip.centerX - width / 2))
        color: Color.popupBackground
        radius: Style.radius
        border.width: 1
        border.color: Color.surface

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                id: tipLabel
                anchors.verticalCenter: parent.verticalCenter
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: HoverTip.text
            }

            Rectangle {
                id: shortcutBadge
                visible: HoverTip.shortcut !== ""
                anchors.verticalCenter: parent.verticalCenter
                height: 14
                width: shortcutText.implicitWidth + 6
                radius: 2
                color: Color.surface

                Text {
                    id: shortcutText
                    anchors.centerIn: parent
                    color: Color.accent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption - 1
                    font.bold: true
                    text: HoverTip.shortcut
                }
            }
        }
    }
}
