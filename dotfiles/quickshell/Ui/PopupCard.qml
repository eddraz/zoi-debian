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
        if (open)
            Qt.callLater(() => card.forceActiveFocus());
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
        if (!needle || typeof panel.searchEntries === "undefined")
            return;
        const entries = panel.searchEntries;
        for (let i = 0; i < entries.length; i++) {
            const entry = entries[i];
            const label = String(entry.label || "").toLowerCase();
            if (label.indexOf(needle) >= 0) {
                if (typeof panel.focusItem === "function")
                    panel.focusItem(entry);
                else if (panel.cursor !== undefined)
                    panel.cursor = entry.index;
                break;
            }
        }
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

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissed()
    }

    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.topMargin: 8
        x: root.centerCard ? Math.round((root.width - width) / 2) : (root.width - width - Style.pad)
        width: root.resolvedWidth
        height: Math.min(column.implicitHeight + Style.pad * 2, root.availableHeight)
        color: Color.popupBackground
        radius: Style.radius
        border.width: 1
        border.color: Color.surface
        focus: root.open
        activeFocusOnTab: true
        clip: true

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
            if (event.key === Qt.Key_Tab) {
                const panel = root.visiblePanel();
                if (panel && typeof panel.nextSection === "function") {
                    panel.nextSection(!!(event.modifiers & Qt.ShiftModifier));
                    event.accepted = true;
                    return;
                }
            }
            if (!root.searching && !findField.activeFocus && (event.key === Qt.Key_Slash || event.text === "/")) {
                root.startSearch();
                event.accepted = true;
                return;
            }
            if (root.searching || findField.activeFocus)
                return;
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

                Text {
                    visible: root.title !== ""
                    color: Color.popupText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontBody
                    font.bold: true
                    text: root.title
                }

                Rectangle {
                    visible: root.searching
                    width: parent.width
                    height: visible ? 30 : 0
                    radius: Style.radius
                    color: Color.surface
                    border.width: 1
                    border.color: Color.accent

                    TextInput {
                        id: findField
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: Text.AlignVCenter
                        color: Color.popupText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontBody
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
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.searching = false;
                                card.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                    }
                }

                Column {
                    id: body
                    width: parent.width
                    spacing: Style.gap
                }
            }
        }
    }
}
