import QtQuick
import qs.common
import qs.services

// Media: what's playing, with a play/pause button.
Item {
    id: root

    implicitWidth: Math.max(230, Math.min(340, track.implicitWidth + 16 + 6 + 26 + 10))

    Label {
        id: track
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: button.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: Media.artist ? Media.title + "  ·  " + Media.artist : Media.title
    }

    Rectangle {
        id: button
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        radius: 13
        color: buttonArea.containsMouse ? Theme.button : "transparent"

        Icon {
            anchors.centerIn: parent
            size: 12
            filled: true
            color: Theme.text
            path: Media.player?.isPlaying ? Icons.pause : Icons.play
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Media.toggle()
        }
    }
}
