import QtQuick
import "../Commons"
import "../Ui"

Item {
    id: root

    signal togglePanel

    implicitWidth: Style.iconSize + 6
    implicitHeight: Style.barHeight

    StatusIcon {
        anchors.centerIn: parent
        icon: Notifs.dnd ? "bell-off" : "bell"
        stroke: Notifs.dnd ? Color.muted : (Notifs.unread > 0 ? Color.accent : Color.barText)
    }

    Rectangle {
        visible: Notifs.unread > 0 && !Notifs.dnd
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 1
        anchors.topMargin: 4
        width: 7
        height: 7
        radius: 4
        color: Color.urgent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Notifs.toggleDnd();
            else {
                Notifs.clearUnread();
                root.togglePanel();
            }
        }
        onContainsMouseChanged: {
            if (containsMouse)
                HoverTip.show(root, "Notifications" + (Notifs.dnd ? " · DND" : (Notifs.unread > 0 ? (" · " + Notifs.unread + " new") : "")), "Super+N");
            else
                HoverTip.hide();
        }
    }
}
