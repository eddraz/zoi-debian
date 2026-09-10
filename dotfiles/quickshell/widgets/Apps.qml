import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: Style.iconSize + 6
    implicitHeight: Style.barHeight

    StatusIcon {
        anchors.centerIn: parent
        icon: "apps"
        stroke: Radio.playing ? Color.accent : Color.barText
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, Radio.playing ? "Apps · Lofi Radio ON" : "Native Apps");
            else
                HoverTip.hide();
        }
    }
}
