pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string currentId: "mocha"
    property string screensaverDraft: ""
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string statePath: stateDir + "/theme"
    readonly property string screensaverPath: Quickshell.env("HOME") + "/.config/quickshell/screensaver.txt"
    readonly property string screensaverColorsPath: stateDir + "/screensaver-colors"
    readonly property string defaultScreensaver: "ZOI"
    readonly property string paletteHelper: Quickshell.env("HOME") + "/.local/bin/qs-theme-from-wallpaper"
    property string pendingWallpaper: ""
    property string wallpaperPath: ""
    property var wallpaperColors: ({
        "id": "wallpaper",
        "name": "Wallpaper",
        "background": "#1e1e2e",
        "mantle": "#181825",
        "crust": "#11111b",
        "foreground": "#cdd6f4",
        "muted": "#a6adc8",
        "overlay": "#6c7086",
        "surface": "#313244",
        "accent": "#89b4fa",
        "urgent": "#f38ba8",
        "green": "#a6e3a1",
        "peach": "#fab387",
        "yellow": "#f9e2af"
    })

    readonly property var palettes: [wallpaperColors].concat(stockPalettes)

    readonly property var stockPalettes: [
        {
            "id": "mocha",
            "name": "Mocha",
            "background": "#1e1e2e",
            "mantle": "#181825",
            "crust": "#11111b",
            "foreground": "#cdd6f4",
            "muted": "#a6adc8",
            "overlay": "#6c7086",
            "surface": "#313244",
            "accent": "#89b4fa",
            "urgent": "#f38ba8",
            "green": "#a6e3a1",
            "peach": "#fab387",
            "yellow": "#f9e2af"
        },
        {
            "id": "macchiato",
            "name": "Macchiato",
            "background": "#24273a",
            "mantle": "#1e2030",
            "crust": "#181926",
            "foreground": "#cad3f5",
            "muted": "#a5adcb",
            "overlay": "#6e738d",
            "surface": "#363a4f",
            "accent": "#8aadf4",
            "urgent": "#ed8796",
            "green": "#a6da95",
            "peach": "#f5a97f",
            "yellow": "#eed49f"
        },
        {
            "id": "frappe",
            "name": "Frappé",
            "background": "#303446",
            "mantle": "#292c3c",
            "crust": "#232634",
            "foreground": "#c6d0f5",
            "muted": "#a5adce",
            "overlay": "#737994",
            "surface": "#414559",
            "accent": "#8caaee",
            "urgent": "#e78284",
            "green": "#a6d189",
            "peach": "#ef9f76",
            "yellow": "#e5c890"
        },
        {
            "id": "latte",
            "name": "Latte",
            "background": "#eff1f5",
            "mantle": "#e6e9ef",
            "crust": "#dce0e8",
            "foreground": "#4c4f69",
            "muted": "#6c6f85",
            "overlay": "#9ca0b0",
            "surface": "#ccd0da",
            "accent": "#1e66f5",
            "urgent": "#d20f39",
            "green": "#40a02b",
            "peach": "#fe640b",
            "yellow": "#df8e1d"
        },
        {
            "id": "kanagawa",
            "name": "Kanagawa",
            "background": "#1f1f28",
            "mantle": "#16161d",
            "crust": "#16161d",
            "foreground": "#dcd7ba",
            "muted": "#727169",
            "overlay": "#54546d",
            "surface": "#2a2a37",
            "accent": "#7e9cd8",
            "urgent": "#c34043",
            "green": "#98bb6c",
            "peach": "#ffa066",
            "yellow": "#dca561"
        },
        {
            "id": "nord",
            "name": "Nord",
            "background": "#2e3440",
            "mantle": "#3b4252",
            "crust": "#2e3440",
            "foreground": "#eceff4",
            "muted": "#d8dee9",
            "overlay": "#4c566a",
            "surface": "#434c5e",
            "accent": "#88c0d0",
            "urgent": "#bf616a",
            "green": "#a3be8c",
            "peach": "#d08770",
            "yellow": "#ebcb8b"
        },
        {
            "id": "gruvbox",
            "name": "Gruvbox",
            "background": "#282828",
            "mantle": "#1d2021",
            "crust": "#1d2021",
            "foreground": "#ebdbb2",
            "muted": "#a89984",
            "overlay": "#928374",
            "surface": "#3c3836",
            "accent": "#83a598",
            "urgent": "#fb4934",
            "green": "#b8bb26",
            "peach": "#fe8019",
            "yellow": "#fabd2f"
        },
        {
            "id": "dracula",
            "name": "Dracula",
            "background": "#282a36",
            "mantle": "#21222c",
            "crust": "#191a21",
            "foreground": "#f8f8f2",
            "muted": "#6272a4",
            "overlay": "#6272a4",
            "surface": "#44475a",
            "accent": "#bd93f9",
            "urgent": "#ff5555",
            "green": "#50fa7b",
            "peach": "#ffb86c",
            "yellow": "#f1fa8c"
        },
        {
            "id": "rosepine",
            "name": "Rosé Pine",
            "background": "#191724",
            "mantle": "#1f1d2e",
            "crust": "#191724",
            "foreground": "#e0def4",
            "muted": "#908caa",
            "overlay": "#6e6a86",
            "surface": "#26233a",
            "accent": "#c4a7e7",
            "urgent": "#eb6f92",
            "green": "#9ccfd8",
            "peach": "#f6c177",
            "yellow": "#f6c177"
        }
    ]

    function paletteById(id) {
        for (let i = 0; i < palettes.length; i++) {
            if (palettes[i].id === id)
                return palettes[i];
        }
        return palettes[0];
    }

    function stripHash(value) {
        const text = String(value || "");
        return text.charAt(0) === "#" ? text.slice(1) : text;
    }

    function refreshFromWallpaper(path) {
        if (!path)
            return;
        wallpaperPath = path;
        if (extractProc.running) {
            pendingWallpaper = path;
            return;
        }
        extractProc.command = [paletteHelper, path];
        extractProc.running = true;
    }

    function parseWallpaperColors(text) {
        const map = {};
        const lines = String(text || "").split("\n");
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            const cut = line.indexOf("=");
            if (cut <= 0)
                continue;
            map[line.slice(0, cut).trim()] = line.slice(cut + 1).trim();
        }
        if (!map.background)
            return;
        wallpaperColors = {
            "id": "wallpaper",
            "name": "Wallpaper",
            "background": map.background,
            "mantle": map.mantle || map.background,
            "crust": map.crust || map.background,
            "foreground": map.foreground || "#cdd6f4",
            "muted": map.muted || map.foreground,
            "overlay": map.overlay || map.muted,
            "surface": map.surface || map.background,
            "accent": map.accent || "#89b4fa",
            "urgent": map.urgent || "#f38ba8",
            "green": map.green || "#a6e3a1",
            "peach": map.peach || "#fab387",
            "yellow": map.yellow || "#f9e2af"
        };
        if (currentId === "wallpaper")
            apply("wallpaper");
    }

    function apply(id) {
        const pal = paletteById(id);
        currentId = pal.id;
        if (id === "wallpaper" && wallpaperPath && !extractProc.running)
            refreshFromWallpaper(wallpaperPath);
        Color.background = pal.background;
        Color.mantle = pal.mantle;
        Color.crust = pal.crust;
        Color.foreground = pal.foreground;
        Color.muted = pal.muted;
        Color.overlay = pal.overlay;
        Color.surface = pal.surface;
        Color.accent = pal.accent;
        Color.urgent = pal.urgent;
        Color.green = pal.green;
        Color.peach = pal.peach;
        Color.yellow = pal.yellow;
        persist();
        writeScreensaverColors(pal);
    }

    function persist() {
        Quickshell.execDetached(["mkdir", "-p", stateDir]);
        themeFile.setText(currentId + "\n");
    }

    function writeScreensaverColors(pal) {
        Quickshell.execDetached(["mkdir", "-p", stateDir]);
        colorsFile.setText(stripHash(pal.crust) + "\n" + stripHash(pal.accent) + "\n");
    }

    function saveScreensaver() {
        const value = String(screensaverDraft || "").replace(/\n/g, " ").trim();
        screensaverDraft = value === "" ? defaultScreensaver : value;
        saverFile.setText(screensaverDraft + "\n");
    }

    function resetScreensaver() {
        screensaverDraft = defaultScreensaver;
        saveScreensaver();
    }

    FileView {
        id: themeFile
        path: root.statePath
        watchChanges: true
        printErrors: false
        onLoaded: {
            const value = String(text()).trim();
            if (value !== "")
                root.apply(value);
        }
    }

    FileView {
        id: colorsFile
        path: root.screensaverColorsPath
        printErrors: false
    }

    FileView {
        id: saverFile
        path: root.screensaverPath
        watchChanges: true
        printErrors: false
        onLoaded: root.screensaverDraft = String(text()).trim().split("\n")[0]
    }

    Process {
        id: extractProc
        stdout: StdioCollector {
            onStreamFinished: root.parseWallpaperColors(text)
        }
        onExited: {
            if (root.pendingWallpaper !== "") {
                const path = root.pendingWallpaper;
                root.pendingWallpaper = "";
                root.refreshFromWallpaper(path);
            }
        }
    }
}
