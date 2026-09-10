pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "Commons"
import "Ui"

Variants {
    model: Quickshell.screens

    Scope {
        id: screenRoot

        required property var modelData

        readonly property string popup: Popups.requested
        readonly property string edge: PluginRegistry.barEdge
        readonly property bool vertical: PluginRegistry.isVertical

        function togglePopup(name) {
            HoverTip.hide();
            Popups.toggle(name);
        }

        function setAnchorFromItem(item, widgetId) {
            if (!item || !item.mapToItem)
                return;
            const pt = item.mapToItem(null, 0, 0);
            const sec = PluginRegistry.sectionOf(widgetId) || "right";
            if (screenRoot.vertical) {
                const h = item.height > 0 ? item.height : 32;
                popupCard.anchorSection = sec;
                popupCard.anchorLeftX = pt.y;        // reuse X props for Y axis
                popupCard.anchorRightX = pt.y + h;
                popupCard.anchorCenterX = pt.y + h / 2;
            } else {
                const w = item.width > 0 ? item.width : 32;
                popupCard.anchorSection = sec;
                popupCard.anchorLeftX = pt.x;
                popupCard.anchorRightX = pt.x + w;
                popupCard.anchorCenterX = pt.x + w / 2;
            }
            popupCard.hasAnchor = true;
        }

        function findWidgetInfo(widgetId) {
            if (!widgetId)
                return null;

            if (leftRepeater) {
                const left = PluginRegistry.leftIds;
                for (let i = 0; i < left.length; i++) {
                    if (left[i] === widgetId) {
                        const loader = leftRepeater.itemAt(i);
                        if (loader)
                            return { loader: loader, section: "left" };
                    }
                }
            }
            if (leftFlow && leftFlow.children) {
                for (let i = 0; i < leftFlow.children.length; i++) {
                    const c = leftFlow.children[i];
                    if (c && c.widgetId === widgetId)
                        return { loader: c, section: "left" };
                }
            }

            if (centerRepeater) {
                const center = PluginRegistry.centerIds;
                for (let i = 0; i < center.length; i++) {
                    if (center[i] === widgetId) {
                        const loader = centerRepeater.itemAt(i);
                        if (loader)
                            return { loader: loader, section: "center" };
                    }
                }
            }
            if (centerFlow && centerFlow.children) {
                for (let i = 0; i < centerFlow.children.length; i++) {
                    const c = centerFlow.children[i];
                    if (c && c.widgetId === widgetId)
                        return { loader: c, section: "center" };
                }
            }

            if (rightRepeater) {
                const right = PluginRegistry.rightIds;
                for (let i = 0; i < right.length; i++) {
                    if (right[i] === widgetId) {
                        const loader = rightRepeater.itemAt(i);
                        if (loader)
                            return { loader: loader, section: "right" };
                    }
                }
            }
            if (rightFlow && rightFlow.children) {
                for (let i = 0; i < rightFlow.children.length; i++) {
                    const c = rightFlow.children[i];
                    if (c && c.widgetId === widgetId)
                        return { loader: c, section: "right" };
                }
            }

            return null;
        }

        function updatePopupAnchor() {
            if (!screenRoot.popup) {
                popupCard.hasAnchor = false;
                return;
            }
            const wid = PluginRegistry.widgetIdByPopup(screenRoot.popup);
            if (!wid) {
                popupCard.hasAnchor = false;
                return;
            }
            const info = screenRoot.findWidgetInfo(wid);
            if (!info || !info.loader) {
                popupCard.hasAnchor = false;
                return;
            }
            const target = (info.loader.item && info.loader.item.mapToItem) ? info.loader.item : info.loader;
            const pt = target.mapToItem(null, 0, 0);
            if (screenRoot.vertical) {
                const h = (target.height > 0) ? target.height : (info.loader.height > 0 ? info.loader.height : 32);
                popupCard.anchorSection = info.section;
                popupCard.anchorLeftX = pt.y;
                popupCard.anchorRightX = pt.y + h;
                popupCard.anchorCenterX = pt.y + h / 2;
            } else {
                const w = (target.width > 0) ? target.width : (info.loader.width > 0 ? info.loader.width : 32);
                popupCard.anchorSection = info.section;
                popupCard.anchorLeftX = pt.x;
                popupCard.anchorRightX = pt.x + w;
                popupCard.anchorCenterX = pt.x + w / 2;
            }
            popupCard.hasAnchor = true;
        }

        onPopupChanged: updatePopupAnchor()

        Connections {
            target: PluginRegistry
            function onRevisionChanged() {
                if (screenRoot.popup !== "")
                    screenRoot.updatePopupAnchor();
            }
        }

        function bindChip(item, id) {
            if (!item || item.togglePanel === undefined)
                return;
            const meta = PluginRegistry.widgetMeta(id);
            if (!meta)
                return;
            item.togglePanel.connect(() => {
                if (meta.ipc && meta.ipc.length) {
                    Quickshell.execDetached(["/usr/bin/qs", "ipc", "call"].concat(meta.ipc));
                } else if (meta.popup) {
                    screenRoot.setAnchorFromItem(item, id);
                    screenRoot.togglePopup(meta.popup);
                }
            });
        }

        function bindPanel(item) {
            if (!item)
                return;
            if (item.openKeys !== undefined)
                item.openKeys.connect(() => Popups.open("keys"));
            if (item.openTheme !== undefined)
                item.openTheme.connect(() => Popups.open("theme"));
            if (item.openBar !== undefined)
                item.openBar.connect(() => Popups.open("bar"));
        }

        component ChipLoader: Loader {
            required property var modelData
            readonly property string widgetId: String(modelData)
            source: PluginRegistry.widgetUrl(widgetId)
            // For horizontal bar: center vertically. For vertical: center horizontally.
            anchors.verticalCenter: !screenRoot.vertical && parent ? parent.verticalCenter : undefined
            anchors.horizontalCenter: screenRoot.vertical && parent ? parent.horizontalCenter : undefined
            onLoaded: screenRoot.bindChip(item, widgetId)
        }

        // ── Drag-to-edge overlay ──
        Item {
            id: dragOverlay
            property bool dragging: false
            property string hoverEdge: ""
        }

        PanelWindow {
            id: barWindow
            screen: screenRoot.modelData
            color: Color.barBackground
            // Bar thickness: fixed for the thin dimension
            implicitHeight: screenRoot.vertical ? screenRoot.modelData.height : Style.barHeight
            implicitWidth: screenRoot.vertical ? Style.barHeight : screenRoot.modelData.width

            anchors {
                top: screenRoot.edge === "top" || screenRoot.vertical
                bottom: screenRoot.edge === "bottom" || screenRoot.vertical
                left: screenRoot.edge === "left" || !screenRoot.vertical
                right: screenRoot.edge === "right" || !screenRoot.vertical
            }

            // ── Drag handle for repositioning the bar ──
            MouseArea {
                id: barDrag
                z: -1
                anchors.fill: parent
                property bool isDragging: false
                property real startX: 0
                property real startY: 0

                onPressed: mouse => {
                    startX = mouse.x;
                    startY = mouse.y;
                    isDragging = false;
                }

                onPositionChanged: mouse => {
                    if (!isDragging) {
                        const dx = mouse.x - startX;
                        const dy = mouse.y - startY;
                        if (Math.sqrt(dx*dx + dy*dy) > 30)
                            isDragging = true;
                    }
                    if (isDragging) {
                        // Determine which edge we're near
                        const globalPos = mapToGlobal(mouse.x, mouse.y);
                        const sw = screenRoot.modelData.width;
                        const sh = screenRoot.modelData.height;
                        const margin = 60;
                        let edge = screenRoot.edge;
                        if (globalPos.y < margin) edge = "top";
                        else if (globalPos.y > sh - margin) edge = "bottom";
                        else if (globalPos.x < margin) edge = "left";
                        else if (globalPos.x > sw - margin) edge = "right";
                        dragOverlay.hoverEdge = edge;
                        dragOverlay.dragging = true;
                    }
                }

                onReleased: {
                    if (isDragging && dragOverlay.hoverEdge !== "") {
                        PluginRegistry.setBarEdge(dragOverlay.hoverEdge);
                    }
                    isDragging = false;
                    dragOverlay.dragging = false;
                    dragOverlay.hoverEdge = "";
                }
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin: Style.pad
                anchors.rightMargin: Style.pad
                anchors.topMargin: screenRoot.vertical ? Style.pad : 0
                anchors.bottomMargin: screenRoot.vertical ? Style.pad : 0

                // ── Horizontal Bar Layout ──
                Row {
                    id: leftFlow
                    visible: !screenRoot.vertical
                    height: parent.height
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Repeater {
                        id: leftRepeater
                        model: PluginRegistry.leftIds
                        ChipLoader {}
                    }
                }

                Row {
                    id: centerFlow
                    visible: !screenRoot.vertical
                    height: parent.height
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        id: centerRepeater
                        model: PluginRegistry.centerIds
                        ChipLoader {}
                    }
                }

                Row {
                    id: rightFlow
                    visible: !screenRoot.vertical
                    height: parent.height
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        id: rightRepeater
                        model: PluginRegistry.rightIds
                        ChipLoader {}
                    }
                }

                // ── Vertical Bar Layout ──
                Column {
                    id: leftVFlow
                    visible: screenRoot.vertical
                    width: parent.width
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Repeater {
                        id: leftVRepeater
                        model: screenRoot.vertical ? PluginRegistry.leftIds : []
                        ChipLoader {}
                    }
                }

                Column {
                    id: centerVFlow
                    visible: screenRoot.vertical
                    width: parent.width
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        id: centerVRepeater
                        model: screenRoot.vertical ? PluginRegistry.centerIds : []
                        ChipLoader {}
                    }
                }

                Column {
                    id: rightVFlow
                    visible: screenRoot.vertical
                    width: parent.width
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Repeater {
                        id: rightVRepeater
                        model: screenRoot.vertical ? PluginRegistry.rightIds : []
                        ChipLoader {}
                    }
                }
            }
        }

        HoverTipLayer {
            modelData: screenRoot.modelData
        }

        PopupCard {
            id: popupCard
            modelData: screenRoot.modelData
            open: screenRoot.popup !== ""
            centerCard: !!PluginRegistry.panelMeta(screenRoot.popup).centerCard
            cardWidth: PluginRegistry.panelMeta(screenRoot.popup).cardWidth || 268
            title: String(PluginRegistry.panelMeta(screenRoot.popup).title || "")
            barEdge: screenRoot.edge
            onDismissed: Popups.closeAll()

            Loader {
                active: screenRoot.popup !== ""
                width: parent.width
                source: PluginRegistry.panelUrl(screenRoot.popup)
                onLoaded: screenRoot.bindPanel(item)
            }
        }
    }
}
