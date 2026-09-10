pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../Commons"

Row {
    spacing: 6

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: trayItem

            required property var modelData

            implicitWidth: 18
            implicitHeight: 18
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onClicked: event => {
                if (event.button === Qt.LeftButton)
                    trayItem.modelData.activate();
                else if (event.button === Qt.MiddleButton)
                    trayItem.modelData.secondaryActivate();
                else
                    trayItem.modelData.display(QsWindow.window, 0, implicitHeight);
            }

            Image {
                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                source: trayItem.modelData.icon
                sourceSize.width: 16
                sourceSize.height: 16
            }
        }
    }
}
