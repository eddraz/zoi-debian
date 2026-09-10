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
    implicitHeight: 26
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

        y: (HoverTip.text !== "" && HoverTip.screen === modelData) ? 3 : 0
        Behavior on y { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutQuad } }

        opacity: (HoverTip.text !== "" && HoverTip.screen === modelData) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutQuad } }

        height: 22
        width: contentRow.implicitWidth + 14
        x: Math.max(6, Math.min(root.width - width - 6, HoverTip.centerX - width / 2))
        color: Color.popupBackground
        radius: Style.radius
        border.width: 1
        border.color: Color.cardBorder

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
                height: 15
                width: shortcutText.implicitWidth + 8
                radius: 3
                color: Color.surface
                border.width: 1
                border.color: Color.subtleBorder

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
