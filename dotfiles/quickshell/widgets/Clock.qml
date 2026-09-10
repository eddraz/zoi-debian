import QtQuick
import Quickshell
import "../Commons"

Item {
    id: root

    signal togglePanel

    implicitWidth: label.implicitWidth
    implicitHeight: Style.barHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: label
        anchors.centerIn: parent
        color: Color.barText
        font.family: Style.fontFamily
        font.pixelSize: Style.fontBody
        text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, Qt.formatDateTime(clock.date, "dddd d MMMM yyyy"));
            else
                HoverTip.hide();
        }
    }
}
