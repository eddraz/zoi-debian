pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import "../Commons"

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: Style.barHeight

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: 10

            Rectangle {
                id: chip

                required property int index
                readonly property int number: index + 1
                readonly property var workspace: {
                    const values = I3.workspaces.values;
                    for (let i = 0; i < values.length; i++) {
                        if (values[i].number === chip.number)
                            return values[i];
                    }
                    return null;
                }
                readonly property bool focused: I3.focusedWorkspace && I3.focusedWorkspace.number === number
                readonly property bool occupied: workspace !== null
                readonly property bool urgent: workspace ? workspace.urgent : false

                implicitWidth: Math.max(22, label.implicitWidth + 10)
                implicitHeight: Style.chipHeight
                radius: Style.radius
                color: focused ? Color.accent : (urgent ? Color.urgent : Color.surface)
                opacity: occupied || focused ? 1 : 0.45

                Text {
                    id: label
                    anchors.centerIn: parent
                    color: chip.focused ? Color.background : Color.foreground
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    font.bold: chip.focused
                    text: chip.number === 10 ? "0" : String(chip.number)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: I3.dispatch("workspace number " + chip.number)
                }
            }
        }
    }
}
