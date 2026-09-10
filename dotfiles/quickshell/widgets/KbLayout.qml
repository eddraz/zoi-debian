import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: Style.iconSize + 6
    implicitHeight: Style.barHeight

    readonly property string tipText: "Teclado · " + Keyboard.label + " (" + Keyboard.name + ")"

    StatusIcon {
        anchors.centerIn: parent
        icon: "keyboard"
        stroke: mouse.containsMouse ? Color.accent : Color.barText
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Keyboard.cycle();
            else
                root.togglePanel();
        }
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, root.tipText, "Click: menú");
            else
                HoverTip.hide();
        }
    }

    onTipTextChanged: if (mouse.containsMouse)
        HoverTip.update(root, tipText, "Click: menú")
}
