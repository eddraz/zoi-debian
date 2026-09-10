import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: chip.implicitWidth + 6
    implicitHeight: Style.barHeight

    readonly property string tipText: "Teclado · " + Keyboard.name

    Rectangle {
        id: chip
        anchors.centerIn: parent
        implicitWidth: contentRow.implicitWidth + 14
        implicitHeight: Style.chipHeight
        radius: Style.radius
        color: mouse.containsMouse ? Color.focusFill : Color.surface
        border.width: 1
        border.color: mouse.containsMouse ? Color.accent : Color.subtleBorder
        Behavior on color { ColorAnimation { duration: Style.animDuration } }
        Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 5

            StatusIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: "keyboard"
                stroke: Color.barText
            }

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                color: Color.barText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                font.bold: true
                text: Keyboard.label
            }
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
