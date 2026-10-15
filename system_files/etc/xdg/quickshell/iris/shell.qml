// Iris: Matte OS's shell. Skeleton v0: wallpaper, island (workspaces + time), notifications, lock screen.
//
// Run:      qs -c iris
// Develop:  copy this folder to ~/.config/quickshell/iris and edit it there.
//           Quickshell reloads whenever you save, and your copy overrides this one.
// Test:     qs -c iris ipc call island ping
// Lock:     qs -c iris ipc call lock lock

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Notifications {}
    Lock {}

    // Wallpaper: one picture stretched across all monitors side by side
    // (the default is 3840x1080: one half per 1920x1080 monitor).
    // With a single monitor it is shown whole on the same near-black background instead of cropped.
    Variants {
        model: Theme.screenList()

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "iris-wallpaper"
            color: Theme.bg

            Image {
                readonly property var b: Theme.bounds()
                source: Theme.wallpaper
                asynchronous: true
                smooth: true
                fillMode: b.count > 1 ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                width: b.count > 1 ? b.w : parent.width
                height: b.count > 1 ? b.h : parent.height
                x: b.count > 1 ? b.x - modelData.x : 0
                y: b.count > 1 ? b.y - modelData.y : 0
            }
        }
    }

    // The island shows on the main monitor only: the rightmost screen.
    // Later this becomes a setting.
    Variants {
        model: Theme.mainScreens()

        PanelWindow {
            id: island
            required property var modelData
            screen: modelData

            // Only "top" is anchored, so the layer-shell centres the island horizontally.
            anchors.top: true
            margins.top: 8
            exclusiveZone: 0
            color: "transparent"
            implicitWidth: content.implicitWidth + 36
            implicitHeight: 36

            property var workspaces: []

            // Ask niri for the workspace list once a second.
            // TODO: switch to `niri msg -j event-stream` so it updates instantly.
            Process {
                id: wsQuery
                command: ["niri", "msg", "-j", "workspaces"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            const all = JSON.parse(text);
                            island.workspaces = all
                                .filter(w => w.output === island.screen.name)
                                .sort((a, b) => a.idx - b.idx);
                        } catch (e) {
                            island.workspaces = [];
                        }
                    }
                }
            }
            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: wsQuery.running = true
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Theme.glass
                border.color: Theme.edge
                border.width: 1

                Row {
                    id: content
                    anchors.centerIn: parent
                    spacing: 14

                    // Workspace dots: the focused one is the accent colour and longer.
                    Row {
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: island.workspaces
                            Rectangle {
                                required property var modelData
                                width: modelData.is_focused ? 18 : 7
                                height: 7
                                radius: 3.5
                                color: modelData.is_focused ? Theme.accent : Theme.dim
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Theme.fg
                        font.family: Theme.sans
                        font.pixelSize: 14
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }

    // Lets you check from a terminal that Iris is running.
    IpcHandler {
        target: "island"
        function ping(): string {
            return "iris is alive";
        }
    }
}
