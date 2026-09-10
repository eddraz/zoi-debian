pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../Commons"

PanelWindow {
    id: root

    required property var modelData
    property bool open: false
    property string title: ""
    property bool centerCard: false
    property int cardWidth: 268
    property bool searching: false
    property string searchQuery: ""
    property var searchMatches: []
    property int searchMatchIndex: 0

    onSearchingChanged: {
        Popups.isSearching = searching;
        if (!searching) {
            searchQuery = "";
            searchMatches = [];
            searchMatchIndex = 0;
        }
    }
    property bool hasAnchor: false
    property string anchorSection: ""
    property real anchorLeftX: 0
    property real anchorRightX: 0
    property real anchorCenterX: 0
    property bool allowSlideAnimation: false
    default property alias content: body.children

    signal dismissed

    screen: modelData
    visible: open
    color: "transparent"
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    implicitHeight: modelData.height - Style.barHeight
    WlrLayershell.namespace: "quickshell-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property int availableWidth: Math.max(200, root.width - Style.pad * 2)
    readonly property int availableHeight: Math.max(120, root.height - Style.pad * 2)
    readonly property int resolvedWidth: Math.min(root.cardWidth, Style.popupMaxWidth, availableWidth)

    anchors {
        left: true
        right: true
        bottom: true
    }

    onOpenChanged: {
        scroller.contentY = 0;
        searching = false;
        searchQuery = "";
        if (open) {
            Qt.callLater(() => {
                if (root.open)
                    root.allowSlideAnimation = true;
                card.forceActiveFocus();
            });
        } else {
            root.allowSlideAnimation = false;
        }
    }

    onTitleChanged: {
        scroller.contentY = 0;
        searching = false;
        searchQuery = "";
    }

    function visiblePanel() {
        const kids = body.children;
        for (let i = 0; i < kids.length; i++) {
            const kid = kids[i];
            if (!kid.visible)
                continue;
            if (kid.item)
                return kid.item;
            return kid;
        }
        return null;
    }

    function scrollBy(delta) {
        if (scroller.contentHeight <= scroller.height)
            return false;
        const next = Math.max(0, Math.min(scroller.contentHeight - scroller.height, scroller.contentY + delta));
        if (next === scroller.contentY)
            return false;
        scroller.contentY = next;
        return true;
    }

    function applySearch() {
        const panel = visiblePanel();
        if (!panel)
            return;
        const needle = searchQuery.trim().toLowerCase();
        searchMatches = [];
        searchMatchIndex = 0;
        if (!needle || typeof panel.searchEntries === "undefined")
            return;
        const entries = panel.searchEntries;
        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i];
            const label = String(entry.label || "").toLowerCase();
            if (label.indexOf(needle) >= 0) {
                searchMatches.push(entry);
            }
        }
        if (searchMatches.length > 0) {
            focusCurrentMatch();
        }
    }

    function navigateSearch(delta) {
        if (!searchMatches || searchMatches.length === 0)
            return;
        searchMatchIndex = (searchMatchIndex + delta + searchMatches.length) % searchMatches.length;
        focusCurrentMatch();
    }

    function focusCurrentMatch() {
        const panel = visiblePanel();
        if (!panel || !searchMatches || searchMatches.length === 0)
            return;
        const entry = searchMatches[searchMatchIndex];
        if (typeof panel.focusItem === "function")
            panel.focusItem(entry);
        else if (panel.cursor !== undefined)
            panel.cursor = entry.index;
    }

    function startSearch() {
        const panel = visiblePanel();
        if (panel && typeof panel.beginSearch === "function") {
            panel.beginSearch();
            return;
        }
        searching = true;
        searchQuery = "";
        Qt.callLater(() => findField.forceActiveFocus());
    }

    function triggerQr() {
        const panel = visiblePanel();
        if (panel && typeof panel.openWifiQr === "function") {
            panel.openWifiQr();
        } else {
            Quickshell.execDetached(["/usr/bin/qs", "ipc", "call", "wifiqr", "toggle"]);
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Color.dimOverlay
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animSlow; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        id: card

        function targetCardX() {
            if (root.centerCard || !root.hasAnchor) {
                return root.centerCard ? Math.round((root.width - width) / 2) : (root.width - width - Style.pad);
            }

            let tx = 0;
            if (root.anchorSection === "left") {
                tx = root.anchorLeftX;
            } else if (root.anchorSection === "center") {
                tx = Math.round(root.anchorCenterX - width / 2);
            } else {
                tx = root.anchorRightX - width;
            }

            const minX = Style.pad;
            const maxX = root.width - width - Style.pad;
            if (maxX <= minX)
                return minX;
            return Math.max(minX, Math.min(maxX, tx));
        }

        anchors.top: parent.top
        anchors.topMargin: root.open ? 8 : 0
        x: targetCardX()
        width: root.resolvedWidth
        height: Math.min(column.implicitHeight + Style.pad * 2, root.availableHeight)
        color: Color.popupBackground
        radius: Style.cardRadius
        border.width: 1
        border.color: Color.cardBorder
        focus: root.open
        activeFocusOnTab: true
        clip: true

        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Style.animSlow; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: Style.animSlow; easing.type: Easing.OutCubic } }
        Behavior on x {
            enabled: root.open && root.allowSlideAnimation
            NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Q && (event.modifiers & Qt.MetaModifier)) {
                root.dismissed();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Escape) {
                if (root.searching) {
                    root.searching = false;
                    root.searchQuery = "";
                    card.forceActiveFocus();
                    event.accepted = true;
                    return;
                }
                const panel = root.visiblePanel();
                if (panel && typeof panel.handleEscape === "function" && panel.handleEscape()) {
                    event.accepted = true;
                    return;
                }
                root.dismissed();
                event.accepted = true;
                return;
            }
            if (root.searching || findField.activeFocus) {
                // When search bar is active, all hotkeys / quick keys are strictly blocked
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Tab) {
                const panel = root.visiblePanel();
                if (panel && typeof panel.nextSection === "function") {
                    panel.nextSection(!!(event.modifiers & Qt.ShiftModifier));
                    event.accepted = true;
                    return;
                }
            }
            if (event.key === Qt.Key_Slash || event.text === "/") {
                root.startSearch();
                event.accepted = true;
                return;
            }
            if (Popups.requested === "network" && (event.key === Qt.Key_Q || event.text === "q" || event.text === "Q")) {
                root.triggerQr();
                event.accepted = true;
                return;
            }
            const panel = root.visiblePanel();
            if (panel && typeof panel.handleKey === "function" && panel.handleKey(event)) {
                event.accepted = true;
                return;
            }
            if (KeyNav.isNext(event) || KeyNav.isRight(event)) {
                event.accepted = root.scrollBy(48);
                return;
            }
            if (KeyNav.isPrev(event) || KeyNav.isLeft(event)) {
                event.accepted = root.scrollBy(-48);
                return;
            }
        }

        MouseArea {
            z: -1
            anchors.fill: parent
            onClicked: card.forceActiveFocus()
        }

        Flickable {
            id: scroller
            anchors.fill: parent
            anchors.margins: Style.pad
            contentWidth: width
            contentHeight: column.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height

            Column {
                id: column
                width: scroller.width
                spacing: Style.gap

                Item {
                    width: parent.width
                    height: 20
                    visible: root.title !== ""

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 14
                            radius: 1.5
                            color: Color.accent
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: Color.popupText
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontTitle
                            font.bold: true
                            text: root.title
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        visible: !root.searching

                        Rectangle {
                            id: qrHint
                            visible: Popups.requested === "network"
                            height: 18
                            width: qrHintRow.implicitWidth + 8
                            radius: 3
                            color: Color.surface
                            border.width: 1
                            border.color: Color.subtleBorder

                            Row {
                                id: qrHintRow
                                anchors.centerIn: parent
                                spacing: 4

                                StatusIcon {
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon: "qr"
                                    stroke: Color.popupMuted
                                    width: 11
                                    height: 11
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 12
                                    width: 12
                                    radius: 2
                                    color: Color.mantle

                                    Text {
                                        anchors.centerIn: parent
                                        color: Color.accent
                                        font.family: Style.fontFamily
                                        font.pixelSize: 8
                                        font.bold: true
                                        text: "Q"
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.triggerQr()
                            }
                        }

                        Rectangle {
                            id: searchHint
                            height: 18
                            width: hintRow.implicitWidth + 8
                            radius: 3
                            color: Color.surface
                            border.width: 1
                            border.color: Color.subtleBorder

                            Row {
                                id: hintRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Color.popupMuted
                                    font.family: Style.fontFamily
                                    font.pixelSize: 9
                                    text: "Buscar"
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 12
                                    width: 12
                                    radius: 2
                                    color: Color.mantle

                                    Text {
                                        anchors.centerIn: parent
                                        color: Color.accent
                                        font.family: Style.fontFamily
                                        font.pixelSize: 8
                                        font.bold: true
                                        text: "/"
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.startSearch()
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.searching
                    width: parent.width
                    height: visible ? 30 : 0
                    radius: Style.radius
                    color: Color.crust
                    border.width: 1
                    border.color: Color.accent

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 6
                        spacing: 6

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: Color.accent
                            font.family: Style.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            text: "/"
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(50, parent.width - 60)
                            height: parent.height

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.searchQuery === ""
                                color: Color.popupMuted
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontCaption
                                text: "Filtrar opciones..."
                            }

                            TextInput {
                                id: findField
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                color: Color.popupText
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontCaption
                                clip: true
                                text: root.searchQuery
                                onTextChanged: {
                                    root.searchQuery = text;
                                    root.applySearch();
                                }
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        root.searching = false;
                                        root.searchQuery = "";
                                        card.forceActiveFocus();
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        const panel = root.visiblePanel();
                                        if (panel && typeof panel.handleKey === "function") {
                                            panel.handleKey({
                                                key: Qt.Key_Return,
                                                modifiers: 0,
                                                text: ""
                                            });
                                        }
                                        root.searching = false;
                                        card.forceActiveFocus();
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                                        root.navigateSearch(1);
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                                        root.navigateSearch(-1);
                                        event.accepted = true;
                                        return;
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 16
                            width: escLabel.implicitWidth + 8
                            radius: 2
                            color: Color.surface

                            Text {
                                id: escLabel
                                anchors.centerIn: parent
                                color: Color.popupMuted
                                font.family: Style.fontFamily
                                font.pixelSize: 9
                                text: "Esc"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.searching = false;
                                    root.searchQuery = "";
                                    card.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                Column {
                    id: body
                    width: parent.width
                    spacing: Style.gap
                }

                Item {
                    width: parent.width
                    height: 2
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Color.surface
                    opacity: 0.5
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    opacity: 0.7

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "↑↓"; font.pixelSize: 9; color: Color.accent; font.bold: true }
                        Text { text: "navegar"; font.family: Style.fontFamily; font.pixelSize: 9; color: Color.popupMuted }
                    }

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "↵"; font.pixelSize: 9; color: Color.accent; font.bold: true }
                        Text { text: "activar"; font.family: Style.fontFamily; font.pixelSize: 9; color: Color.popupMuted }
                    }

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: "esc"; font.pixelSize: 8; color: Color.accent; font.bold: true }
                        Text { text: "cerrar"; font.family: Style.fontFamily; font.pixelSize: 9; color: Color.popupMuted }
                    }
                }
            }
        }
    }
}
