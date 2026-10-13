import QtQuick
import Quickshell
import qs.common
import qs.services

// Idle: one dot per column on this monitor's workspace (the focused one in sky blue), and the time.
Item {
    id: root

    property string output: ""
    readonly property var columns: Niri.columnsOn(output)
    readonly property int shown: Math.max(1, Math.min(columns.columns, 7))

    implicitWidth: row.implicitWidth + 32

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 14

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Repeater {
                model: root.shown

                Rectangle {
                    required property int index
                    width: 5
                    height: 5
                    radius: 3
                    color: index === Math.min(root.columns.focusedColumn, root.shown - 1) ? Theme.accent : Theme.dot

                    Behavior on color {
                        ColorAnimation { duration: 140 }
                    }
                }
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(clock.date, Config.clock24h ? "HH:mm" : "h:mm AP")
        }
    }
}
