pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "Commons"

Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: true
        imageSupported: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        persistenceSupported: true

        onNotification: notification => {
            Notifs.record(notification);
            const silent = Notifs.dnd && notification.urgency !== NotificationUrgency.Critical;
            notification.tracked = !silent;
        }
    }

    function durationMs(notification) {
        if (notification.urgency === NotificationUrgency.Critical)
            return 0;
        const requested = Number(notification.expireTimeout || 0);
        if (requested > 0)
            return Math.min(20000, Math.max(4000, requested));
        return 7000;
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popupWindow

            required property var modelData

            screen: modelData
            visible: server.trackedNotifications.values.length > 0
            color: "transparent"
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-notifications"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            mask: Region {
                item: toastColumn
            }

            Column {
                id: toastColumn
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: Style.barHeight + 8
                anchors.rightMargin: Style.pad
                spacing: 8
                width: 320

                Repeater {
                    model: server.trackedNotifications

                    Rectangle {
                        id: toast

                        required property var modelData
                        readonly property string iconSource: {
                            if (modelData.image !== "")
                                return modelData.image;
                            if (modelData.appIcon !== "")
                                return Quickshell.iconPath(modelData.appIcon);
                            return "";
                        }

                        width: 320
                        implicitHeight: toastBody.implicitHeight + 16
                        radius: Style.radius
                        color: Color.popupBackground
                        border.width: 1
                        border.color: modelData.urgency === NotificationUrgency.Critical ? Color.urgent : Color.cardBorder

                        Column {
                            id: toastBody
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 4

                            Row {
                                spacing: 8
                                width: parent.width

                                IconImage {
                                    visible: toast.iconSource !== ""
                                    implicitSize: 22
                                    source: toast.iconSource
                                }

                                Rectangle {
                                    visible: toast.iconSource === ""
                                    implicitWidth: 10
                                    implicitHeight: 10
                                    radius: 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: toast.modelData.urgency === NotificationUrgency.Critical ? Color.urgent : Color.accent
                                }

                                Column {
                                    width: parent.width - (toast.iconSource !== "" ? 30 : 18)
                                    spacing: 2

                                    Text {
                                        width: parent.width
                                        color: Color.popupMuted
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.fontCaption
                                        elide: Text.ElideRight
                                        text: toast.modelData.appName
                                    }

                                    Text {
                                        width: parent.width
                                        color: Color.popupText
                                        font.family: Style.fontFamily
                                        font.pixelSize: Style.fontCaption
                                        font.bold: true
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        text: toast.modelData.summary
                                    }
                                }
                            }

                            Text {
                                visible: toast.modelData.body !== ""
                                width: parent.width
                                color: Color.popupText
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontCaption
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                                text: toast.modelData.body
                            }

                            Row {
                                spacing: 6
                                visible: toast.modelData.actions.length > 0

                                Repeater {
                                    model: toast.modelData.actions

                                    Rectangle {
                                        required property var modelData
                                        height: 22
                                        implicitWidth: actionLabel.implicitWidth + 12
                                        radius: Style.radius
                                        color: actionMouse.containsMouse ? Color.focusFill : Color.surface
                                        border.width: 1
                                        border.color: Color.subtleBorder

                                        Text {
                                            id: actionLabel
                                            anchors.centerIn: parent
                                            color: Color.popupText
                                            font.family: Style.fontFamily
                                            font.pixelSize: Style.fontCaption
                                            text: modelData.text
                                        }

                                        MouseArea {
                                            id: actionMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: modelData.invoke()
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: toast.modelData.dismiss()
                        }

                        Timer {
                            interval: root.durationMs(toast.modelData)
                            running: interval > 0
                            onTriggered: toast.modelData.expire()
                        }
                    }
                }
            }
        }
    }
}
