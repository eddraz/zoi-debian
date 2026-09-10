import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Commons"

PanelWindow {
    id: root

    required property var modelData

    readonly property string edge: PluginRegistry.barEdge
    readonly property bool barVertical: edge === "left" || edge === "right"
    readonly property bool tipVisible: HoverTip.text !== "" && HoverTip.screen === modelData

    screen: modelData
    visible: tipVisible
    color: "transparent"
    implicitHeight: barVertical ? modelData.height : 26
    implicitWidth: barVertical ? (bubble.width + 12) : modelData.width
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}
    WlrLayershell.namespace: "quickshell-tip"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: edge === "top" || barVertical
        bottom: edge === "bottom" || barVertical
        left: edge === "left" || !barVertical
        right: edge === "right" || !barVertical
    }

    Rectangle {
        id: bubble

        // Position based on bar edge
        x: {
            if (root.barVertical) {
                // For vertical bars, appear beside the bar
                if (root.edge === "left")
                    return root.tipVisible ? 3 : 0;
                else
                    return root.tipVisible ? (root.width - width - 3) : root.width;
            }
            return Math.max(6, Math.min(root.width - width - 6, HoverTip.centerX - width / 2));
        }

        y: {
            if (root.barVertical) {
                // Use centerX as centerY for vertical bars
                return Math.max(6, Math.min(root.height - height - 6, HoverTip.centerX - height / 2));
            }
            if (root.edge === "bottom")
                return root.tipVisible ? (root.height - height - 3) : root.height;
            return root.tipVisible ? 3 : 0;
        }

        Behavior on x { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutQuad } }
        Behavior on y { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutQuad } }

        opacity: root.tipVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutQuad } }

        height: 22
        width: contentRow.implicitWidth + 14
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
