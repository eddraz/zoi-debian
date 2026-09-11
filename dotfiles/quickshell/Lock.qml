pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "Commons"

Scope {
    id: root

    property string password: ""
    property string status: ""
    property bool busy: false

    function lock() {
        Popups.closeAll();
        password = "";
        status = "";
        busy = false;
        sessionLock.locked = true;
    }

    function unlock() {
        sessionLock.locked = false;
        password = "";
        busy = false;
        status = "";
    }

    function tryUnlock() {
        if (busy || password === "")
            return;
        busy = true;
        status = "";
        pam.start();
    }

    IpcHandler {
        target: "lock"

        function activate(): string {
            root.lock();
            return "ok";
        }

        function lock(): string {
            root.lock();
            return "ok";
        }

        function unlock(): string {
            root.unlock();
            return "ok";
        }
    }

    PamContext {
        id: pam
        user: Quickshell.env("USER")
        config: "swaylock"

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.unlock();
            } else {
                root.password = "";
                root.status = "Wrong password";
            }
        }

        onError: {
            root.busy = false;
            root.password = "";
            root.status = "Unlock failed";
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            id: lockSurface

            Item {
                width: lockSurface.width
                height: lockSurface.height

                Image {
                    anchors.fill: parent
                    visible: Wallpaper.current !== ""
                    source: Wallpaper.current !== "" ? ("file://" + Wallpaper.current) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: Wallpaper.current !== "" ? Qt.rgba(0.118, 0.118, 0.180, 0.55) : Color.background
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 14
                    width: 280

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        color: Color.foreground
                        font.family: Style.fontFamily
                        font.pixelSize: 28
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        color: Color.muted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontBody
                        text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        color: Color.accent
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: Quickshell.env("USER")
                    }

                    Rectangle {
                        width: parent.width
                        height: 34
                        radius: Style.radius
                        color: Color.surface
                        border.width: 1
                        border.color: Color.overlay

                        TextInput {
                            id: passwordField
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            color: Color.foreground
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontBody
                            echoMode: TextInput.Password
                            enabled: !root.busy
                            text: root.password
                            onTextChanged: {
                                root.password = text;
                                if (root.status !== "")
                                    root.status = "";
                            }
                            onAccepted: root.tryUnlock()

                            Component.onCompleted: forceActiveFocus()
                        }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        color: root.status === "" ? Color.muted : Color.urgent
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: root.busy ? "Unlocking…" : (root.status !== "" ? root.status : "Enter password")
                    }

                        Rectangle {
                            width: parent.width
                            height: 34
                            radius: Style.radius
                            color: Color.accent
                            opacity: root.busy || root.password === "" ? 0.45 : 1

                            Text {
                                anchors.centerIn: parent
                                color: Color.background
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontBody
                                font.bold: true
                                text: "Unlock"
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: !root.busy && root.password !== ""
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.tryUnlock()
                            }
                        }
                }

                SystemClock {
                    id: clock
                    precision: SystemClock.Minutes
                }
            }
        }
    }
}
