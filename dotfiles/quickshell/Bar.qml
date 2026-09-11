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

        function togglePopup(name) {
            HoverTip.hide();
            Popups.toggle(name);
        }

        function setAnchorFromItem(item, widgetId) {
            if (!item || !item.mapToItem)
                return;
            const pt = item.mapToItem(null, 0, 0);
            const w = item.width > 0 ? item.width : 32;
            const sec = PluginRegistry.sectionOf(widgetId) || "right";
            popupCard.anchorSection = sec;
            popupCard.anchorLeftX = pt.x;
            popupCard.anchorRightX = pt.x + w;
            popupCard.anchorCenterX = pt.x + w / 2;
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
            if (leftRow && leftRow.children) {
                for (let i = 0; i < leftRow.children.length; i++) {
                    const c = leftRow.children[i];
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
            if (centerRow && centerRow.children) {
                for (let i = 0; i < centerRow.children.length; i++) {
                    const c = centerRow.children[i];
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
            if (rightRow && rightRow.children) {
                for (let i = 0; i < rightRow.children.length; i++) {
                    const c = rightRow.children[i];
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
            const w = (target.width > 0) ? target.width : (info.loader.width > 0 ? info.loader.width : 32);
            popupCard.anchorSection = info.section;
            popupCard.anchorLeftX = pt.x;
            popupCard.anchorRightX = pt.x + w;
            popupCard.anchorCenterX = pt.x + w / 2;
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
            if (item.openTrigger !== undefined)
                item.openTrigger.connect(() => Popups.open("trigger"));
            if (item.openLearn !== undefined)
                item.openLearn.connect(() => Popups.open("learn"));
        }

        component ChipLoader: Loader {
            required property var modelData
            readonly property string widgetId: String(modelData)
            source: PluginRegistry.widgetUrl(widgetId)
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            onLoaded: screenRoot.bindChip(item, widgetId)
        }

        PanelWindow {
            screen: screenRoot.modelData
            color: Color.barBackground
            implicitHeight: Style.barHeight

            anchors {
                top: true
                left: true
                right: true
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin: Style.pad
                anchors.rightMargin: Style.pad

                Row {
                    id: leftRow
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
                    id: centerRow
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
                    id: rightRow
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
