pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../Commons"

// Extracted search bar from PopupCard
Rectangle {
    id: root

    property bool searching: false
    property alias searchQuery: findField.text
    property alias activeFocusOnField: findField.activeFocus

    signal closeSearch()
    signal applySearch()
    signal runItem()
    signal navigateSearch(int delta)
    signal nextSection(bool back)
    signal escapePressed()

    function forceActiveFocus() {
        findField.forceActiveFocus();
    }

    visible: searching
    width: parent ? parent.width : 252
    height: visible ? 30 : 0
    radius: Style.radius
    color: Color.crust
    border.width: 1
    border.color: Color.accent

    Row {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 6
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: Color.accent
            font.family: Style.fontFamily
            font.pixelSize: 11
            font.bold: true
            text: "/"
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(50, parent.width - 60)
            height: parent.height

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: findField.text === ""
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: "Filtrar opciones..."
            }

            TextInput {
                id: findField
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                clip: true

                onTextChanged: {
                    root.applySearch();
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.escapePressed();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.runItem();
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                        root.navigateSearch(1);
                        event.accepted = true;
                        return;
                    }
                    if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                        root.navigateSearch(-1);
                        event.accepted = true;
                        return;
                    }
                }
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 16
            width: escLabel.implicitWidth + 8
            radius: 2
            color: Color.surface

            Text {
                id: escLabel
                anchors.centerIn: parent
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: 9
                text: "Esc"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.escapePressed();
                }
            }
        }
    }
}
