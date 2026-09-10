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
        const max = 4;
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
        else if (section === 2)
            Qt.callLater(() => editor.forceActiveFocus());
        else
            editor.focus = false;
    }

    readonly property var searchEntries: {
        const e = [];
        for (let i = 0; i < Themes.palettes.length; i++)
            e.push({ "label": String(Themes.palettes[i].name), "index": i, "section": 0 });
        for (let i = 0; i < Wallpaper.images.length; i++) {
            const parts = String(Wallpaper.images[i] || "").split("/");
            e.push({ "label": parts.length ? parts[parts.length - 1] : "wallpaper", "index": i, "section": 1 });
        }
        e.push({ "label": "salvapantallas screensaver text zoi", "index": 0, "section": 2 });
        e.push({ "label": "restablecer zoi reset screensaver", "index": 0, "section": 3 });
        e.push({ "label": "guardar texto save screensaver", "index": 0, "section": 4 });
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
            else if (section === 3)
                section = 4;
            return true;
        }
        if (KeyNav.isPrev(event)) {
            if (section === 0)
                cursor = Math.max(0, cursor - 1);
            else if (section === 1)
                wallCursor = Math.max(0, wallCursor - 2);
            else if (section === 4)
                section = 3;
            return true;
        }
        if (KeyNav.isRight(event)) {
            if (section === 0)
                section = wallCount > 0 ? 1 : 2;
            else if (section === 1)
                wallCursor = Math.min(Math.max(0, wallCount - 1), wallCursor + 1);
            else if (section === 3)
                section = 4;
            return true;
        }
        if (KeyNav.isLeft(event)) {
            if (section === 1 && wallCursor % 2 === 0)
                section = 0;
            else if (section === 1)
                wallCursor = Math.max(0, wallCursor - 1);
            else if (section === 2)
                section = 1;
            else if (section === 4)
                section = 3;
            return true;
        }
        if (KeyNav.isActivate(event)) {
            if (section === 0)
                Themes.apply(Themes.palettes[cursor].id);
            else if (section === 1 && wallCount > 0)
                Wallpaper.apply(Wallpaper.images[wallCursor]);
            else if (section === 2)
                editor.forceActiveFocus();
            else if (section === 3)
                Themes.resetScreensaver();
            else if (section === 4)
                Themes.saveScreensaver();
            return true;
        }
        return false;
    }

    Text {
        color: Color.popupMuted
        font.family: Style.fontFamily
        font.pixelSize: Style.fontCaption
        text: "Paleta de colores"
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
                    text: {
                        if (current)
                            return modelData.id === "wallpaper" ? "Extraída del fondo de pantalla actual" : "Paleta de colores activa";
                        return modelData.id === "wallpaper" ? "Colores adaptativos del fondo" : "Haz clic para aplicar tema";
                    }
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
        text: "Fondo de pantalla"
    }

    Rectangle {
        visible: Wallpaper.images.length === 0
        width: parent.width
        height: 60
        radius: Style.radius
        color: Color.surface
        border.width: 1
        border.color: Color.subtleBorder

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontBody
                font.bold: true
                text: "No se encontraron imágenes"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Color.popupMuted
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: "Coloca archivos .jpg o .png en ~/Imágenes"
            }
        }
    }

    Grid {
        width: parent.width
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            model: Wallpaper.images

            Rectangle {
                id: wallCard
                required property var modelData
                required property int index
                readonly property bool selected: root.section === 1 && root.wallCursor === index
                readonly property bool current: Wallpaper.current === modelData

                width: (root.width - 8) / 2
                height: 94
                radius: Style.radius
                clip: true
                color: selected ? Color.focusFill : Color.surface
                border.width: current ? 2 : (selected ? 2 : 1)
                border.color: current ? Color.accent : (selected ? Color.focusFill : Color.subtleBorder)
                Behavior on color { ColorAnimation { duration: Style.animDuration } }
                Behavior on border.color { ColorAnimation { duration: Style.animDuration } }

                // Thumbnail image
                Image {
                    anchors.fill: parent
                    anchors.margins: current ? 2 : 1
                    anchors.bottomMargin: 24
                    source: "file://" + modelData
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 180
                    sourceSize.height: 80
                }

                // Dark gradient overlay for bottom title readability
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: parent.height - 26
                    color: current ? Color.mantle : Color.crust
                    opacity: 0.92
                }

                // Top left: Index badge
                IndexBadge {
                    z: 2
                    slot: index
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 6
                }

                // Top right: Active badge
                Rectangle {
                    z: 2
                    visible: wallCard.current
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    height: 18
                    width: activeText.implicitWidth + 10
                    radius: 3
                    color: Color.accent
                    border.width: 1
                    border.color: Color.accent

                    Row {
                        id: activeText
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: Color.crust
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontBadge
                            font.bold: true
                            text: "✓ ACTUAL"
                        }
                    }
                }

                // Bottom bar: filename and active dot
                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 4
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 5

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 5
                        height: 5
                        radius: 2.5
                        color: wallCard.current ? Color.accent : "transparent"
                        visible: wallCard.current
                    }

                    Text {
                        width: parent.width - (wallCard.current ? 10 : 0)
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideMiddle
                        color: wallCard.current ? Color.accent : Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontCaption
                        font.bold: wallCard.current
                        text: root.nameFor(modelData)
                    }
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
        text: "Texto de salvapantallas"
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
                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    root.nextSection(event.key === Qt.Key_Backtab || !!(event.modifiers & Qt.ShiftModifier));
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
            color: root.section === 3 ? Color.focusFill : Color.surface
            border.width: root.section === 3 ? 1 : 0
            border.color: Color.accent

            Text {
                anchors.centerIn: parent
                color: root.section === 3 ? Color.accent : Color.popupText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                text: "Restablecer ZOI"
            }

            HoverMouse {
                onClicked: {
                    root.section = 3;
                    Themes.resetScreensaver();
                }
            }
        }

        Rectangle {
            width: (parent.width - 6) / 2
            height: 26
            radius: Style.radius
            color: Color.accent
            border.width: root.section === 4 ? 2 : 0
            border.color: Color.text

            Text {
                anchors.centerIn: parent
                color: Color.background
                font.family: Style.fontFamily
                font.pixelSize: Style.fontCaption
                font.bold: true
                text: "Guardar texto"
            }

            HoverMouse {
                onClicked: {
                    root.section = 4;
                    Themes.saveScreensaver();
                }
            }
        }
    }
}
