import QtQuick
import "../Commons"

MouseArea {
    id: root

    z: -1
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Rectangle {
        anchors.fill: parent
        radius: Style.radius
        color: Color.focusFill
        visible: root.containsMouse
    }
}
