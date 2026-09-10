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
        const ids = sectionIds[s];
        if (idx < 0 || idx >= ids.length)
            return false;
        const id = ids[idx];
        const fromSec = ["left","center","right"][s];
        const toSec = ["left","center","right"][dstSec];
        const dstIds = sectionIds[dstSec];
        let insertAt = (typeof dstIdx === "number") ? dstIdx : dstIds.length;
        insertAt = Math.max(0, Math.min(dstIds.length, insertAt));
        PluginRegistry.moveToSection(id, fromSec, toSec, insertAt);
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
        const shift = event.modifiers & Qt.ShiftModifier;

        // Shift alone: toggle pick on current chip
        if (shift && (KeyNav.isLeft(event) || KeyNav.isRight(event) || KeyNav.isUp(event) || KeyNav.isDown(event) || event.key === Qt.Key_Shift)) {
            if (!onAddRow) {
                if (pickedKey === _keyFor(s, cur))
                    _drop();
                else
                    _setPicked(s, cur);
                dirty = true;
                return true;
            }
        }

        // Pure shift keypress (no arrow) just toggles pick
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
                // move picked down within current column at cur position
                if (cur < count) {
                    if (_moveTo(ps, pi, s, cur + 1)) {
                        _setCursor(s, cur + 1);
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
                if (s < 2) {
                    if (_moveTo(ps, pi, s + 1, Math.min(pi, _count(s + 1)))) {
                        _setCursor(s + 1, Math.min(pi, _count(s + 1)));
                        section = s + 1;
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
                if (s > 0) {
                    if (_moveTo(ps, pi, s - 1, Math.min(pi, _count(s - 1)))) {
                        _setCursor(s - 1, Math.min(pi, _count(s - 1)));
                        section = s - 1;
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

    Connections {
        target: PluginRegistry
        function onRevisionChanged() { root.dirty = true; }
    }

    Rectangle {
        width: parent.width
        height: 22
        color: "transparent"

        Text {
            id: helpText
            anchors.left: parent.left
            anchors.right: saveBtn.left
            anchors.rightMargin: 8
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

        Rectangle {
            id: saveBtn
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: saveRow.implicitWidth + 18
            height: 22
            radius: Style.radius
            color: root.dirty ? Color.accent : Color.surface

            Text {
                id: saveRow
                anchors.centerIn: parent
                text: root.dirty ? "Save" : "Saved"
                color: root.dirty ? Color.background : Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                font.bold: true
            }

            HoverMouse {
                onClicked: {
                    PluginRegistry.writeShell();
                    root.dirty = false;
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
                required property int modelData
                width: (parent.width - 16) / 3
                spacing: 4

                Text {
                    color: root.section === modelData ? Color.accent : Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    font.bold: true
                    text: root.sectionNames[modelData]

                    HoverMouse {
                        z: -1
                        anchors.fill: parent
                        onClicked: {
                            root.section = modelData;
                            root._setCursor(modelData, Math.min(root._getCursor(modelData), root._max(modelData)));
                            if (root.pickedKey !== -1)
                                root._drop();
                        }
                    }
                }

                Rectangle {
                    visible: root.section === modelData
                    width: parent.width
                    height: 2
                    color: Color.accent
                }

                Repeater {
                    model: root.sectionIds[modelData]

                    Rectangle {
                        id: chipRect
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 24
                        radius: Style.radius
                        color: root._isPicked(modelData, index) ? Color.accent
                              : (root.section === modelData && root._cursorArr[modelData] === index) ? Color.focusFill
                              : Color.surface
                        border.width: (root.section === modelData && root._cursorArr[modelData] === index) ? 2 : 0
                        border.color: Color.accent

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            color: root._isPicked(parent.modelData, parent.index) ? Color.background : Color.popupText
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontCaption
                            elide: Text.ElideRight
                            text: root.nameFor(parent.modelData)
                        }

                        MouseArea {
                            id: chipHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton
                            onEntered: {
                                chipRect.color = Color.focusFill;
                            }
                            onExited: {
                                chipRect.color = Qt.binding(function() {
                                    return root._isPicked(chipRect.modelData, chipRect.index) ? Color.accent
                                           : (root.section === chipRect.modelData && root._cursorArr[chipRect.modelData] === chipRect.index) ? Color.focusFill
                                           : Color.surface;
                                });
                            }
                            onClicked: {
                                root.section = chipRect.modelData;
                                root._setCursor(chipRect.modelData, chipRect.index);
                                if (root.pickedKey !== -1)
                                    root._drop();
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    visible: root.sectionAvailable[modelData].length > 0
                    height: 22
                    radius: Style.radius
                    color: (root.section === modelData && root._cursorArr[modelData] === root.sectionIds[modelData].length) ? Color.focusFill : "transparent"
                    border.width: 1
                    border.color: Color.overlay

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        color: Color.popupMuted
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        text: "+ " + root.sectionAvailable[modelData].length + " available"
                    }
                }
            }
        }
    }
}
