pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"

Rectangle {
    id: root

    property int slot: 0
    readonly property string label: {
        if (slot < 0 || slot > 9)
            return "";
        return slot === 9 ? "0" : String(slot + 1);
    }

    visible: label !== "" && !Popups.isSearching
    width: Math.max(18, indexLabel.implicitWidth + 8)
    height: 18
    radius: 4
    color: Color.crust
    border.width: 1
    border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.28)

    Text {
        id: indexLabel
        anchors.centerIn: parent
        color: Color.accent
        font.family: Style.fontFamily
        font.pixelSize: 10
        font.bold: true
        text: root.label
    }
}
