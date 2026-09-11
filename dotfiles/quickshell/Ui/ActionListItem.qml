pragma ComponentBehavior: Bound

import QtQuick
import "../Commons"

// Reusable list item for panels.
// Encapsulates the standard row: indicator pill · IndexBadge · optional leading · title/desc · status badge · HoverMouse.
Item {
    id: root

    // Optional extra content between the index badge and the title (e.g. theme swatches).
    property Component leading: null

    // --- Required props ---
    property bool selected: false
    property int slot: 0                     // IndexBadge slot (0-9)
    property string title: ""
    property string description: ""

    // --- Optional customization ---
    property string badge: ""                // status badge text (e.g. "ACTIVO", "ON")
    property color badgeTextColor: Color.popupMuted
    property color badgeBg: selected ? Color.surface : Color.background
    property color badgeBorderColor: selected ? Color.subtleBorder : "transparent"

    property bool highlighted: false         // "active" state (e.g. connected, current device)
    property color highlightColor: Color.accent
    property color highlightBg: Color.accent // background when highlighted overrides row color

    property bool useHighlightBg: false      // if true, row bg = highlightBg when highlighted (e.g. BT on, Wifi on)
    property color titleColor: highlighted ? highlightColor : Color.popupText
    property color descColor: useHighlightBg && highlighted ? Color.background : Color.popupMuted

    property int itemHeight: 42

    signal clicked()
    signal doubleClicked()

    width: parent ? parent.width : 252
    height: itemHeight

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Style.radius
        color: root.useHighlightBg && root.highlighted
               ? root.highlightBg
               : (root.selected ? Color.focusFill : Color.surface)
        border.width: root.selected ? 1 : 0
        border.color: root.useHighlightBg && root.highlighted
                      ? Color.background : Color.accent
        Behavior on color { ColorAnimation { duration: Style.animDuration } }
    }

    // Active indicator pill on left
    Rectangle {
        width: 3
        height: root.selected ? 20 : 0
        radius: 1.5
        color: root.useHighlightBg && root.highlighted ? Color.background : Color.accent
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.selected
        Behavior on height { NumberAnimation { duration: Style.animDuration; easing.type: Easing.OutCubic } }
    }

    // Keycap badge [1], [2], ...
    IndexBadge {
        id: indexBadge
        slot: root.slot
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }

    Loader {
        id: leadingLoader
        anchors.left: parent.left
        anchors.leftMargin: 32
        anchors.verticalCenter: parent.verticalCenter
        visible: status === Loader.Ready
        width: visible ? Math.max(implicitWidth, item ? item.implicitWidth : 0) : 0
        height: 22
        sourceComponent: root.leading
    }

    // Title + Description column
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 32 + (leadingLoader.visible ? leadingLoader.width + 10 : 0)
        anchors.right: statusBadge.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            elide: Text.ElideRight
            color: root.useHighlightBg && root.highlighted ? Color.background : root.titleColor
            font.family: Style.fontFamily
            font.pixelSize: Style.fontBody
            font.bold: true
            text: root.title
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            color: root.descColor
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption
            text: root.description
            visible: root.description !== ""
        }
    }

    // Status badge on the right
    Rectangle {
        id: statusBadge
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        visible: root.badge !== ""
        height: 20
        width: badgeLabel.implicitWidth + 12
        radius: 4
        color: root.highlighted
               ? (root.useHighlightBg ? Color.background : Color.focusFill)
               : root.badgeBg
        border.width: 1
        border.color: root.highlighted
                      ? (root.useHighlightBg ? Color.background : Color.accent)
                      : root.badgeBorderColor

        Text {
            id: badgeLabel
            anchors.centerIn: parent
            font.family: Style.fontFamily
            font.pixelSize: Style.fontCaption - 1
            font.bold: true
            color: root.highlighted
                   ? (root.useHighlightBg ? Color.accent : Color.accent)
                   : root.badgeTextColor
            text: root.badge
        }
    }

    // Hover overlay + click handler
    HoverMouse {
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }
}
