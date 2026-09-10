pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../Commons"
import "../Ui"

Column {
    id: root

    width: parent ? parent.width : 460
    spacing: 8

    property int section: 0
    property var _cursorArr: [0, 0, 0]
    property bool dirty: false
    readonly property var sectionNames: ["Left", "Center", "Right"]

    // Picked-up chip: -1 = nothing picked, else section*1000 + index
    property int pickedKey: -1

    readonly property var sectionIds: {
        PluginRegistry.revision;
        return [
            PluginRegistry.orderedIds("left"),
            PluginRegistry.orderedIds("center"),
            PluginRegistry.orderedIds("right")
        ];
    }

    readonly property var sectionAvailable: {
        PluginRegistry.revision;
        return [
            PluginRegistry.availableBarIds("left"),
            PluginRegistry.availableBarIds("center"),
            PluginRegistry.availableBarIds("right")
        ];
    }

    function _count(s) { return sectionIds[s].length; }
    function _max(s) { return _count(s); }

    function _getCursor(s) { return _cursorArr[s] || 0; }
    function _setCursor(s, v) {
        const arr = _cursorArr.slice();
        arr[s] = Math.max(0, Math.min(_max(s), v));
        _cursorArr = arr;
    }

    function _keyFor(s, idx) { return s * 1000 + idx; }
    function _sectionOf(key) { return Math.floor(key / 1000); }
    function _indexOf(key) { return key - Math.floor(key / 1000) * 1000; }

    function _isPicked(s, idx) {
        return pickedKey === _keyFor(s, idx);
    }

    function _setPicked(s, idx) {
        pickedKey = (s < 0 || idx < 0) ? -1 : _keyFor(s, idx);
        if (s >= 0) section = s;
    }

    function _drop() {
        pickedKey = -1;
    }

    function nameFor(id) {
        const entry = PluginRegistry.widgetMeta(id);
        return entry ? (entry.label || id) : id;
    }

    function handleEscape() {
        if (pickedKey !== -1) {
            _drop();
            return true;
        }
        return false;
    }

    function nextSection(back) {
        if (back)
            section = section <= 0 ? 2 : section - 1;
        else
            section = section >= 2 ? 0 : section + 1;
        _setCursor(section, Math.min(_getCursor(section), _max(section)));
    }

    function focusItem(entry) {
        section = entry.section;
        _setCursor(entry.section, entry.index);
    }

    function _swapWithin(s, idx, dir) {
        const ids = sectionIds[s];
        const target = idx + dir;
        if (target < 0 || target >= ids.length)
            return false;
        PluginRegistry.moveWithinSection(["left","center","right"][s], idx, target);
        _setCursor(s, target);
        return true;
    }

    function _moveTo(s, idx, dstSec, dstIdx) {
        if (s === dstSec) {
            return (typeof dstIdx === "number") ? _swapWithin(s, idx, dstIdx - idx) : false;
        }
        const ids = sectionIds[s];
        if (!ids || idx < 0 || idx >= ids.length)
            return false;
        const id = ids[idx];
        const fromSec = ["left","center","right"][s];
        const toSec = ["left","center","right"][dstSec];
        const dstIds = sectionIds[dstSec];
        let insertAt = (typeof dstIdx === "number") ? dstIdx : (dstIds ? dstIds.length : 0);
        insertAt = Math.max(0, Math.min(dstIds ? dstIds.length : 0, insertAt));
        PluginRegistry.moveToSection(id, fromSec, toSec, insertAt);
        dirty = true;
        return true;
    }

    function _addFromAvailable(s) {
        const sections = ["left","center","right"];
        const ids = sectionIds[s];
        const avail = sectionAvailable[s];
        if (!avail.length)
            return false;
        const next = avail[0];
        const srcSec = sections[Math.max(0, PluginRegistry.sectionIndexOf(next))] || sections[s];
        PluginRegistry.moveToSection(next, srcSec, sections[s], ids.length);
        _setCursor(s, ids.length);
        return true;
    }

    function _toggleRemove(s) {
        const ids = sectionIds[s];
        const idx = _getCursor(s);
        if (idx >= ids.length)
            return;
        const id = ids[idx];
        const sec = ["left","center","right"][s];
        PluginRegistry._mutateLayout(function(next) {
            const arr2 = next[sec].slice();
            const j = arr2.indexOf(id);
            if (j >= 0)
                arr2.splice(j, 1);
            next[sec] = arr2;
        });
        PluginRegistry.togglePlugin(id, false);
    }

    readonly property var searchEntries: {
        const e = [];
        for (let s = 0; s < 3; s++) {
            const ids = sectionIds[s];
            for (let i = 0; i < ids.length; i++)
                e.push({ "label": root.nameFor(ids[i]), "index": i, "section": s });
            const avail = sectionAvailable[s];
            if (avail.length)
                e.push({ "label": "add " + root.nameFor(avail[0]), "index": ids.length, "section": s });
        }
        return e;
    }

    function handleKey(event) {
        const s = section;
        const cur = _getCursor(s);
        const count = _count(s);
        const onAddRow = cur === count;

        // Shift keypress toggles pick
        if (event.key === Qt.Key_Shift) {
            if (!onAddRow) {
                if (pickedKey === _keyFor(s, cur))
                    _drop();
                else
                    _setPicked(s, cur);
                dirty = true;
            }
            return true;
        }

        const jump = KeyNav.jump(event, count + 1);
        if (jump >= 0) {
            _setCursor(s, jump);
            return true;
        }

        if (KeyNav.isNext(event) || KeyNav.isDown(event)) {
            if (pickedKey !== -1) {
                const ps = _sectionOf(pickedKey);
                const pi = _indexOf(pickedKey);
                if (ps === s) {
                    if (_swapWithin(s, pi, +1)) {
                        pickedKey = _keyFor(s, pi + 1);
                        dirty = true;
                    }
                    return true;
                }
                if (cur < count) {
                    if (_moveTo(ps, pi, s, cur + 1)) {
                        _setCursor(s, cur + 1);
                        pickedKey = _keyFor(s, cur + 1);
                        dirty = true;
                    }
                    return true;
                }
                return true;
            }
            _setCursor(s, Math.min(count, cur + 1));
            return true;
        }

        if (KeyNav.isPrev(event) || KeyNav.isUp(event)) {
            if (pickedKey !== -1) {
                const ps = _sectionOf(pickedKey);
                const pi = _indexOf(pickedKey);
                if (ps === s) {
                    if (_swapWithin(s, pi, -1)) {
                        pickedKey = _keyFor(s, pi - 1);
                        dirty = true;
                    }
                    return true;
                }
                if (cur > 0) {
                    if (_moveTo(ps, pi, s, cur - 1)) {
                        _setCursor(s, cur - 1);
                        pickedKey = _keyFor(s, cur - 1);
                        dirty = true;
                    }
                    return true;
                }
                return true;
            }
            _setCursor(s, Math.max(0, cur - 1));
            return true;
        }

        if (KeyNav.isRight(event)) {
            if (pickedKey !== -1) {
                const ps = _sectionOf(pickedKey);
                const pi = _indexOf(pickedKey);
                if (ps < 2) {
                    const targetSec = ps + 1;
                    const targetIdx = Math.min(pi, _count(targetSec));
                    if (_moveTo(ps, pi, targetSec, targetIdx)) {
                        section = targetSec;
                        _setCursor(targetSec, targetIdx);
                        pickedKey = _keyFor(targetSec, targetIdx);
                        dirty = true;
                    }
                    return true;
                }
                return true;
            }
            if (s < 2) {
                section = s + 1;
                _setCursor(section, Math.min(_getCursor(section), _max(section)));
                return true;
            }
            return true;
        }

        if (KeyNav.isLeft(event)) {
            if (pickedKey !== -1) {
                const ps = _sectionOf(pickedKey);
                const pi = _indexOf(pickedKey);
                if (ps > 0) {
                    const targetSec = ps - 1;
                    const targetIdx = Math.min(pi, _count(targetSec));
                    if (_moveTo(ps, pi, targetSec, targetIdx)) {
                        section = targetSec;
                        _setCursor(targetSec, targetIdx);
                        pickedKey = _keyFor(targetSec, targetIdx);
                        dirty = true;
                    }
                    return true;
                }
                return true;
            }
            if (s > 0) {
                section = s - 1;
                _setCursor(section, Math.min(_getCursor(section), _max(section)));
                return true;
            }
            return true;
        }

        if (KeyNav.isActivate(event)) {
            if (onAddRow) {
                _addFromAvailable(s);
                return true;
            }
            if (pickedKey !== -1) {
                _drop();
                dirty = true;
                return true;
            }
            if (!onAddRow && cur < count) {
                _setPicked(s, cur);
                dirty = true;
                return true;
            }
            _toggleRemove(s);
            return true;
        }
        return false;
    }

    onVisibleChanged: {
        if (visible) {
            section = 0;
            _cursorArr = [0, 0, 0];
            _drop();
        }
    }

    Rectangle {
        width: parent.width
        height: 22
        color: "transparent"

        Text {
            id: helpText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: Color.popupMuted
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            font.bold: true
            elide: Text.ElideRight
            text: {
                const help = "↑/↓ nav  ←/→ column  Shift pick  Enter toggle  Tab switch";
                if (root.pickedKey !== -1)
                    return root.sectionNames[root._sectionOf(root.pickedKey)] + " • picked: " + root.nameFor(root.sectionIds[root._sectionOf(root.pickedKey)][root._indexOf(root.pickedKey)]);
                return help;
            }
            readonly property string fullText: "↑ / ↓ — navigate within column\n" +
                "← / → — move cursor to other column\n" +
                "Shift — pick up / put down the chip under the cursor\n" +
                "After picking, ↑ / ↓ reorders within the column; ← / → moves to the adjacent column at the cursor's row\n" +
                "Enter — put down if picked, otherwise toggle on / off\n" +
                "Tab — switch column (same as →)\n" +
                "Escape — cancel pick"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onContainsMouseChanged: {
                    if (containsMouse)
                        HoverTip.show(parent, helpText.fullText);
                    else
                        HoverTip.hide();
                }
            }
        }
    }

    Row {
        width: parent.width
        spacing: 8

        Repeater {
            model: 3

            Column {
                id: sectionCol
                required property int modelData
                readonly property int secIndex: modelData

                width: (parent.width - 16) / 3
                spacing: 4

                Rectangle {
                    width: parent.width
                    height: 24
                    color: "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.section === sectionCol.secIndex ? Color.accent : Color.popupMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        font.bold: true
                        text: root.sectionNames[sectionCol.secIndex]
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.pickedKey !== -1) {
                                const ps = root._sectionOf(root.pickedKey);
                                const pi = root._indexOf(root.pickedKey);
                                if (ps !== sectionCol.secIndex) {
                                    const targetIdx = root._count(sectionCol.secIndex);
                                    root._moveTo(ps, pi, sectionCol.secIndex, targetIdx);
                                    root.section = sectionCol.secIndex;
                                    root._setCursor(sectionCol.secIndex, targetIdx);
                                    root.pickedKey = root._keyFor(sectionCol.secIndex, targetIdx);
                                    root.dirty = true;
                                    return;
                                }
                            }
                            root.section = sectionCol.secIndex;
                            root._setCursor(sectionCol.secIndex, Math.min(root._getCursor(sectionCol.secIndex), root._max(sectionCol.secIndex)));
                        }
                    }
                }

                Rectangle {
                    visible: root.section === sectionCol.secIndex
                    width: parent.width
                    height: 2
                    color: Color.accent
                }

                Repeater {
                    model: root.sectionIds[sectionCol.secIndex]

                    Rectangle {
                        id: chipRect
                        required property var modelData
                        required property int index
                        readonly property string widgetId: String(modelData)
                        readonly property int chipIndex: index
                        readonly property int chipSec: sectionCol.secIndex

                        width: parent.width
                        height: 28
                        radius: Style.radius
                        color: {
                            if (root._isPicked(chipSec, chipIndex))
                                return Color.accent;
                            if (chipMouse.containsMouse || (root.section === chipSec && root._cursorArr[chipSec] === chipIndex))
                                return Color.focusFill;
                            return Color.surface;
                        }
                        border.width: 1
                        border.color: root._isPicked(chipSec, chipIndex) || (root.section === chipSec && root._cursorArr[chipSec] === chipIndex) ? Color.accent : "transparent"
                        Behavior on color { ColorAnimation { duration: Style.animDuration } }
                        Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

                        Rectangle {
                            width: 3
                            height: parent.height - 10
                            radius: 1.5
                            color: root._isPicked(chipSec, chipIndex) ? Color.background : Color.accent
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root._isPicked(chipSec, chipIndex) || (root.section === chipSec && root._cursorArr[chipSec] === chipIndex)
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 4

                            Rectangle {
                                visible: chipRect.chipSec > 0
                                width: 18
                                height: 18
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 3
                                color: leftBtnMouse.containsMouse ? Color.focusFill : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "◀"
                                    font.pixelSize: 10
                                    color: root._isPicked(chipRect.chipSec, chipRect.chipIndex) ? Color.background : Color.accent
                                }

                                MouseArea {
                                    id: leftBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root._moveTo(chipRect.chipSec, chipRect.chipIndex, chipRect.chipSec - 1, undefined);
                                        root.section = chipRect.chipSec - 1;
                                        root._setCursor(chipRect.chipSec - 1, root._count(chipRect.chipSec - 1) - 1);
                                        if (root.pickedKey !== -1)
                                            root._drop();
                                        root.dirty = true;
                                    }
                                }
                            }

                            Text {
                                width: parent.width - (chipRect.chipSec > 0 ? 22 : 0) - (chipRect.chipSec < 2 ? 22 : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                color: root._isPicked(chipRect.chipSec, chipRect.chipIndex) ? Color.background : Color.popupText
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontCaption
                                font.bold: root._isPicked(chipRect.chipSec, chipRect.chipIndex)
                                text: root.nameFor(chipRect.widgetId)
                            }

                            Rectangle {
                                visible: chipRect.chipSec < 2
                                width: 18
                                height: 18
                                anchors.verticalCenter: parent.verticalCenter
                                radius: 3
                                color: rightBtnMouse.containsMouse ? Color.focusFill : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "▶"
                                    font.pixelSize: 10
                                    color: root._isPicked(chipRect.chipSec, chipRect.chipIndex) ? Color.background : Color.accent
                                }

                                MouseArea {
                                    id: rightBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root._moveTo(chipRect.chipSec, chipRect.chipIndex, chipRect.chipSec + 1, undefined);
                                        root.section = chipRect.chipSec + 1;
                                        root._setCursor(chipRect.chipSec + 1, root._count(chipRect.chipSec + 1) - 1);
                                        if (root.pickedKey !== -1)
                                            root._drop();
                                        root.dirty = true;
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: chipMouse
                            z: -1
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                if (root.pickedKey !== -1) {
                                    const ps = root._sectionOf(root.pickedKey);
                                    const pi = root._indexOf(root.pickedKey);
                                    if (ps !== chipRect.chipSec) {
                                        root._moveTo(ps, pi, chipRect.chipSec, chipRect.chipIndex);
                                        root.section = chipRect.chipSec;
                                        root._setCursor(chipRect.chipSec, chipRect.chipIndex);
                                        root.pickedKey = root._keyFor(chipRect.chipSec, chipRect.chipIndex);
                                        root.dirty = true;
                                        return;
                                    }
                                }
                                if (root.pickedKey === root._keyFor(chipRect.chipSec, chipRect.chipIndex)) {
                                    root._drop();
                                } else {
                                    root.section = chipRect.chipSec;
                                    root._setCursor(chipRect.chipSec, chipRect.chipIndex);
                                    root._setPicked(chipRect.chipSec, chipRect.chipIndex);
                                }
                                root.dirty = true;
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    visible: root.sectionAvailable[sectionCol.secIndex].length > 0
                    height: 26
                    radius: Style.radius
                    color: availMouse.containsMouse ? Color.focusFill : ((root.section === sectionCol.secIndex && root._cursorArr[sectionCol.secIndex] === root.sectionIds[sectionCol.secIndex].length) ? Color.focusFill : "transparent")
                    border.width: 1
                    border.color: (root.section === sectionCol.secIndex && root._cursorArr[sectionCol.secIndex] === root.sectionIds[sectionCol.secIndex].length) ? Color.accent : Color.subtleBorder
                    Behavior on color { ColorAnimation { duration: Style.animDuration } }
                    Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        color: Color.popupMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: "+ " + root.sectionAvailable[sectionCol.secIndex].length + " available"
                    }

                    MouseArea {
                        id: availMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.section = sectionCol.secIndex;
                            root._addFromAvailable(sectionCol.secIndex);
                            root.dirty = true;
                        }
                    }
                }
            }
        }
    }
}
