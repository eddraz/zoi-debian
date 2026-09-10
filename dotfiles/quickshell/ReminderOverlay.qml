pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Commons"
import "Ui"

Scope {
    id: root

    property bool opened: false
    property string step: "minutes"
    property string minutes: ""
    property string draft: ""

    function open(): void {
        step = "minutes";
        minutes = "";
        draft = "";
        opened = true;
        Reminders.refresh();
        Qt.callLater(() => input.forceActiveFocus());
    }

    function close(): void {
        opened = false;
        draft = "";
        step = "minutes";
    }

    function toggle(): void {
        if (opened)
            close();
        else
            open();
    }

    function submit(): void {
        if (step === "minutes") {
            const n = parseInt(draft.trim(), 10);
            if (!draft.trim()) {
                close();
                return;
            }
            if (!n || n < 1) {
                Quickshell.execDetached(["notify-send", "Reminder", "Enter minutes as a number"]);
                return;
            }
            minutes = String(n);
            draft = "";
            step = "message";
            Qt.callLater(() => input.forceActiveFocus());
            return;
        }
        Reminders.add(minutes, draft.trim());
        close();
    }

    Connections {
        target: Popups
        function onClosed() {
            root.close();
        }
    }

    IpcHandler {
        target: "reminders"

        function toggle(): string {
            root.toggle();
            return "ok";
        }

        function open(): string {
            root.open();
            return "ok";
        }

        function close(): string {
            root.close();
            return "ok";
        }
    }

    PanelWindow {
        visible: root.opened
        color: "transparent"
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-reminders"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 72
            width: Math.min(Style.popupMaxWidth, parent.width - Style.pad * 2)
            implicitHeight: col.implicitHeight + Style.pad * 2
            color: Color.popupBackground
            radius: Style.radius
            border.width: 1
            border.color: Color.surface

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    input.forceActiveFocus();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    root.close();
                    event.accepted = true;
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: input.forceActiveFocus()
            }

            Column {
                id: col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.pad
                spacing: 8

                Text {
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    font.bold: true
                    text: "Reminder"
                }

                Text {
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: root.step === "minutes" ? "Minutes from now" : "Message"
                }

                Rectangle {
                    width: parent.width
                    height: 30
                    radius: Style.radius
                    color: Color.surface
                    border.width: 1
                    border.color: Color.accent

                    TextInput {
                        id: input
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        color: Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontBody
                        clip: true
                        text: root.draft
                        onTextChanged: root.draft = text
                        onAccepted: root.submit()
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                                card.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                    }
                }

                Text {
                    visible: Reminders.count > 0
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: "Pending"
                }

                Repeater {
                    model: Reminders.items

                    Rectangle {
                        required property var modelData
                        required property int index
                        width: col.width
                        height: 26
                        radius: Style.radius
                        color: Color.surface

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            color: Color.popupText
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontCaption
                            text: (modelData.left ? modelData.left + " · " : "") + (modelData.message || "")
                        }

                        HoverMouse {
                            onClicked: Reminders.cancel(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
