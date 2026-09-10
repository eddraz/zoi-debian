pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root

    width: parent ? parent.width : 388
    spacing: 8

    property int cursor: 0
    readonly property int columns: 2
    readonly property int count: Wallpaper.images.length

    onVisibleChanged: {
        if (visible) {
            Wallpaper.refresh();
            cursor = 0;
            for (let i = 0; i < Wallpaper.images.length; i++) {
                if (Wallpaper.images[i] === Wallpaper.current) {
                    cursor = i;
                    break;
                }
            }
        }
    }

    function nameFor(path) {
        const parts = String(path || "").split("/");
        return parts.length ? parts[parts.length - 1] : path;
    }

    function nextSection(back) {}

    function focusItem(entry) {
        cursor = entry.index;
    }

    readonly property var searchEntries: {
        const e = [];
        for (let i = 0; i < Wallpaper.images.length; i++) {
            const parts = String(Wallpaper.images[i] || "").split("/");
            e.push({ "label": parts.length ? parts[parts.length - 1] : "wallpaper", "index": i });
        }
        return e;
    }

    function handleKey(event) {
        if (count === 0)
            return false;
        const jump = KeyNav.jump(event, count);
        if (jump >= 0) {
            cursor = jump;
            return true;
        }
        if (KeyNav.isLeft(event)) {
            cursor = Math.max(0, cursor - 1);
            return true;
        }
        if (KeyNav.isRight(event)) {
            cursor = Math.min(count - 1, cursor + 1);
            return true;
        }
        if (KeyNav.isNext(event)) {
            cursor = Math.min(count - 1, cursor + columns);
            return true;
        }
        if (KeyNav.isPrev(event)) {
            cursor = Math.max(0, cursor - columns);
            return true;
        }
        if (KeyNav.isActivate(event)) {
            Wallpaper.apply(Wallpaper.images[cursor]);
            return true;
        }
        return false;
    }

    Text {
        visible: root.count === 0
        width: parent.width
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        wrapMode: Text.Wrap
        text: "Put jpg/png files in ~/Imágenes"
    }

    Grid {
        width: parent.width
        columns: root.columns
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            model: Wallpaper.images

            Rectangle {
                required property var modelData
                required property int index
                readonly property bool selected: root.cursor === index
                readonly property bool current: Wallpaper.current === modelData

                width: (root.width - 8) / 2
                height: 108
                radius: Style.radius
                color: selected ? Color.focusFill : Color.surface
                border.width: selected || current ? 2 : 1
                border.color: selected ? Color.accent : (current ? Color.green : Color.subtleBorder)
                Behavior on color { ColorAnimation { duration: Style.animDuration } }
                Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

                IndexBadge {
                    z: 1
                    slot: index
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 6
                }

                Image {
                    anchors.fill: parent
                    anchors.margins: 3
                    anchors.bottomMargin: 22
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 180
                    sourceSize.height: 90
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 4
                    elide: Text.ElideMiddle
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: current ? "Current" : root.nameFor(modelData)
                }

                HoverMouse {
                    onClicked: {
                        root.cursor = index;
                        Wallpaper.apply(modelData);
                    }
                }
            }
        }
    }
}
