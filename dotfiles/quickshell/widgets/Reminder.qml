pragma ComponentBehavior: Bound

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
        icon: "alarm"
        stroke: Reminders.count > 0 ? Color.peach : Color.barText
    }

    Rectangle {
        visible: Reminders.count > 0
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 0
        anchors.topMargin: 4
        width: Math.max(10, countLabel.implicitWidth + 4)
        height: 10
        radius: 4
        color: Color.peach

        Text {
            id: countLabel
            anchors.centerIn: parent
            color: Color.background
            font.family: Style.fontFamily
            font.pixelSize: 8
            font.bold: true
            text: String(Reminders.count)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, "Reminders" + (Reminders.count > 0 ? (" · " + Reminders.count + " active") : ""), "Super+Shift+N");
            else
                HoverTip.hide();
        }
    }
}
