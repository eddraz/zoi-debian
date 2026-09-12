//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import "Commons"

ShellRoot {
    // Force-instantiate Themes at boot. Color.qml paints from colors.json, but
    // the ThemePanel selector reads Themes.currentId; without this the singleton
    // only appeared after opening Session → Theme or Lock pulling Wallpaper.
    readonly property string _bootTheme: Themes.currentId

    Bar {}

    Instantiator {
        model: PluginRegistry.hostIds
        delegate: Loader {
            required property var modelData
            source: PluginRegistry.hostUrl(String(modelData))
        }
    }
}
