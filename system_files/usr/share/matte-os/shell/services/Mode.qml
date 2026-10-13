pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The current Matte OS mode (normal, vfx, game, focus), as set by `matte-mode`.
Singleton {
    id: root

    property string mode: "normal"
    readonly property string title: ({ normal: "Normal", vfx: "VFX", game: "Game", focus: "Focus" })[mode] ?? mode

    signal switched()

    function set(name) {
        Quickshell.execDetached(["matte-mode", "set", name]);
    }

    function cycle() {
        Quickshell.execDetached(["matte-mode", "cycle"]);
    }

    FileView {
        id: file
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/matte-os/mode"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const next = text().trim() || "normal";
            if (next !== root.mode) {
                root.mode = next;
                root.switched();
            }
        }
    }

    // The file only exists after the first switch; check now and then until it does.
    Timer {
        interval: 3000
        repeat: true
        running: !file.loaded
        onTriggered: file.reload()
    }
}
