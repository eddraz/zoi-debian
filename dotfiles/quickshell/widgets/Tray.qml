pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import "../Commons"
import "../Ui"

Item {
    id: root

    property bool expanded: true

    implicitWidth: row.implicitWidth
    implicitHeight: Style.barHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        MouseArea {
            id: trayBtn
            implicitWidth: Style.iconSize + 6
            implicitHeight: Style.barHeight
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            StatusIcon {
                anchors.centerIn: parent
                icon: "tray"
                stroke: Color.barText
            }

            onClicked: {
                if (trayRepeater.count > 0)
                    root.expanded = !root.expanded;
            }

            onContainsMouseChanged: {
                if (containsMouse) {
                    if (trayRepeater.count === 0)
                        HoverTip.show(trayBtn, "System Tray");
                    else if (root.expanded)
                        HoverTip.show(trayBtn, "System Tray (" + trayRepeater.count + " active) — click to hide");
                    else
                        HoverTip.show(trayBtn, "System Tray (" + trayRepeater.count + " hidden) — click to show");
                } else {
                    HoverTip.hide();
                }
            }
        }

        Repeater {
            id: trayRepeater
            model: root.expanded ? SystemTray.items : []

            MouseArea {
                id: trayItem

                required property var modelData

                implicitWidth: 18
                implicitHeight: 18
                anchors.verticalCenter: parent.verticalCenter
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: event => {
                    if (event.button === Qt.LeftButton)
                        trayItem.modelData.activate();
                    else if (event.button === Qt.MiddleButton)
                        trayItem.modelData.secondaryActivate();
                    else
                        trayItem.modelData.display(QsWindow.window, 0, implicitHeight);
                }

                Image {
                    id: trayImg
                    anchors.fill: parent
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    source: trayItem.modelData.icon
                    sourceSize.width: 16
                    sourceSize.height: 16
                }

                StatusIcon {
                    anchors.centerIn: parent
                    visible: trayImg.status !== Image.Ready
                    icon: "tray"
                    stroke: Color.muted
                }
            }
        }
    }
}
