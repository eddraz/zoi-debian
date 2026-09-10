pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Singleton {
    function isNext(event) {
        return event.key === Qt.Key_J || event.key === Qt.Key_Down;
    }

    function isPrev(event) {
        return event.key === Qt.Key_K || event.key === Qt.Key_Up;
    }

    function isUp(event) {
        return event.key === Qt.Key_Up || event.key === Qt.Key_K;
    }

    function isDown(event) {
        return event.key === Qt.Key_Down || event.key === Qt.Key_J;
    }

    function isRight(event) {
        return event.key === Qt.Key_L || event.key === Qt.Key_Right;
    }

    function isLeft(event) {
        return event.key === Qt.Key_H || event.key === Qt.Key_Left;
    }

    function isActivate(event) {
        return event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space;
    }

    function digitIndex(event) {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return -1;
        const ch = String(event.text || "");
        if (ch >= "1" && ch <= "9")
            return parseInt(ch, 10) - 1;
        if (ch === "0")
            return 9;
        if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9)
            return event.key - Qt.Key_1;
        if (event.key === Qt.Key_0)
            return 9;
        return -1;
    }

    function jump(event, count) {
        const index = digitIndex(event);
        if (index < 0 || index >= count)
            return -1;
        return index;
    }

    function nextStart(starts, current, back) {
        if (!starts || starts.length === 0)
            return current;
        let i = 0;
        for (let s = 0; s < starts.length; s++) {
            if (starts[s] <= current)
                i = s;
        }
        if (back)
            i = i <= 0 ? starts.length - 1 : i - 1;
        else
            i = i >= starts.length - 1 ? 0 : i + 1;
        return starts[i];
    }
}
