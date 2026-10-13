import QtQuick
import qs.common
import qs.services

// Mode: shown for a moment after switching between Normal, VFX, Game and Focus (Win+M).
Item {
    implicitWidth: Math.max(170, row.implicitWidth + 32)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: Mode.mode === "normal" ? Theme.dot : Theme.accent
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Mode.title + " mode"
        }
    }
}
