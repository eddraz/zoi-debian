pragma ComponentBehavior: Bound

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
            else if (root.icon === "apps" || root.icon === "grid")
                root.paintApps(ctx, w, h);
            else if (root.icon === "keyboard" || root.icon === "key")
                root.paintKeyboard(ctx, w, h);
            else if (root.icon === "trash" || root.icon === "delete")
                root.paintTrash(ctx, w, h);
            else if (root.icon === "search")
                root.paintSearch(ctx, w, h);
            else if (root.icon === "qr" || root.icon === "qrcode")
                root.paintQr(ctx, w, h);
            else if (root.icon === "clipboard")
                root.paintClipboard(ctx, w, h);
            else if (root.icon === "chev-left" || root.icon === "chev-right"
                     || root.icon === "chev-double-left" || root.icon === "chev-double-right")
                root.paintChevron(ctx, w, h);
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
        const r = Math.min(2.5, bh * 0.25);
        ctx.beginPath();
        if (ctx.roundRect)
            ctx.roundRect(x, y, bw, bh, r);
        else
            ctx.rect(x, y, bw, bh);
        ctx.stroke();

        ctx.beginPath();
        if (ctx.roundRect)
            ctx.roundRect(x + bw + w * 0.02, y + bh * 0.28, w * 0.08, bh * 0.44, 1.5);
        else
            ctx.rect(x + bw + w * 0.02, y + bh * 0.28, w * 0.08, bh * 0.44);
        ctx.fill();

        const pad = w * 0.06;
        const fillW = Math.max(0, (bw - pad * 2) * Math.max(0, Math.min(root.level, 1)));
        if (fillW > 0) {
            ctx.beginPath();
            if (ctx.roundRect)
                ctx.roundRect(x + pad, y + pad, fillW, bh - pad * 2, Math.max(1, r - 1));
            else
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
        ctx.moveTo(w * 0.50, h * 0.16);
        ctx.lineTo(w * 0.50, h * 0.48);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(w * 0.50, h * 0.56, w * 0.28, -Math.PI * 0.25, -Math.PI * 0.75, false);
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

    function paintApps(ctx, w, h) {
        const size = w * 0.28;
        const gap = w * 0.16;
        const x1 = (w - (size * 2 + gap)) / 2;
        const x2 = x1 + size + gap;
        const y1 = (h - (size * 2 + gap)) / 2;
        const y2 = y1 + size + gap;
        const r = 2;

        const drawBox = (x, y) => {
            ctx.beginPath();
            if (ctx.roundRect)
                ctx.roundRect(x, y, size, size, r);
            else
                ctx.rect(x, y, size, size);
            ctx.stroke();
        };

        drawBox(x1, y1);
        drawBox(x2, y1);
        drawBox(x1, y2);
        drawBox(x2, y2);
    }

    function paintKeyboard(ctx, w, h) {
        const x = w * 0.08;
        const y = h * 0.20;
        const kw = w * 0.84;
        const kh = h * 0.60;
        const r = 2.2;

        ctx.beginPath();
        if (ctx.roundRect)
            ctx.roundRect(x, y, kw, kh, r);
        else
            ctx.rect(x, y, kw, kh);
        ctx.stroke();

        const dotR = Math.max(0.9, w * 0.055);
        const yRow1 = y + kh * 0.30;
        const yRow2 = y + kh * 0.55;
        const yRow3 = y + kh * 0.80;

        ctx.beginPath();
        ctx.arc(x + kw * 0.24, yRow1, dotR, 0, Math.PI * 2);
        ctx.arc(x + kw * 0.50, yRow1, dotR, 0, Math.PI * 2);
        ctx.arc(x + kw * 0.76, yRow1, dotR, 0, Math.PI * 2);
        ctx.fill();

        ctx.beginPath();
        ctx.arc(x + kw * 0.24, yRow2, dotR, 0, Math.PI * 2);
        ctx.arc(x + kw * 0.50, yRow2, dotR, 0, Math.PI * 2);
        ctx.arc(x + kw * 0.76, yRow2, dotR, 0, Math.PI * 2);
        ctx.fill();

        ctx.beginPath();
        ctx.moveTo(x + kw * 0.28, yRow3);
        ctx.lineTo(x + kw * 0.72, yRow3);
        ctx.stroke();
    }

    function paintTrash(ctx, w, h) {
        ctx.fillStyle = "transparent";
        ctx.beginPath();
        ctx.moveTo(w * 0.18, h * 0.28);
        ctx.lineTo(w * 0.82, h * 0.28);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(w * 0.36, h * 0.28);
        ctx.lineTo(w * 0.36, h * 0.16);
        ctx.lineTo(w * 0.64, h * 0.16);
        ctx.lineTo(w * 0.64, h * 0.28);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(w * 0.26, h * 0.28);
        ctx.lineTo(w * 0.30, h * 0.80);
        ctx.quadraticCurveTo(w * 0.31, h * 0.86, w * 0.38, h * 0.86);
        ctx.lineTo(w * 0.62, h * 0.86);
        ctx.quadraticCurveTo(w * 0.69, h * 0.86, w * 0.70, h * 0.80);
        ctx.lineTo(w * 0.74, h * 0.28);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(w * 0.42, h * 0.40);
        ctx.lineTo(w * 0.42, h * 0.72);
        ctx.moveTo(w * 0.58, h * 0.40);
        ctx.lineTo(w * 0.58, h * 0.72);
        ctx.stroke();
    }

    function paintSearch(ctx, w, h) {
        ctx.fillStyle = "transparent";
        const r = w * 0.25;
        const cx = w * 0.42;
        const cy = h * 0.42;
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(cx + r * 0.707, cy + r * 0.707);
        ctx.lineTo(w * 0.82, h * 0.82);
        ctx.stroke();
    }

    function paintChevron(ctx, w, h) {
        ctx.fillStyle = "transparent";
        const cy = h * 0.50;
        const single = root.icon === "chev-left" || root.icon === "chev-right";
        const left = root.icon === "chev-left" || root.icon === "chev-double-left";
        const drawOne = off => {
            const tipX = left ? w * (0.32 + off) : w * (0.68 - off);
            const baseX = left ? w * (0.62 + off) : w * (0.38 - off);
            ctx.beginPath();
            ctx.moveTo(baseX, h * 0.26);
            ctx.lineTo(tipX, cy);
            ctx.lineTo(baseX, h * 0.74);
            ctx.stroke();
        };
        drawOne(0);
        if (!single)
            drawOne(left ? 0.22 : 0.22);
    }

    function paintClipboard(ctx, w, h) {
        ctx.fillStyle = "transparent";
        ctx.beginPath();
        if (ctx.roundRect)
            ctx.roundRect(w * 0.20, h * 0.22, w * 0.60, h * 0.68, 2.5);
        else
            ctx.rect(w * 0.20, h * 0.22, w * 0.60, h * 0.68);
        ctx.stroke();

        ctx.beginPath();
        if (ctx.roundRect)
            ctx.roundRect(w * 0.34, h * 0.12, w * 0.32, h * 0.18, 1.5);
        else
            ctx.rect(w * 0.34, h * 0.12, w * 0.32, h * 0.18);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(w * 0.34, h * 0.46);
        ctx.lineTo(w * 0.66, h * 0.46);
        ctx.moveTo(w * 0.34, h * 0.60);
        ctx.lineTo(w * 0.66, h * 0.60);
        ctx.moveTo(w * 0.34, h * 0.74);
        ctx.lineTo(w * 0.54, h * 0.74);
        ctx.stroke();
    }

    function paintQr(ctx, w, h) {
        ctx.fillStyle = root.stroke;
        ctx.strokeStyle = root.stroke;
        ctx.lineWidth = Math.max(1.0, w * 0.08);

        const s = w * 0.34;
        const pad = w * 0.12;
        const rightX = w - pad - s;
        const botY = h - pad - s;

        const drawFinder = (x, y) => {
            ctx.strokeRect(x, y, s, s);
            const innerPad = s * 0.28;
            ctx.fillRect(x + innerPad, y + innerPad, s - innerPad * 2, s - innerPad * 2);
        };

        // Top-Left Finder Pattern
        drawFinder(pad, pad);
        // Top-Right Finder Pattern
        drawFinder(rightX, pad);
        // Bottom-Left Finder Pattern
        drawFinder(pad, botY);

        // Bottom-Right modules / dots
        const modSize = s * 0.36;
        ctx.fillRect(rightX, botY, modSize, modSize);
        ctx.fillRect(rightX + s - modSize, botY, modSize, modSize);
        ctx.fillRect(rightX, botY + s - modSize, modSize, modSize);
        ctx.fillRect(rightX + s - modSize, botY + s - modSize, modSize, modSize);
    }
}
