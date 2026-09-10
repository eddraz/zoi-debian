pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import "Commons"

Scope {
    Process {
        running: NightLight.enabled
        command: ["wlsunset", "-t", "4000", "-T", "4000", "-S", "23:59", "-s", "00:00"]
    }
}
