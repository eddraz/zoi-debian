import QtQuick
import "../Commons"

Item {
    id: root

    property string icon: "volume"
    property real level: 1
    property bool charging: false
    property bool enabled: true
    property color stroke: Color.barText

    implicitWidth: Style.iconSize
    implicitHeight: Style.iconSize

    onIconChanged: canvas.requestPaint()
    onLevelChanged: canvas.requestPaint()
    onChargingChanged: canvas.requestPaint()
    onEnabledChanged: canvas.requestPaint()
    onStrokeChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            const w = width;
            const h = height;
            ctx.reset();
            ctx.clearRect(0, 0, w, h);
            ctx.strokeStyle = root.stroke;
            ctx.fillStyle = root.stroke;
            ctx.lineWidth = Math.max(1.2, w * 0.09);
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            if (root.icon === "volume" || root.icon === "mute")
                root.paintVolume(ctx, w, h);
            else if (root.icon === "battery")
                root.paintBattery(ctx, w, h);
            else if (root.icon === "wifi" || root.icon === "wifi-off")
                root.paintWifi(ctx, w, h);
            else if (root.icon === "ethernet")
                root.paintEthernet(ctx, w, h);
            else if (root.icon.indexOf("bluetooth") === 0)
                root.paintBluetooth(ctx, w, h);
            else if (root.icon === "power" || root.icon === "session")
                root.paintPower(ctx, w, h);
            else if (root.icon === "user")
                root.paintUser(ctx, w, h);
            else if (root.icon === "bell" || root.icon === "bell-off")
                root.paintBell(ctx, w, h);
            else if (root.icon === "play" || root.icon === "pause")
                root.paintTransport(ctx, w, h);
            else if (root.icon === "alarm")
                root.paintAlarm(ctx, w, h);
            else if (root.icon === "tray")
                root.paintTray(ctx, w, h);
        }
    }

    function paintVolume(ctx, w, h) {
        ctx.beginPath();
        ctx.moveTo(w * 0.10, h * 0.38);
        ctx.lineTo(w * 0.28, h * 0.38);
        ctx.lineTo(w * 0.46, h * 0.22);
        ctx.lineTo(w * 0.46, h * 0.78);
        ctx.lineTo(w * 0.28, h * 0.62);
        ctx.lineTo(w * 0.10, h * 0.62);
        ctx.closePath();
        ctx.fill();

        if (root.icon === "mute") {
            ctx.beginPath();
            ctx.moveTo(w * 0.58, h * 0.34);
            ctx.lineTo(w * 0.88, h * 0.66);
            ctx.moveTo(w * 0.88, h * 0.34);
            ctx.lineTo(w * 0.58, h * 0.66);
            ctx.stroke();
            return;
        }

        ctx.fillStyle = "transparent";
        if (root.level > 0.08) {
            ctx.beginPath();
            ctx.arc(w * 0.50, h * 0.50, w * 0.18, -0.7, 0.7);
            ctx.stroke();
        }
        if (root.level > 0.45) {
            ctx.beginPath();
            ctx.arc(w * 0.50, h * 0.50, w * 0.32, -0.75, 0.75);
            ctx.stroke();
        }
    }

    function paintBattery(ctx, w, h) {
        const x = w * 0.08;
        const y = h * 0.28;
        const bw = w * 0.70;
        const bh = h * 0.44;
        const r = Math.min(2.2, bh * 0.25);
        ctx.beginPath();
        ctx.rect(x, y, bw, bh);
        ctx.stroke();
        ctx.beginPath();
        ctx.rect(x + bw + w * 0.02, y + bh * 0.28, w * 0.08, bh * 0.44);
        ctx.fill();

        const pad = w * 0.06;
        const fillW = Math.max(0, (bw - pad * 2) * Math.max(0, Math.min(root.level, 1)));
        if (fillW > 0) {
            ctx.beginPath();
            ctx.rect(x + pad, y + pad, fillW, bh - pad * 2);
            ctx.fill();
        }

        if (root.charging) {
            ctx.globalCompositeOperation = "destination-out";
            ctx.beginPath();
            ctx.moveTo(w * 0.46, h * 0.22);
            ctx.lineTo(w * 0.34, h * 0.52);
            ctx.lineTo(w * 0.48, h * 0.52);
            ctx.lineTo(w * 0.38, h * 0.80);
            ctx.lineTo(w * 0.58, h * 0.46);
            ctx.lineTo(w * 0.44, h * 0.46);
            ctx.closePath();
            ctx.fill();
            ctx.globalCompositeOperation = "source-over";
            ctx.beginPath();
            ctx.moveTo(w * 0.46, h * 0.22);
            ctx.lineTo(w * 0.34, h * 0.52);
            ctx.lineTo(w * 0.48, h * 0.52);
            ctx.lineTo(w * 0.38, h * 0.80);
            ctx.lineTo(w * 0.58, h * 0.46);
            ctx.lineTo(w * 0.44, h * 0.46);
            ctx.closePath();
            ctx.fill();
        }
    }

    function paintWifi(ctx, w, h) {
        const cx = w * 0.50;
        const cy = h * 0.84;
        const isOff = root.icon === "wifi-off";

        const rings = isOff ? 0 : (root.level > 0.66 ? 3 : (root.level > 0.33 ? 2 : 1));

        // Dot at bottom
        ctx.fillStyle = isOff ? Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, 0.35) : root.stroke;
        ctx.beginPath();
        ctx.arc(cx, cy - w * 0.03, w * 0.08, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = "transparent";
        const startAngle = Math.PI * 1.25; // 225 deg
        const endAngle = Math.PI * 1.75;   // 315 deg

        const activeStroke = root.stroke;
        const inactiveStroke = Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, 0.25);

        // Ring 1 (inner wave)
        ctx.strokeStyle = (rings >= 1) ? activeStroke : inactiveStroke;
        ctx.beginPath();
        ctx.arc(cx, cy, w * 0.28, startAngle, endAngle);
        ctx.stroke();

        // Ring 2 (middle wave)
        ctx.strokeStyle = (rings >= 2) ? activeStroke : inactiveStroke;
        ctx.beginPath();
        ctx.arc(cx, cy, w * 0.44, startAngle, endAngle);
        ctx.stroke();

        // Ring 3 (outer wave)
        ctx.strokeStyle = (rings >= 3) ? activeStroke : inactiveStroke;
        ctx.beginPath();
        ctx.arc(cx, cy, w * 0.60, startAngle, endAngle);
        ctx.stroke();

        if (isOff) {
            ctx.strokeStyle = root.stroke;
            ctx.beginPath();
            ctx.moveTo(w * 0.20, h * 0.80);
            ctx.lineTo(w * 0.80, h * 0.20);
            ctx.stroke();
        }
    }

    function paintEthernet(ctx, w, h) {
        ctx.fillStyle = "transparent";
        ctx.beginPath();
        ctx.rect(w * 0.18, h * 0.18, w * 0.64, h * 0.42);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(w * 0.50, h * 0.60);
        ctx.lineTo(w * 0.50, h * 0.78);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(w * 0.34, h * 0.78);
        ctx.lineTo(w * 0.66, h * 0.78);
        ctx.stroke();
    }

    function paintBluetooth(ctx, w, h) {
        ctx.fillStyle = "transparent";
        const cx = w * 0.46;
        ctx.beginPath();
        ctx.moveTo(cx, h * 0.16);
        ctx.lineTo(cx, h * 0.84);
        ctx.moveTo(cx, h * 0.16);
        ctx.lineTo(w * 0.74, h * 0.34);
        ctx.lineTo(cx, h * 0.50);
        ctx.lineTo(w * 0.74, h * 0.66);
        ctx.lineTo(cx, h * 0.84);
        ctx.moveTo(w * 0.22, h * 0.34);
        ctx.lineTo(cx, h * 0.50);
        ctx.lineTo(w * 0.22, h * 0.66);
        ctx.stroke();
        if (root.icon === "bluetooth-off") {
            ctx.beginPath();
            ctx.moveTo(w * 0.18, h * 0.78);
            ctx.lineTo(w * 0.82, h * 0.22);
            ctx.stroke();
        }
    }

    function paintPower(ctx, w, h) {
        ctx.fillStyle = "transparent";
        ctx.beginPath();
        ctx.moveTo(w * 0.50, h * 0.14);
        ctx.lineTo(w * 0.50, h * 0.48);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(w * 0.50, h * 0.56, w * 0.30, -Math.PI * 0.28, Math.PI * 1.28, false);
        ctx.stroke();
    }

    function paintUser(ctx, w, h) {
        ctx.fillStyle = "transparent";
        ctx.beginPath();
        ctx.arc(w * 0.50, h * 0.32, w * 0.18, 0, Math.PI * 2);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(w * 0.50, h * 0.88, w * 0.36, Math.PI * 1.15, Math.PI * 1.85, false);
        ctx.stroke();
    }

    function paintBell(ctx, w, h) {
        ctx.fillStyle = "transparent";
        ctx.beginPath();
        ctx.moveTo(w * 0.28, h * 0.46);
        ctx.quadraticCurveTo(w * 0.28, h * 0.22, w * 0.50, h * 0.22);
        ctx.quadraticCurveTo(w * 0.72, h * 0.22, w * 0.72, h * 0.46);
        ctx.lineTo(w * 0.72, h * 0.62);
        ctx.lineTo(w * 0.80, h * 0.72);
        ctx.lineTo(w * 0.20, h * 0.72);
        ctx.lineTo(w * 0.28, h * 0.62);
        ctx.closePath();
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(w * 0.50, h * 0.78, w * 0.08, Math.PI, 0, true);
        ctx.stroke();
        if (root.icon === "bell-off") {
            ctx.beginPath();
            ctx.moveTo(w * 0.20, h * 0.78);
            ctx.lineTo(w * 0.80, h * 0.22);
            ctx.stroke();
        }
    }

    function paintTransport(ctx, w, h) {
        ctx.beginPath();
        if (root.icon === "pause") {
            ctx.rect(w * 0.28, h * 0.22, w * 0.14, h * 0.56);
            ctx.rect(w * 0.58, h * 0.22, w * 0.14, h * 0.56);
            ctx.fill();
        } else {
            ctx.moveTo(w * 0.30, h * 0.20);
            ctx.lineTo(w * 0.78, h * 0.50);
            ctx.lineTo(w * 0.30, h * 0.80);
            ctx.closePath();
            ctx.fill();
        }
    }

    function paintAlarm(ctx, w, h) {
        ctx.beginPath();
        ctx.arc(w * 0.50, h * 0.54, w * 0.30, 0, Math.PI * 2);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(w * 0.50, h * 0.54);
        ctx.lineTo(w * 0.50, h * 0.36);
        ctx.moveTo(w * 0.50, h * 0.54);
        ctx.lineTo(w * 0.68, h * 0.54);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(w * 0.28, h * 0.22, w * 0.10, Math.PI * 0.15, Math.PI * 1.05);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(w * 0.72, h * 0.22, w * 0.10, Math.PI * -0.05, Math.PI * 0.85);
        ctx.stroke();
    }

    function paintTray(ctx, w, h) {
        ctx.beginPath();
        ctx.moveTo(w * 0.16, h * 0.50);
        ctx.lineTo(w * 0.36, h * 0.50);
        ctx.lineTo(w * 0.42, h * 0.62);
        ctx.lineTo(w * 0.58, h * 0.62);
        ctx.lineTo(w * 0.64, h * 0.50);
        ctx.lineTo(w * 0.84, h * 0.50);
        ctx.lineTo(w * 0.78, h * 0.78);
        ctx.lineTo(w * 0.22, h * 0.78);
        ctx.closePath();
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(w * 0.50, h * 0.18);
        ctx.lineTo(w * 0.50, h * 0.44);
        ctx.moveTo(w * 0.38, h * 0.32);
        ctx.lineTo(w * 0.50, h * 0.44);
        ctx.lineTo(w * 0.62, h * 0.32);
        ctx.stroke();
    }
}
