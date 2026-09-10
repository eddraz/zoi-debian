import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: chip.implicitWidth + 6
    implicitHeight: Style.barHeight

    Rectangle {
        id: chip
        anchors.centerIn: parent
        implicitWidth: Math.max(28, label.implicitWidth + 10)
        implicitHeight: Style.chipHeight
        radius: Style.radius
        color: Color.surface

        Text {
            id: label
            anchors.centerIn: parent
            color: Color.barText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            font.bold: true
            text: Keyboard.label
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.togglePanel();
            else
                Keyboard.cycle();
        }
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, "Keyboard · " + Keyboard.name, "Alt+Shift");
            else
                HoverTip.hide();
        }
    }
}
