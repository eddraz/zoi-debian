pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string requested: ""
    property bool isSearching: false
    signal closed

    function closeAll() {
        requested = "";
        closed();
    }

    function toggle(name) {
        requested = requested === name ? "" : name;
    }

    function open(name) {
        requested = name;
    }

    IpcHandler {
        target: "session"

        function toggle(): string {
            root.toggle("session");
            return "ok";
        }

        function open(): string {
            root.open("session");
            return "ok";
        }
    }

    IpcHandler {
        target: "popups"

        function close(): string {
            root.closeAll();
            return "ok";
        }

        function closeAll(): string {
            root.closeAll();
            return "ok";
        }

        function toggle(name: string): string {
            if (!name)
                root.closeAll();
            else
                root.toggle(name);
            return "ok";
        }

        function open(name: string): string {
            if (name)
                root.open(name);
            return "ok";
        }
    }
}
