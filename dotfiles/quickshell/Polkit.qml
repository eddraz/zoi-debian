pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import "Commons"

Scope {
    id: root

    property bool closing: false
    property bool submitted: false
    property bool errorFlash: false
    property int shakeOffset: 0
    property string currentMessage: ""
    property string currentPrompt: ""
    property bool responseRequired: false
    property bool responseVisible: false

    readonly property bool dialogVisible: agent.isActive || closing
    readonly property bool inputLocked: submitted || errorFlash

    function authorizationLabel(message) {
        const text = String(message || "");
        const match = text.match(/^Authentication is (?:needed|required) to run [`']([^`']+)[`'] as /i);
        if (match)
            return "Authorize '" + match[1] + "'";
        return text || "Authentication required";
    }

    function resetSnapshot() {
        currentMessage = "";
        currentPrompt = "";
        responseRequired = false;
        responseVisible = false;
        submitted = false;
        errorFlash = false;
        passwordInput.text = "";
    }

    function syncFromFlow() {
        const flow = agent.flow;
        if (!flow)
            return;
        currentMessage = String(flow.message || "Authentication is needed…");
        currentPrompt = String(flow.inputPrompt || "");
        responseRequired = !!flow.isResponseRequired;
        responseVisible = !!flow.responseVisible;
    }

    function beginFlow() {
        closeTimer.stop();
        closing = false;
        submitted = false;
        errorFlash = false;
        passwordInput.text = "";
        syncFromFlow();
        Qt.callLater(refocus);
    }

    function refocus() {
        if (!dialogVisible || inputLocked)
            return;
        passwordInput.forceActiveFocus();
    }

    function submitResponse() {
        const flow = agent.flow;
        if (!flow || !flow.isResponseRequired || inputLocked)
            return;
        if (passwordInput.text === "")
            return;
        submitted = true;
        errorFlash = false;
        flow.submit(passwordInput.text);
        passwordInput.text = "";
    }

    function cancelRequest() {
        const flow = agent.flow;
        passwordInput.text = "";
        submitted = false;
        closing = true;
        closeTimer.restart();
        if (flow)
            flow.cancelAuthenticationRequest();
    }

    function triggerFailureFeedback() {
        submitted = false;
        errorFlash = true;
        passwordInput.text = "";
        errorTimer.restart();
        shakeAnimation.restart();
    }

    Timer {
        id: closeTimer
        interval: 220
        onTriggered: {
            root.closing = false;
            root.resetSnapshot();
        }
    }

    Timer {
        id: errorTimer
        interval: 900
        onTriggered: {
            root.errorFlash = false;
            Qt.callLater(root.refocus);
        }
    }

    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation {
            target: root
            property: "shakeOffset"
            to: -8
            duration: 35
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: root
            property: "shakeOffset"
            to: 8
            duration: 50
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: root
            property: "shakeOffset"
            to: 0
            duration: 55
            easing.type: Easing.OutQuad
        }
    }

    PolkitAgent {
        id: agent
        path: "/org/quickshell/PolkitAgent"

        onAuthenticationRequestStarted: root.beginFlow()
        onIsActiveChanged: {
            if (isActive)
                root.syncFromFlow();
            else if (!root.closing)
                root.resetSnapshot();
        }
        onIsRegisteredChanged: {
            if (isRegistered)
                console.log("polkit agent registered");
            else
                console.warn("polkit agent is not registered; another agent may be running");
        }
    }

    Connections {
        target: agent.flow

        function onIsResponseRequiredChanged() {
            root.syncFromFlow();
            if (!agent.flow || !agent.flow.isResponseRequired)
                passwordInput.text = "";
            if (!root.inputLocked)
                Qt.callLater(root.refocus);
        }

        function onInputPromptChanged() {
            root.syncFromFlow();
        }

        function onResponseVisibleChanged() {
            root.syncFromFlow();
        }

        function onAuthenticationFailed() {
            root.syncFromFlow();
            root.triggerFailureFeedback();
        }

        function onAuthenticationSucceeded() {
            root.closing = true;
            closeTimer.restart();
        }

        function onAuthenticationRequestCancelled() {
            root.closing = true;
            closeTimer.restart();
        }
    }

    PanelWindow {
        id: panel
        visible: root.dialogVisible
        color: "transparent"
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.dialogVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.118, 0.118, 0.180, 0.55)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.refocus()
        }

        Rectangle {
            id: card
            width: 300
            implicitHeight: cardColumn.implicitHeight + 28
            radius: Style.radius
            color: Color.popupBackground
            border.width: 1
            border.color: root.errorFlash ? Color.urgent : Color.accent
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.shakeOffset

            MouseArea {
                anchors.fill: parent
                onClicked: root.refocus()
            }

            Column {
                id: cardColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                Text {
                    width: parent.width
                    color: root.errorFlash ? Color.urgent : Color.accent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    font.bold: true
                    text: "Authorization"
                }

                Text {
                    width: parent.width
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    wrapMode: Text.Wrap
                    text: root.authorizationLabel(root.currentMessage)
                }

                Text {
                    visible: Quickshell.env("USER") !== ""
                    width: parent.width
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: "User " + Quickshell.env("USER")
                }

                Rectangle {
                    width: parent.width
                    height: 34
                    radius: Style.radius
                    color: Color.surface
                    border.width: 1
                    border.color: root.errorFlash ? Color.urgent : Color.overlay
                    opacity: root.inputLocked ? 0.45 : 1

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        visible: passwordInput.text.length === 0 && !root.inputLocked
                        color: Color.muted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: root.currentPrompt !== "" ? root.currentPrompt : "Password"
                    }

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: Text.AlignVCenter
                        color: Color.foreground
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontBody
                        echoMode: root.responseVisible ? TextInput.Normal : TextInput.Password
                        enabled: root.dialogVisible && !root.inputLocked
                        readOnly: root.inputLocked
                        onAccepted: root.submitResponse()
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.cancelRequest();
                                event.accepted = true;
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    color: root.errorFlash ? Color.urgent : Color.accent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: root.errorFlash ? "Wrong password" : (root.submitted ? "Checking…" : " ")
                }

                Row {
                    spacing: 6
                    width: parent.width

                    Rectangle {
                        width: (parent.width - 6) / 2
                        height: 26
                        radius: Style.radius
                        color: Color.surface

                        Text {
                            anchors.centerIn: parent
                            color: Color.popupText
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontCaption
                            text: "Cancel"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cancelRequest()
                        }
                    }

                    Rectangle {
                        width: (parent.width - 6) / 2
                        height: 26
                        radius: Style.radius
                        color: root.inputLocked ? Color.surface : Color.accent
                        opacity: root.inputLocked ? 0.45 : 1

                        Text {
                            anchors.centerIn: parent
                            color: root.inputLocked ? Color.popupMuted : Color.background
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontCaption
                            text: root.submitted ? "Checking…" : "Authenticate"
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.inputLocked
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.submitResponse()
                        }
                    }
                }
            }
        }
    }
}
