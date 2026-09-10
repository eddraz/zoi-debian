pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property color background: "#1e1e2e"
    property color mantle: "#181825"
    property color crust: "#11111b"
    property color foreground: "#cdd6f4"
    property color muted: "#a6adc8"
    property color overlay: "#6c7086"
    property color surface: "#313244"
    property color accent: "#89b4fa"
    property color urgent: "#f38ba8"
    property color green: "#a6e3a1"
    property color peach: "#fab387"
    property color yellow: "#f9e2af"

    readonly property color barBackground: background
    readonly property color barText: foreground
    readonly property color popupBackground: mantle
    readonly property color popupText: foreground
    readonly property color popupMuted: muted
    readonly property color focusFill: Qt.rgba(accent.r, accent.g, accent.b, 0.22)
    readonly property color cardBorder: Qt.rgba(accent.r, accent.g, accent.b, 0.25)
    readonly property color dimOverlay: Qt.rgba(0, 0, 0, 0.38)
    readonly property color subtleBorder: Qt.rgba(accent.r, accent.g, accent.b, 0.14)

    readonly property string colorsPath: Quickshell.env("HOME") + "/.local/state/quickshell/colors.json"

    FileView {
        id: colorsFile
        path: root.colorsPath
        watchChanges: true
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(String(text()).trim());
                if (data && data.background) {
                    root.background = data.background;
                    root.mantle = data.mantle || data.dark_background || data.background;
                    root.crust = data.crust || data.darker_background || data.background;
                    root.foreground = data.foreground || "#cdd6f4";
                    root.muted = data.muted || data.overlay || "#a6adc8";
                    root.overlay = data.overlay || data.muted || "#6c7086";
                    root.surface = data.surface || data.lighter_background || data.background;
                    root.accent = data.accent || "#89b4fa";
                    root.urgent = data.urgent || data.red || "#f38ba8";
                    root.green = data.green || "#a6e3a1";
                    root.peach = data.peach || data.orange || "#fab387";
                    root.yellow = data.yellow || "#f9e2af";
                }
            } catch (e) {
            }
        }
    }
}

