// Iris notifications: the newest one drops in under the island for a few seconds.
// Click it to dismiss. Skeleton v0: one at a time, no history yet.

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick

Scope {
    id: root
    property var current: null

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: false
        imageSupported: false
        onNotification: n => {
            n.tracked = true;
            root.current = n;
            hide.interval = n.urgency === NotificationUrgency.Critical ? 12000 : 5000;
            hide.restart();
        }
    }

    Timer {
        id: hide
        onTriggered: root.current = null
    }

    Variants {
        model: Theme.mainScreens()

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.current !== null
            anchors.top: true
            margins.top: 56
            exclusiveZone: 0
            color: "transparent"
            implicitWidth: 480
            implicitHeight: 68

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Theme.glass
                border.color: Theme.edge
                border.width: 1

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    spacing: 16

                    // a small white planet stands in for the app icon for now
                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: Theme.accent
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text {
                            text: root.current ? root.current.appName.toUpperCase() : ""
                            color: Theme.muted
                            font.family: Theme.sans
                            font.pixelSize: 12
                            font.letterSpacing: 1.6
                        }
                        Text {
                            text: root.current ? root.current.summary : ""
                            color: Theme.fg
                            font.family: Theme.sans
                            font.pixelSize: 15
                            elide: Text.ElideRight
                            width: 380
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.current) root.current.dismiss();
                        root.current = null;
                    }
                }
            }
        }
    }
}
