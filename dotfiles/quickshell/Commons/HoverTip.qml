pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property string text: ""
    property string shortcut: ""
    property real centerX: 0
    property var screen: null
    property string pending: ""
    property string pendingShortcut: ""
    property real pendingX: 0
    property var pendingScreen: null

    function show(item, message, shortcut) {
        if (!item || !item.mapToItem)
            return;
        const point = item.mapToItem(null, item.width / 2, 0);
        const win = item.QsWindow ? item.QsWindow.window : null;
        pending = message || "";
        pendingShortcut = shortcut || "";
        pendingX = point.x;
        pendingScreen = win ? win.screen : null;
        hideNow();
        showTimer.restart();
    }

    function update(item, message, shortcut) {
        if (!item || !item.mapToItem)
            return;
        const point = item.mapToItem(null, item.width / 2, 0);
        if (text !== "") {
            text = message || "";
            if (shortcut !== undefined)
                root.shortcut = shortcut || "";
            centerX = point.x;
            return;
        }
        if (showTimer.running) {
            pending = message || "";
            if (shortcut !== undefined)
                pendingShortcut = shortcut || "";
            pendingX = point.x;
        }
    }

    function hide() {
        showTimer.stop();
        pending = "";
        pendingShortcut = "";
        hideNow();
    }

    function hideNow() {
        text = "";
        shortcut = "";
        screen = null;
    }

    Timer {
        id: showTimer
        interval: 350
        onTriggered: {
            root.text = root.pending;
            root.shortcut = root.pendingShortcut;
            root.centerX = root.pendingX;
            root.screen = root.pendingScreen;
        }
    }
}
