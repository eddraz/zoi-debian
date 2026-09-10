pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: Style.iconSize + 6
    implicitHeight: Style.barHeight

    readonly property string tipText: !Audio.ready ? "Volume" : (Audio.muted ? "Volume · Muted" : "Volume · " + Audio.percent + "%")

    StatusIcon {
        anchors.centerIn: parent
        icon: Audio.muted || !Audio.ready ? "mute" : "volume"
        level: Audio.percent / 100
        stroke: Audio.muted ? Color.urgent : Color.barText
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Audio.toggleMute();
            else
                root.togglePanel();
        }
        onWheel: event => {
            Audio.adjust(event.angleDelta.y > 0 ? 0.05 : -0.05);
            event.accepted = true;
        }
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, root.tipText, "Super+M");
            else
                HoverTip.hide();
        }
    }

    onTipTextChanged: {
        if (mouse.containsMouse)
            HoverTip.update(root, tipText, "Super+M");
    }
}
