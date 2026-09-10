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

        function bindChip(item, id) {
            if (!item || item.togglePanel === undefined)
                return;
            const meta = PluginRegistry.widgetMeta(id);
            if (!meta)
                return;
            item.togglePanel.connect(() => {
                if (meta.ipc && meta.ipc.length)
                    Quickshell.execDetached(["/usr/bin/qs", "ipc", "call"].concat(meta.ipc));
                else if (meta.popup)
                    screenRoot.togglePopup(meta.popup);
            });
        }

        function bindPanel(item) {
            if (!item)
                return;
            if (item.openKeys !== undefined)
                item.openKeys.connect(() => Popups.open("keys"));
            if (item.openWallpaper !== undefined)
                item.openWallpaper.connect(() => Popups.open("wallpaper"));
            if (item.openTheme !== undefined)
                item.openTheme.connect(() => Popups.open("theme"));
            if (item.openBar !== undefined)
                item.openBar.connect(() => Popups.open("bar"));
        }

        component ChipLoader: Loader {
            required property var modelData
            source: PluginRegistry.widgetUrl(String(modelData))
            onLoaded: screenRoot.bindChip(item, String(modelData))
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
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Repeater {
                        model: PluginRegistry.leftIds
                        ChipLoader {}
                    }
                }

                Row {
                    id: centerRow
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: PluginRegistry.centerIds
                        ChipLoader {}
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
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
