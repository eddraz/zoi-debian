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

    visible: label !== ""
    width: 18
    height: 18
    radius: 3
    color: Color.crust
    border.width: 1
    border.color: Color.overlay

    Text {
        anchors.centerIn: parent
        color: Color.accent
        font.family: Style.fontFamily
        font.pixelSize: 10
        font.bold: true
        text: root.label
    }
}
