import QtQuick
import Quickshell.Wayland
import "../Commons"

Item {
    id: root

    property int maxWidth: 180

    readonly property var toplevel: ToplevelManager.activeToplevel
    readonly property string title: {
        if (!toplevel)
            return "";
        return toplevel.title || toplevel.appId || "";
    }

    visible: title !== ""
    implicitWidth: visible ? Math.min(maxWidth, label.implicitWidth) : 0
    implicitHeight: Style.barHeight
    clip: true

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        width: root.width
        elide: Text.ElideRight
        color: Color.barText
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        opacity: 0.9
        text: root.title
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (!root.toplevel)
                return;
            if (event.button === Qt.MiddleButton)
                root.toplevel.close();
            else
                root.toplevel.activate();
        }
        onContainsMouseChanged: {
            if (containsMouse && root.title !== "")
                HoverTip.show(root, "Window · " + root.title, "Super+Shift+W");
            else
                HoverTip.hide();
        }
    }

    onTitleChanged: if (mouse.containsMouse)
        HoverTip.update(root, "Window · " + title, "Super+Shift+W")
}
