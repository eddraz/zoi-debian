//@ pragma Env QS_NO_RELOAD_POPUP=1
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import "Commons"

ShellRoot {
    Bar {}

    Instantiator {
        model: PluginRegistry.hostIds
        delegate: Loader {
            required property var modelData
            source: PluginRegistry.hostUrl(String(modelData))
        }
    }
}
