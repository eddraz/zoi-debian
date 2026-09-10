import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    visible: Notifs.dnd
    implicitWidth: visible ? Style.iconSize + 6 : 0
    implicitHeight: Style.barHeight

    StatusIcon {
        anchors.centerIn: parent
        icon: "bell-off"
        stroke: Color.peach
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifs.toggleDnd()
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, "Do not disturb · click to allow");
            else
                HoverTip.hide();
        }
    }
}
