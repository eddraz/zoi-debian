pragma ComponentBehavior: Bound

import QtQuick
import "../Commons" as Commons
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: row.implicitWidth + 8
    implicitHeight: Commons.Style.barHeight

    Row {
        id: row
        spacing: 4
        anchors.centerIn: parent

        StatusIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: Commons.Weather.ready ? Commons.Weather.icon : "cloud"
            stroke: Commons.Weather.ready ? Commons.Color.barText : Commons.Color.muted
        }

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            color: Commons.Weather.ready ? Commons.Color.barText : Commons.Color.muted
            font.family: Commons.Style.fontFamily
            font.pixelSize: Commons.Style.fontBody
            font.bold: true
            text: Commons.Weather.label
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
                Commons.Weather.refresh();
            else
                root.togglePanel();
        }
        onContainsMouseChanged: {
            if (containsMouse)
                Commons.HoverTip.show(root, root.tipText, "Super+T");
            else
                Commons.HoverTip.hide();
        }
    }

    readonly property string tipText: {
        if (!Commons.Weather.ready)
            return "Weather · fetching";
        const bits = ["Weather"];
        if (Commons.Weather.city)
            bits.push(Commons.Weather.city);
        bits.push(Commons.Weather.label);
        if (Commons.Weather.condition)
            bits.push(Commons.Weather.condition);
        return bits.join(" · ");
    }

    onTipTextChanged: {
        if (mouse.containsMouse)
            Commons.HoverTip.update(root, tipText, "Super+T");
    }
}
