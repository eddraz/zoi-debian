//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import "Commons"

// Waybar owns the strip. Quickshell keeps overlays/services (launcher,
// notifications, lock, clipboard, OSD, emojis, polkit, …).
ShellRoot {
    readonly property string _bootTheme: Themes.currentId
    readonly property bool _bootWeather: Weather.ready

    Instantiator {
        model: PluginRegistry.hostIds
        delegate: Loader {
            required property var modelData
            source: PluginRegistry.hostUrl(String(modelData))
        }
    }
}
