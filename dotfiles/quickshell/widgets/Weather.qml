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
            text: Weather.label
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.MiddleButton)
                Weather.refresh();
            else
                root.togglePanel();
        }
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, root.tipText);
            else
                HoverTip.hide();
        }
    }

    readonly property string tipText: {
        if (!Weather.ready)
            return "Weather";
        const bits = [];
        if (Weather.city)
            bits.push(Weather.city);
        bits.push(Weather.label);
        bits.push(Weather.condition);
        return bits.join(" · ");
    }

    onTipTextChanged: if (mouse.containsMouse)
        HoverTip.update(root, tipText)
}
