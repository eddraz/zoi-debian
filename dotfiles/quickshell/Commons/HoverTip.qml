pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string text: ""
    property real centerX: 0
    property var screen: null
    property string pending: ""
    property real pendingX: 0
    property var pendingScreen: null

    function show(item, message) {
        const point = item.mapToItem(null, item.width / 2, 0);
        const win = item.QsWindow.window;
        pending = message;
        pendingX = point.x;
        pendingScreen = win ? win.screen : null;
        hideNow();
        showTimer.restart();
    }

    function update(item, message) {
        const point = item.mapToItem(null, item.width / 2, 0);
        if (text !== "") {
            text = message;
            centerX = point.x;
            return;
        }
        if (showTimer.running) {
            pending = message;
            pendingX = point.x;
        }
    }

    function hide() {
        showTimer.stop();
        pending = "";
        hideNow();
    }

    function hideNow() {
        text = "";
        screen = null;
    }

    Timer {
        id: showTimer
        interval: 350
        onTriggered: {
            root.text = root.pending;
            root.centerX = root.pendingX;
            root.screen = root.pendingScreen;
        }
    }
}
