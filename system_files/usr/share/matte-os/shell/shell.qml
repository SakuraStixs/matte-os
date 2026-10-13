//@ pragma AppId org.matteos.shell
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

// Matte OS shell (phase 2, in progress). Run it with `matte-shell`.
// Today it draws Iris; the launcher, control centre, lock screen and the rest follow
// (see "Before the own shell replaces DMS" in the Matte OS spec).

import QtQuick
import Quickshell
import Quickshell.Io
import qs.iris

ShellRoot {
    id: root

    Iris {
        id: iris
    }

    // Commands for scripts and keybinds:
    //   matte-shell ipc call iris activity "Rendering" "112 / 240" 0.47
    //   matte-shell ipc call iris clearActivity
    //   matte-shell ipc call iris demo
    IpcHandler {
        target: "iris"

        function activity(title: string, detail: string, progress: real): void {
            iris.setActivity(title, detail, progress);
        }

        function clearActivity(): void {
            iris.setActivity("", "", -1);
        }

        function flash(kind: string): void {
            iris.flash(kind, 2000);
        }

        // Walks through the states so you can see them all in a few seconds.
        function demo(): void {
            demoTimer.step = 0;
            demoTimer.restart();
        }
    }

    Timer {
        id: demoTimer
        property int step: 0
        interval: 1800
        repeat: true
        onTriggered: {
            switch (step++) {
            case 0: iris.flash("mode", 1600); break;
            case 1: iris.flash("volume", 1600); break;
            case 2: iris.setActivity("Rendering", "112 / 240", 0.47); break;
            case 3: iris.setActivity("Rendering", "240 / 240", 1); break;
            default: iris.setActivity("", "", -1); stop();
            }
        }
    }
}
