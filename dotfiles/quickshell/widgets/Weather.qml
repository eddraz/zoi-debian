pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: row.implicitWidth + 8
    implicitHeight: Style.barHeight

    Row {
        id: row
        spacing: 4
        anchors.centerIn: parent

        StatusIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: Weather.ready ? Weather.icon : "cloud"
            stroke: Weather.ready ? Color.barText : Color.muted
        }

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            color: Weather.ready ? Color.barText : Color.muted
            font.family: Style.fontFamily
            font.pixelSize: Style.fontBody
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
                HoverTip.show(root, root.tipText, "Super+T");
            else
                HoverTip.hide();
        }
    }

    readonly property string tipText: {
        if (!Weather.ready)
            return "Weather · fetching";
        const bits = ["Weather"];
        if (Weather.city)
            bits.push(Weather.city);
        bits.push(Weather.label);
        if (Weather.condition)
            bits.push(Weather.condition);
        return bits.join(" · ");
    }

    onTipTextChanged: {
        if (mouse.containsMouse)
            HoverTip.update(root, tipText, "Super+T");
    }
}
