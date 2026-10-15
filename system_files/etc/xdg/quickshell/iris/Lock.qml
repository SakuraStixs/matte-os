// Iris lock screen. Lock with:  qs -c iris ipc call lock lock   (Win+L in niri)
// Same wallpaper, an orbit clock, and a password field. Skeleton v0.
//
// Note: if Iris crashes while the screen is locked, the compositor keeps it locked.
// Recover from a text console (Ctrl+Alt+F3): log in and run  pkill qs  then  qs -c iris
// or use the "Niri (DMS fallback)" session.

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root
    property string typed: ""
    property string pending: ""
    property string status: ""
    property bool busy: false

    SystemClock {
        id: lockClock
        precision: SystemClock.Seconds
    }

    function submit() {
        if (busy || typed.length === 0) return;
        pending = typed;
        busy = true;
        status = "";
        pam.start();
    }

    PamContext {
        id: pam
        config: "iris-lock"
        onPamMessage: {
            if (responseRequired) respond(root.pending);
        }
        onCompleted: result => {
            root.busy = false;
            root.typed = "";
            root.pending = "";
            if (result === PamResult.Success) session.locked = false;
            else root.status = "That is not the password";
        }
        onError: err => {
            root.busy = false;
            root.status = "Could not check the password";
        }
    }

    WlSessionLock {
        id: session
        onLockedChanged: {
            if (locked) {
                root.typed = "";
                root.status = "";
            }
        }

        WlSessionLockSurface {
            id: surface
            color: Theme.bg

            readonly property var b: Theme.bounds()
            readonly property bool isMain: Theme.mainScreens().length > 0 && Theme.mainScreens()[0] === screen

            Image {
                source: Theme.wallpaper
                asynchronous: true
                smooth: true
                fillMode: surface.b.count > 1 ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                width: surface.b.count > 1 ? surface.b.w : surface.width
                height: surface.b.count > 1 ? surface.b.h : surface.height
                x: surface.b.count > 1 ? surface.b.x - screen.x : 0
                y: surface.b.count > 1 ? surface.b.y - screen.y : 0
            }

            Rectangle { anchors.fill: parent; color: "#33000000" }

            // Keyboard input: every surface has an invisible field so typing works
            // whichever monitor the compositor gives focus to.
            TextInput {
                id: input
                width: 1; height: 1; opacity: 0
                focus: true
                echoMode: TextInput.Password
                text: root.typed
                onTextEdited: root.typed = text
                onAccepted: root.submit()
                Keys.onEscapePressed: root.typed = ""
                Component.onCompleted: forceActiveFocus()
            }

            // Everything below shows on the main monitor only.
            Item {
                anchors.fill: parent
                visible: surface.isMain

                // Orbit clock: hour = ringed planet on the inner orbit, minute = planet on the outer one
                Item {
                    id: orbit
                    x: parent.width * 0.78
                    y: parent.height * 0.64

                    Rectangle { x: -300; y: -300; width: 600; height: 600; radius: 300; color: "transparent"; border.color: "#3DF2F2F2"; border.width: 1 }
                    Rectangle { x: -190; y: -190; width: 380; height: 380; radius: 190; color: "transparent"; border.color: "#3DF2F2F2"; border.width: 1 }

                    Rectangle {
                        readonly property real a: ((lockClock.hours % 12) + lockClock.minutes / 60) * 30 * Math.PI / 180 - Math.PI / 2
                        width: 28; height: 28; radius: 14; color: Theme.accent
                        x: Math.cos(a) * 190 - 14
                        y: Math.sin(a) * 190 - 14
                    }
                    Rectangle {
                        readonly property real a: (lockClock.minutes + lockClock.seconds / 60) * 6 * Math.PI / 180 - Math.PI / 2
                        width: 18; height: 18; radius: 9; color: Theme.accent
                        x: Math.cos(a) * 300 - 9
                        y: Math.sin(a) * 300 - 9
                    }
                    Rectangle {
                        readonly property real a: lockClock.seconds * 6 * Math.PI / 180 - Math.PI / 2
                        width: 6; height: 6; radius: 3; color: Theme.muted
                        x: Math.cos(a) * 360 - 3
                        y: Math.sin(a) * 360 - 3
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(lockClock.date, "HH:mm")
                            color: Theme.fg
                            font.family: Theme.serif
                            font.pixelSize: 120
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(lockClock.date, "dddd d MMMM").toUpperCase()
                            color: Theme.muted
                            font.family: Theme.sans
                            font.pixelSize: 14
                            font.letterSpacing: 2.4
                        }
                    }
                }

                // Password field, bottom left
                Column {
                    x: 96
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 112
                    spacing: 14

                    Rectangle {
                        width: 420; height: 58; radius: 29
                        color: "#C70A0A0A"
                        border.color: "#52F2F2F2"
                        border.width: 1

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 24
                            text: root.typed.length > 0 ? "•".repeat(root.typed.length) : "Type your password"
                            color: root.typed.length > 0 ? Theme.fg : Theme.dim
                            font.family: Theme.sans
                            font.pixelSize: root.typed.length > 0 ? 22 : 18
                            font.letterSpacing: root.typed.length > 0 ? 5 : 0.5
                        }
                    }
                    Text {
                        text: root.busy ? "Checking..." : root.status
                        color: Theme.muted
                        font.family: Theme.sans
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            session.locked = true;
        }
    }
}
