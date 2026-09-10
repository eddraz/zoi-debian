import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    readonly property int titleMax: 96
    readonly property bool showTitle: Media.active && Media.title !== ""

    visible: Media.active
    implicitWidth: visible ? (Style.iconSize + 6 + (showTitle ? titleMax + 4 : 0)) : 0
    implicitHeight: Style.barHeight

    Rectangle {
        anchors.fill: parent
        visible: Media.armed
        color: "transparent"
        border.width: 1
        border.color: Color.accent
        radius: Style.radius
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        StatusIcon {
            anchors.verticalCenter: parent.verticalCenter
            icon: Media.playing ? "pause" : "play"
            stroke: Media.playing ? Color.accent : Color.barText
        }

        Text {
            visible: root.showTitle
            anchors.verticalCenter: parent.verticalCenter
            width: root.titleMax
            elide: Text.ElideRight
            color: Color.barText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            text: Media.title
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
                Media.toggle();
            else
                root.togglePanel();
        }
        onWheel: event => {
            if (event.angleDelta.y > 0)
                Media.previous();
            else
                Media.next();
            event.accepted = true;
        }
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, root.tipText);
            else
                HoverTip.hide();
        }
    }

    readonly property string tipText: {
        if (!Media.active)
            return "Media";
        const bits = [];
        if (Media.title)
            bits.push(Media.title);
        if (Media.artist)
            bits.push(Media.artist);
        if (bits.length === 0)
            return Media.identity || "Media";
        return bits.join(" · ");
    }

    onTipTextChanged: if (mouse.containsMouse)
        HoverTip.update(root, tipText)
}
