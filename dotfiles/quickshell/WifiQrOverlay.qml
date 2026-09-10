pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Commons"
import "Ui"

// Centered Wi-Fi share overlay. Esc or click on the scrim dismisses.
Item {
    id: root

    property bool opened: false
    property var qrRows: []
    property int qrSize: 0
    property string iface: ""
    property string ssid: ""
    property string security: ""
    property string password: ""
    property string error: ""
    property bool loading: false
    property bool expectedStop: false

    readonly property string wifiQrHelper: Quickshell.env("HOME") + "/.local/bin/qs-wifi-qr"
    readonly property bool showingQr: qrSize > 0 && !loading && error === ""

    readonly property color onScrim: "white"
    readonly property color onScrimDim: Qt.rgba(1, 1, 1, 0.6)
    readonly property color onScrimUrgent: "#ff6b6b"

    function open() {
        error = "";
        opened = true;
        generate();
        Qt.callLater(function() {
            if (root.opened) keyCatcher.forceActiveFocus();
        });
    }

    function close() {
        if (qrProc.running) {
            root.expectedStop = true;
            qrProc.running = false;
        }
        root.opened = false;
        root.qrSize = 0;
        root.qrRows = [];
        root.ssid = "";
        root.iface = "";
        root.security = "";
        root.error = "";
        root.password = "";
    }

    function generate() {
        if (qrProc.running) {
            expectedStop = true;
            qrProc.running = false;
        }
        qrSize = 0;
        qrRows = [];
        error = "";
        loading = true;
        expectedStop = false;
        qrProc.command = [wifiQrHelper];
        qrProc.running = true;
    }

    function updateQr(raw) {
        const lines = String(raw || "").trim().split(/\r?\n/).filter(function(l) { return l !== ""; });
        if (lines.length === 0) {
            error = "Empty QR output";
            return;
        }
        let meta = { iface: "", security: "", ssid: "" };
        let rows = lines;
        if (lines[0].indexOf("meta\t") === 0) {
            const parts = lines.shift().split("\t");
            meta.iface = parts[1] || "";
            meta.security = parts[2] || "";
            meta.ssid = parts.slice(3).join("\t");
        }
        if (meta.ssid) ssid = meta.ssid;
        if (meta.iface) iface = meta.iface;
        if (meta.security) security = meta.security;
        if (rows.length === 0 || rows[0].length !== rows.length) {
            error = "Malformed QR matrix";
            return;
        }
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].length !== rows[0].length || !/^[01]+$/.test(rows[i])) {
                error = "Malformed QR matrix";
                return;
            }
        }
        qrRows = rows;
        qrSize = rows[0].length;
        if (qrSize > 0) error = "";
    }

    IpcHandler {
        target: "wifiqr"

        function toggle(): string {
            if (root.opened)
                root.close();
            else
                root.open();
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

    Connections {
        target: Popups
        function onClosed() {
            root.close();
        }
    }

    Process {
        id: qrProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (!root.expectedStop) root.updateQr(text)
        }
        onExited: function(exitCode) {
            root.loading = false;
            if (root.expectedStop)
                return;
            if (exitCode !== 0 || root.qrSize === 0) {
                if (root.error === "")
                    root.error = "Could not generate the Wi-Fi QR code (exit " + exitCode + ")";
                root.qrSize = 0;
                root.qrRows = [];
            }
        }
    }

    PanelWindow {
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-wifiqr"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.78)

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Item {
            id: keyCatcher
            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: root.close()

            Item {
                id: card
                anchors.centerIn: parent
                width: 280
                height: content.implicitHeight + 32
                scale: Math.min(1,
                    (keyCatcher.width - 32) / Math.max(1, width),
                    (keyCatcher.height - 32) / Math.max(1, height))

                MouseArea { anchors.fill: parent; onClicked: {} }

                Column {
                    id: content
                    anchors.centerIn: parent
                    width: 240
                    spacing: 12

                    Text {
                        textFormat: Text.PlainText
                        width: parent.width
                        text: (root.ssid !== "" ? root.ssid : "Wi-Fi").toUpperCase()
                        color: root.onScrimDim
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        font.bold: true
                        font.letterSpacing: 2
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        id: qrCanvas
                        visible: root.showingQr
                        readonly property int moduleSize: root.qrSize > 0
                            ? Math.max(4, Math.floor((parent.width - 24) / root.qrSize))
                            : 0
                        width: root.qrSize * moduleSize + 16
                        height: width
                        color: "white"
                        radius: 8
                        anchors.horizontalCenter: parent.horizontalCenter

                        Grid {
                            anchors.fill: parent
                            anchors.margins: 8
                            columns: root.qrSize
                            rows: root.qrSize

                            Repeater {
                                model: root.qrSize * root.qrSize
                                Rectangle {
                                    required property int index
                                    readonly property int matrixRow: Math.floor(index / root.qrSize)
                                    readonly property int matrixColumn: index - (matrixRow * root.qrSize)
                                    width: qrCanvas.moduleSize
                                    height: qrCanvas.moduleSize
                                    color: (root.qrRows[matrixRow] || "").charAt(matrixColumn) === "1" ? "#111111" : "transparent"
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.loading
                        width: parent.width
                        text: "Generando QR..."
                        color: root.onScrimDim
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        visible: root.error !== ""
                        width: parent.width
                        text: root.error
                        color: root.onScrimUrgent
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        visible: root.showingQr
                        width: parent.width
                        text: "Escaneá para unirte a esta red"
                        color: root.onScrimDim
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        textFormat: Text.PlainText
                        visible: root.showingQr && root.security !== "" && root.security !== "nopass"
                        width: parent.width
                        text: "Seguridad: " + (root.security || "")
                        color: root.onScrimDim
                        font.family: Style.fontFamily
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
