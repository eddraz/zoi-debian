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
    readonly property string applyHelper: Quickshell.env("HOME") + "/.local/bin/qs-theme-apply"
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
                "mode": "dark",
                "accent": "#7aa2f7",
                "selection": "#292e42",
                "muted": "#414868",
                "background": "#1a1b26",
                "dark_background": "#13141c",
                "darker_background": "#0e0e14",
                "lighter_background": "#24283b",
                "foreground": "#a9b1d6",
                "dark_foreground": "#565f89",
                "light_foreground": "#b4bee6",
                "bright_foreground": "#c0caf5",
                "red": "#f7768e",
                "yellow": "#e0af68",
                "orange": "#eb927b",
                "green": "#9ece6a",
                "cyan": "#449dab",
                "blue": "#7aa2f7",
                "magenta": "#ad8ee6",
                "brown": "#75493d",
                "bright_red": "#ff7a93",
                "bright_yellow": "#ff9e64",
                "bright_green": "#b9f27c",
                "bright_cyan": "#0db9d7",
                "bright_blue": "#7da6ff",
                "bright_magenta": "#bb9af7",
                "id": "tokyo-night",
                "name": "Tokyo Night",
                "mantle": "#13141c",
                "crust": "#0e0e14",
                "surface": "#24283b",
                "overlay": "#414868",
                "urgent": "#f7768e",
                "peach": "#eb927b"
        },
        {
                "mode": "dark",
                "accent": "#89b4fa",
                "selection": "#45475a",
                "muted": "#585b70",
                "background": "#1e1e2e",
                "dark_background": "#161622",
                "darker_background": "#101019",
                "lighter_background": "#313244",
                "foreground": "#cdd6f4",
                "dark_foreground": "#6c7086",
                "light_foreground": "#bac2de",
                "bright_foreground": "#cdd6f4",
                "red": "#f38ba8",
                "yellow": "#f9e2af",
                "orange": "#f6b6ab",
                "green": "#a6e3a1",
                "cyan": "#94e2d5",
                "blue": "#89b4fa",
                "magenta": "#f5c2e7",
                "brown": "#7b5b55",
                "bright_red": "#f38ba8",
                "bright_yellow": "#f9e2af",
                "bright_green": "#a6e3a1",
                "bright_cyan": "#94e2d5",
                "bright_blue": "#89b4fa",
                "bright_magenta": "#f5c2e7",
                "id": "catppuccin",
                "name": "Catppuccin",
                "mantle": "#161622",
                "crust": "#101019",
                "surface": "#313244",
                "overlay": "#585b70",
                "urgent": "#f38ba8",
                "peach": "#f6b6ab"
        },
        {
                "mode": "dark",
                "accent": "#8aadf4",
                "selection": "#363a4f",
                "muted": "#5b6078",
                "background": "#24273a",
                "dark_background": "#1e2030",
                "darker_background": "#181926",
                "lighter_background": "#363a4f",
                "foreground": "#cad3f5",
                "dark_foreground": "#6e738d",
                "light_foreground": "#b8c0e0",
                "bright_foreground": "#cad3f5",
                "red": "#ed8796",
                "yellow": "#eed49f",
                "orange": "#f5a97f",
                "green": "#a6da95",
                "cyan": "#8bd5ca",
                "blue": "#8aadf4",
                "magenta": "#c6a0f6",
                "brown": "#f0c6c6",
                "bright_red": "#ee99a0",
                "bright_yellow": "#eed49f",
                "bright_green": "#a6da95",
                "bright_cyan": "#91d7e3",
                "bright_blue": "#8aadf4",
                "bright_magenta": "#f5bde6",
                "id": "catppuccin-macchiato",
                "name": "Catppuccin Macchiato",
                "mantle": "#1e2030",
                "crust": "#181926",
                "surface": "#363a4f",
                "overlay": "#5b6078",
                "urgent": "#ed8796",
                "peach": "#f5a97f"
        },
        {
                "mode": "dark",
                "accent": "#8caaee",
                "selection": "#414559",
                "muted": "#626880",
                "background": "#303446",
                "dark_background": "#292c3c",
                "darker_background": "#232634",
                "lighter_background": "#414559",
                "foreground": "#c6d0f5",
                "dark_foreground": "#737994",
                "light_foreground": "#b5bfe2",
                "bright_foreground": "#c6d0f5",
                "red": "#e78284",
                "yellow": "#e5c890",
                "orange": "#ef9f76",
                "green": "#a6d189",
                "cyan": "#81c8be",
                "blue": "#8caaee",
                "magenta": "#ca9ee6",
                "brown": "#eebebe",
                "bright_red": "#ea999c",
                "bright_yellow": "#e5c890",
                "bright_green": "#a6d189",
                "bright_cyan": "#99d1db",
                "bright_blue": "#8caaee",
                "bright_magenta": "#f4b8e4",
                "id": "catppuccin-frappe",
                "name": "Catppuccin Frappe",
                "mantle": "#292c3c",
                "crust": "#232634",
                "surface": "#414559",
                "overlay": "#626880",
                "urgent": "#e78284",
                "peach": "#ef9f76"
        },
        {
                "mode": "light",
                "accent": "#1e66f5",
                "selection": "#ccd0da",
                "muted": "#acb0be",
                "background": "#eff1f5",
                "dark_background": "#e3e4e8",
                "darker_background": "#d7d8dc",
                "lighter_background": "#dce0e8",
                "foreground": "#4c4f69",
                "dark_foreground": "#9ca0b0",
                "light_foreground": "#5c5f77",
                "bright_foreground": "#4c4f69",
                "red": "#d20f39",
                "yellow": "#df8e1d",
                "orange": "#d84e2b",
                "green": "#40a02b",
                "cyan": "#179299",
                "blue": "#1e66f5",
                "magenta": "#ea76cb",
                "brown": "#6c2715",
                "bright_red": "#d20f39",
                "bright_yellow": "#df8e1d",
                "bright_green": "#40a02b",
                "bright_cyan": "#179299",
                "bright_blue": "#1e66f5",
                "bright_magenta": "#ea76cb",
                "id": "catppuccin-latte",
                "name": "Catppuccin Latte",
                "mantle": "#e3e4e8",
                "crust": "#d7d8dc",
                "surface": "#dce0e8",
                "overlay": "#acb0be",
                "urgent": "#d20f39",
                "peach": "#d84e2b"
        },
        {
                "mode": "dark",
                "accent": "#7daea3",
                "selection": "#504945",
                "muted": "#665c54",
                "background": "#282828",
                "dark_background": "#1e1e1e",
                "darker_background": "#161616",
                "lighter_background": "#3c3836",
                "foreground": "#d4be98",
                "dark_foreground": "#7c6f64",
                "light_foreground": "#bdae93",
                "bright_foreground": "#d4be98",
                "red": "#ea6962",
                "yellow": "#d8a657",
                "orange": "#e1875c",
                "green": "#a9b665",
                "cyan": "#89b482",
                "blue": "#7daea3",
                "magenta": "#d3869b",
                "brown": "#70432e",
                "bright_red": "#ea6962",
                "bright_yellow": "#d8a657",
                "bright_green": "#a9b665",
                "bright_cyan": "#89b482",
                "bright_blue": "#7daea3",
                "bright_magenta": "#d3869b",
                "id": "gruvbox",
                "name": "Gruvbox",
                "mantle": "#1e1e1e",
                "crust": "#161616",
                "surface": "#3c3836",
                "overlay": "#665c54",
                "urgent": "#ea6962",
                "peach": "#e1875c"
        },
        {
                "mode": "dark",
                "accent": "#81a1c1",
                "selection": "#434c5e",
                "muted": "#4c566a",
                "background": "#2e3440",
                "dark_background": "#222730",
                "darker_background": "#191c23",
                "lighter_background": "#3b4252",
                "foreground": "#d8dee9",
                "dark_foreground": "#667080",
                "light_foreground": "#adb5c4",
                "bright_foreground": "#d8dee9",
                "red": "#bf616a",
                "yellow": "#ebcb8b",
                "orange": "#d5967a",
                "green": "#a3be8c",
                "cyan": "#88c0d0",
                "blue": "#81a1c1",
                "magenta": "#b48ead",
                "brown": "#6a4b3d",
                "bright_red": "#bf616a",
                "bright_yellow": "#ebcb8b",
                "bright_green": "#a3be8c",
                "bright_cyan": "#8fbcbb",
                "bright_blue": "#81a1c1",
                "bright_magenta": "#b48ead",
                "id": "nord",
                "name": "Nord",
                "mantle": "#222730",
                "crust": "#191c23",
                "surface": "#3b4252",
                "overlay": "#4c566a",
                "urgent": "#bf616a",
                "peach": "#d5967a"
        },
        {
                "mode": "dark",
                "accent": "#dcd7ba",
                "selection": "#363646",
                "muted": "#54546D",
                "background": "#1f1f28",
                "dark_background": "#17171e",
                "darker_background": "#111116",
                "lighter_background": "#223249",
                "foreground": "#dcd7ba",
                "dark_foreground": "#727169",
                "light_foreground": "#c8c093",
                "bright_foreground": "#dcd7ba",
                "red": "#c34043",
                "yellow": "#c0a36e",
                "orange": "#c17158",
                "green": "#76946a",
                "cyan": "#6a9589",
                "blue": "#7e9cd8",
                "magenta": "#957fb8",
                "brown": "#60382c",
                "bright_red": "#e82424",
                "bright_yellow": "#e6c384",
                "bright_green": "#98bb6c",
                "bright_cyan": "#7aa89f",
                "bright_blue": "#7fb4ca",
                "bright_magenta": "#938aa9",
                "id": "kanagawa",
                "name": "Kanagawa",
                "mantle": "#17171e",
                "crust": "#111116",
                "surface": "#223249",
                "overlay": "#54546D",
                "urgent": "#c34043",
                "peach": "#c17158"
        },
        {
                "mode": "dark",
                "accent": "#bd93f9",
                "selection": "#44475a",
                "muted": "#6272a4",
                "background": "#282a36",
                "dark_background": "#21222c",
                "darker_background": "#191a21",
                "lighter_background": "#343746",
                "foreground": "#f8f8f2",
                "dark_foreground": "#6272a4",
                "light_foreground": "#f8f8f2",
                "bright_foreground": "#ffffff",
                "red": "#ff5555",
                "yellow": "#f1fa8c",
                "orange": "#ffb86c",
                "green": "#50fa7b",
                "cyan": "#8be9fd",
                "blue": "#bd93f9",
                "magenta": "#ff79c6",
                "brown": "#d6acff",
                "bright_red": "#ff6e6e",
                "bright_yellow": "#ffffa5",
                "bright_green": "#69ff94",
                "bright_cyan": "#a4ffff",
                "bright_blue": "#d6acff",
                "bright_magenta": "#ff92df",
                "id": "dracula",
                "name": "Dracula",
                "mantle": "#21222c",
                "crust": "#191a21",
                "surface": "#343746",
                "overlay": "#6272a4",
                "urgent": "#ff5555",
                "peach": "#ffb86c"
        },
        {
                "mode": "light",
                "accent": "#56949f",
                "selection": "#dfdad9",
                "muted": "#cecacd",
                "background": "#faf4ed",
                "dark_background": "#ede7e1",
                "darker_background": "#e1dbd5",
                "lighter_background": "#f2e9e1",
                "foreground": "#575279",
                "dark_foreground": "#9893a5",
                "light_foreground": "#6e6a86",
                "bright_foreground": "#575279",
                "red": "#b4637a",
                "yellow": "#ea9d34",
                "orange": "#cf8057",
                "green": "#286983",
                "cyan": "#d7827e",
                "blue": "#56949f",
                "magenta": "#907aa9",
                "brown": "#67402b",
                "bright_red": "#b4637a",
                "bright_yellow": "#ea9d34",
                "bright_green": "#286983",
                "bright_cyan": "#d7827e",
                "bright_blue": "#56949f",
                "bright_magenta": "#907aa9",
                "id": "rose-pine",
                "name": "Rose Pine",
                "mantle": "#ede7e1",
                "crust": "#e1dbd5",
                "surface": "#f2e9e1",
                "overlay": "#cecacd",
                "urgent": "#b4637a",
                "peach": "#cf8057"
        },
        {
                "mode": "dark",
                "accent": "#7fbbb3",
                "selection": "#3d484d",
                "muted": "#475258",
                "background": "#2d353b",
                "dark_background": "#21272c",
                "darker_background": "#181d20",
                "lighter_background": "#343f44",
                "foreground": "#d3c6aa",
                "dark_foreground": "#4f585e",
                "light_foreground": "#9da9a0",
                "bright_foreground": "#d3c6aa",
                "red": "#e67e80",
                "yellow": "#dbbc7f",
                "orange": "#e09d7f",
                "green": "#a7c080",
                "cyan": "#83c092",
                "blue": "#7fbbb3",
                "magenta": "#d699b6",
                "brown": "#704e3f",
                "bright_red": "#e67e80",
                "bright_yellow": "#dbbc7f",
                "bright_green": "#a7c080",
                "bright_cyan": "#83c092",
                "bright_blue": "#7fbbb3",
                "bright_magenta": "#d699b6",
                "id": "everforest",
                "name": "Everforest",
                "mantle": "#21272c",
                "crust": "#181d20",
                "surface": "#343f44",
                "overlay": "#475258",
                "urgent": "#e67e80",
                "peach": "#e09d7f"
        },
        {
                "mode": "dark",
                "accent": "#509475",
                "selection": "#32473B",
                "muted": "#53685B",
                "background": "#111c18",
                "dark_background": "#0c1512",
                "darker_background": "#090f0d",
                "lighter_background": "#23372B",
                "foreground": "#C1C497",
                "dark_foreground": "#81B8A8",
                "light_foreground": "#D6D5BC",
                "bright_foreground": "#F7E8B2",
                "red": "#FF5345",
                "yellow": "#459451",
                "orange": "#a2734b",
                "green": "#549e6a",
                "cyan": "#2DD5B7",
                "blue": "#509475",
                "magenta": "#D2689C",
                "brown": "#513925",
                "bright_red": "#db9f9c",
                "bright_yellow": "#E5C736",
                "bright_green": "#63b07a",
                "bright_cyan": "#8CD3CB",
                "bright_blue": "#ACD4CF",
                "bright_magenta": "#75bbb3",
                "id": "osaka-jade",
                "name": "Osaka Jade",
                "mantle": "#0c1512",
                "crust": "#090f0d",
                "surface": "#23372B",
                "overlay": "#53685B",
                "urgent": "#FF5345",
                "peach": "#a2734b"
        },
        {
                "mode": "dark",
                "accent": "#faa968",
                "selection": "#134e5a",
                "muted": "#2a6b78",
                "background": "#05182e",
                "dark_background": "#031222",
                "darker_background": "#020c17",
                "lighter_background": "#0a2540",
                "foreground": "#f6dcac",
                "dark_foreground": "#3f8f8a",
                "light_foreground": "#a7c9c6",
                "bright_foreground": "#f6dcac",
                "red": "#f85525",
                "yellow": "#e97b3c",
                "orange": "#faa968",
                "green": "#028391",
                "cyan": "#8cbfb8",
                "blue": "#3f8f8a",
                "magenta": "#3f8f8a",
                "brown": "#743d1e",
                "bright_red": "#f85525",
                "bright_yellow": "#e97b3c",
                "bright_green": "#028391",
                "bright_cyan": "#8cbfb8",
                "bright_blue": "#faa968",
                "bright_magenta": "#3f8f8a",
                "id": "retro-82",
                "name": "Retro 82",
                "mantle": "#031222",
                "crust": "#020c17",
                "surface": "#0a2540",
                "overlay": "#2a6b78",
                "urgent": "#f85525",
                "peach": "#faa968"
        },
        {
                "mode": "dark",
                "accent": "#798186",
                "selection": "#343d41",
                "muted": "#4b4e55",
                "background": "#101315",
                "dark_background": "#0c0e10",
                "darker_background": "#080a0b",
                "lighter_background": "#101315",
                "foreground": "#cacccc",
                "dark_foreground": "#4b4e55",
                "light_foreground": "#cbc2be",
                "bright_foreground": "#a5aeb4",
                "hyprland_active_border": "#rgba(798186ee) rgba(caccccee)",
                "hyprland_inactive_border": "#rgb(1e1e1e)",
                "active_border_color": "#a8adb0",
                "active_tab_background": "#798186",
                "red": "#565d60",
                "yellow": "#d9dbdc",
                "green": "#9fa5a9",
                "cyan": "#707070",
                "blue": "#798186",
                "magenta": "#aeaeae",
                "bright_red": "#de6145",
                "bright_yellow": "#c9c2b4",
                "bright_green": "#343d41",
                "bright_cyan": "#707070",
                "bright_blue": "#5d6367",
                "bright_magenta": "#9a9a9a",
                "id": "solitude",
                "name": "Solitude",
                "orange": "#fab387",
                "brown": "#af7d7d",
                "mantle": "#0c0e10",
                "crust": "#080a0b",
                "surface": "#101315",
                "overlay": "#4b4e55",
                "urgent": "#565d60",
                "peach": "#fab387"
        },
        {
                "mode": "dark",
                "accent": "#e68e0d",
                "selection": "#2a2a2a",
                "muted": "#333333",
                "background": "#121212",
                "dark_background": "#0d0d0d",
                "darker_background": "#090909",
                "lighter_background": "#1e1e1e",
                "foreground": "#bebebe",
                "dark_foreground": "#555555",
                "light_foreground": "#8a8a8d",
                "bright_foreground": "#bebebe",
                "red": "#D35F5F",
                "yellow": "#b91c1c",
                "orange": "#c63d3d",
                "green": "#FFC107",
                "cyan": "#bebebe",
                "blue": "#e68e0d",
                "magenta": "#D35F5F",
                "brown": "#631e1e",
                "bright_red": "#B91C1C",
                "bright_yellow": "#b90a0a",
                "bright_green": "#FFC107",
                "bright_cyan": "#eaeaea",
                "bright_blue": "#f59e0b",
                "bright_magenta": "#B91C1C",
                "id": "matte-black",
                "name": "Matte Black",
                "mantle": "#0d0d0d",
                "crust": "#090909",
                "surface": "#1e1e1e",
                "overlay": "#333333",
                "urgent": "#D35F5F",
                "peach": "#c63d3d"
        },
        {
                "mode": "dark",
                "accent": "#78824b",
                "selection": "#383838",
                "muted": "#666666",
                "background": "#222222",
                "dark_background": "#191919",
                "darker_background": "#121212",
                "lighter_background": "#2c2c2c",
                "foreground": "#c2c2b0",
                "dark_foreground": "#555555",
                "light_foreground": "#8a8a7e",
                "bright_foreground": "#c2c2b0",
                "red": "#685742",
                "yellow": "#b36d43",
                "orange": "#8d6242",
                "green": "#5f875f",
                "cyan": "#c9a554",
                "blue": "#78824b",
                "magenta": "#bb7744",
                "brown": "#463121",
                "bright_red": "#685742",
                "bright_yellow": "#b36d43",
                "bright_green": "#5f875f",
                "bright_cyan": "#c9a554",
                "bright_blue": "#78824b",
                "bright_magenta": "#bb7744",
                "id": "miasma",
                "name": "Miasma",
                "mantle": "#191919",
                "crust": "#121212",
                "surface": "#2c2c2c",
                "overlay": "#666666",
                "urgent": "#685742",
                "peach": "#8d6242"
        },
        {
                "mode": "dark",
                "accent": "#8bc9eb",
                "selection": "#243d56",
                "muted": "#304860",
                "background": "#16242d",
                "dark_background": "#101b21",
                "darker_background": "#0b1216",
                "lighter_background": "#1b2d40",
                "foreground": "#d6e2ee",
                "dark_foreground": "#4d86b0",
                "light_foreground": "#d6e2ee",
                "bright_foreground": "#f2fcff",
                "active_border_color": "#f2fcff",
                "active_tab_background": "#6fb8e3",
                "red": "#4d86b0",
                "yellow": "#6fa4c9",
                "orange": "#8bc9eb",
                "green": "#5e95bc",
                "cyan": "#b4e4f6",
                "blue": "#6fb8e3",
                "magenta": "#8bc9eb",
                "brown": "#456475",
                "bright_red": "#73a6cb",
                "bright_yellow": "#9dcae5",
                "bright_green": "#86b7d8",
                "bright_cyan": "#d1eef8",
                "bright_blue": "#f2fcff",
                "bright_magenta": "#b1d8ee",
                "id": "lumon",
                "name": "Lumon",
                "mantle": "#101b21",
                "crust": "#0b1216",
                "surface": "#1b2d40",
                "overlay": "#304860",
                "urgent": "#4d86b0",
                "peach": "#8bc9eb"
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
        Quickshell.execDetached([applyHelper, JSON.stringify(pal)]);
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
