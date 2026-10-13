pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Per-user settings from ~/.config/matte-os/shell.json, reloaded live when the file changes:
//   {
//     "irisScreen": "DP-4",        // monitor that shows Iris; default: the leftmost one
//     "notifications": false,      // true = Iris shows notifications (turn off DMS's first)
//     "clock24h": true
//   }
Singleton {
    id: root

    property string irisScreen: ""
    property bool notifications: Quickshell.env("MATTE_SHELL_NOTIFICATIONS") === "1"
    property bool clock24h: true

    readonly property var irisScreenObject: {
        const screens = Quickshell.screens;
        let leftmost = null;
        for (let i = 0; i < screens.length; i++) {
            const s = screens[i];
            if (s.name === root.irisScreen)
                return s;
            if (leftmost === null || s.x < leftmost.x)
                leftmost = s;
        }
        return leftmost;
    }

    function apply(text) {
        let parsed = {};
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            console.warn("shell.json isn't valid JSON:", e);
            return;
        }
        root.irisScreen = parsed.irisScreen ?? "";
        root.notifications = parsed.notifications ?? (Quickshell.env("MATTE_SHELL_NOTIFICATIONS") === "1");
        root.clock24h = parsed.clock24h ?? true;
    }

    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/matte-os/shell.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.apply(text())
    }
}
