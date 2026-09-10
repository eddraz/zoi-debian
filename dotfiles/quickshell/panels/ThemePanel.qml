pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"
import "../Ui"

Column {
    id: root

    width: parent ? parent.width : 388
    spacing: 10
    property int cursor: 0
    property int wallCursor: 0
    property int section: 0

    readonly property int themeCount: Themes.palettes.length
    readonly property int wallCount: Wallpaper.images.length

    onVisibleChanged: {
        if (visible) {
            Wallpaper.refresh();
            cursor = 0;
            for (let i = 0; i < Themes.palettes.length; i++) {
                if (Themes.palettes[i].id === Themes.currentId) {
                    cursor = i;
                    break;
                }
            }
            wallCursor = 0;
            for (let i = 0; i < Wallpaper.images.length; i++) {
                if (Wallpaper.images[i] === Wallpaper.current) {
                    wallCursor = i;
                    break;
                }
            }
            section = 0;
        }
    }

    function nameFor(path) {
        const parts = String(path || "").split("/");
        return parts.length ? parts[parts.length - 1] : path;
    }

    function handleEscape() {
        if (editor.activeFocus) {
            editor.focus = false;
            return true;
        }
        return false;
    }

    function nextSection(back) {
        const max = 2;
        if (back)
            section = section <= 0 ? max : section - 1;
        else
            section = section >= max ? 0 : section + 1;
        if (section === 2)
            Qt.callLater(() => editor.forceActiveFocus());
        else
            editor.focus = false;
    }

    function focusItem(entry) {
        section = entry.section;
        if (section === 0)
            cursor = entry.index;
        else if (section === 1)
            wallCursor = entry.index;
        else
            Qt.callLater(() => editor.forceActiveFocus());
    }

    readonly property var searchEntries: {
        const e = [];
        for (let i = 0; i < Themes.palettes.length; i++)
            e.push({ "label": String(Themes.palettes[i].name), "index": i, "section": 0 });
        for (let i = 0; i < Wallpaper.images.length; i++) {
            const parts = String(Wallpaper.images[i] || "").split("/");
            e.push({ "label": parts.length ? parts[parts.length - 1] : "wallpaper", "index": i, "section": 1 });
        }
        e.push({ "label": "screensaver text zoi", "index": 0, "section": 2 });
        return e;
    }

    function handleKey(event) {
        if (editor.activeFocus)
            return false;
        if (section === 0) {
            const jump = KeyNav.jump(event, themeCount);
            if (jump >= 0) {
                cursor = jump;
                return true;
            }
        } else if (section === 1) {
            const jump = KeyNav.jump(event, wallCount);
            if (jump >= 0) {
                wallCursor = jump;
                return true;
            }
        }
        if (KeyNav.isNext(event)) {
            if (section === 0)
                cursor = Math.min(themeCount - 1, cursor + 1);
            else if (section === 1)
                wallCursor = Math.min(Math.max(0, wallCount - 1), wallCursor + 2);
            return true;
        }
        if (KeyNav.isPrev(event)) {
            if (section === 0)
                cursor = Math.max(0, cursor - 1);
            else if (section === 1)
                wallCursor = Math.max(0, wallCursor - 2);
            return true;
        }
        if (KeyNav.isRight(event)) {
            if (section === 0)
                section = wallCount > 0 ? 1 : 2;
            else if (section === 1)
                wallCursor = Math.min(Math.max(0, wallCount - 1), wallCursor + 1);
            return true;
        }
        if (KeyNav.isLeft(event)) {
            if (section === 1 && wallCursor % 2 === 0)
                section = 0;
            else if (section === 1)
                wallCursor = Math.max(0, wallCursor - 1);
            else if (section === 2)
                section = 1;
            return true;
        }
        if (KeyNav.isActivate(event)) {
            if (section === 0)
                Themes.apply(Themes.palettes[cursor].id);
            else if (section === 1 && wallCount > 0)
                Wallpaper.apply(Wallpaper.images[wallCursor]);
            else if (section === 2)
                editor.forceActiveFocus();
            return true;
        }
        return false;
    }

    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Colors"
    }

    Repeater {
        model: Themes.palettes

        Rectangle {
            required property var modelData
            required property int index
            readonly property bool selected: root.section === 0 && root.cursor === index
            readonly property bool current: Themes.currentId === modelData.id

            width: root.width
            height: 42
            radius: Style.radius
            color: selected ? Color.focusFill : Color.surface
            border.width: selected ? 1 : 0
            border.color: Color.accent
            Behavior on color { ColorAnimation { duration: Style.animDuration } }

            Rectangle {
                width: 3
                height: selected ? 20 : 0
                radius: 1.5
                color: Color.accent
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: selected
                Behavior on height { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic } }
            }

            IndexBadge {
                id: thBadge
                slot: index
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                id: colorRow
                anchors.left: thBadge.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                    model: [modelData.background, modelData.accent, modelData.urgent, modelData.green]

                    Rectangle {
                        required property var modelData
                        width: 8
                        height: 22
                        radius: 2
                        color: modelData
                        border.width: 1
                        border.color: Color.overlay
                    }
                }
            }

            Column {
                anchors.left: colorRow.right
                anchors.leftMargin: 10
                anchors.right: themeStatusBadge.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: current ? Color.accent : Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    font.bold: true
                    text: modelData.name
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    color: Color.popupMuted
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption
                    text: current ? "Paleta de colores activa" : "Haz clic para aplicar tema"
                }
            }

            Rectangle {
                id: themeStatusBadge
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                height: 20
                width: themeBadgeText.implicitWidth + 12
                radius: 4
                color: current ? Color.focusFill : (selected ? Color.surface : Color.background)
                border.width: 1
                border.color: current ? Color.accent : (selected ? Color.subtleBorder : "transparent")

                Text {
                    id: themeBadgeText
                    anchors.centerIn: parent
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontCaption - 1
                    font.bold: true
                    color: current ? Color.accent : Color.popupMuted
                    text: current ? "ACTIVO" : "TEMA"
                }
            }

            HoverMouse {
                onClicked: {
                    root.section = 0;
                    root.cursor = index;
                    Themes.apply(modelData.id);
                }
            }
        }
    }

    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Background"
    }

    Text {
        visible: Wallpaper.images.length === 0
        width: parent.width
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        wrapMode: Text.Wrap
        text: "Put jpg/png files in ~/Imágenes"
    }

    Grid {
        width: parent.width
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            model: Wallpaper.images

            Rectangle {
                required property var modelData
                required property int index
                readonly property bool selected: root.section === 1 && root.wallCursor === index
                readonly property bool current: Wallpaper.current === modelData

                width: (root.width - 8) / 2
                height: 88
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
                    anchors.bottomMargin: 20
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 160
                    sourceSize.height: 70
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
                        root.section = 1;
                        root.wallCursor = index;
                        Wallpaper.apply(modelData);
                    }
                }
            }
        }
    }

    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Screensaver text"
    }

    Rectangle {
        width: parent.width
        height: 30
        radius: Style.radius
        color: Color.surface
        border.width: root.section === 2 || editor.activeFocus ? 1 : 0
        border.color: Color.accent

        TextInput {
            id: editor
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: Text.AlignVCenter
            color: Color.popupText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontBody
            clip: true
            text: Themes.screensaverDraft
            onTextChanged: Themes.screensaverDraft = text
            onAccepted: Themes.saveScreensaver()
            onActiveFocusChanged: {
                if (activeFocus)
                    root.section = 2;
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    editor.focus = false;
                    event.accepted = true;
                } else if (event.key === Qt.Key_Tab) {
                    root.nextSection(!!(event.modifiers & Qt.ShiftModifier));
                    event.accepted = true;
                }
            }
        }
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
                text: "Reset ZOI"
            }

            HoverMouse {
                onClicked: Themes.resetScreensaver()
            }
        }

        Rectangle {
            width: (parent.width - 6) / 2
            height: 26
            radius: Style.radius
            color: Color.accent

            Text {
                anchors.centerIn: parent
                color: Color.background
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: "Save text"
            }

            HoverMouse {
                onClicked: Themes.saveScreensaver()
            }
        }
    }
}
