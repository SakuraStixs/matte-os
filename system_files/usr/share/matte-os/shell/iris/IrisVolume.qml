import QtQuick
import qs.common
import qs.services

// Volume: shown for a moment whenever the output volume changes.
Item {
    implicitWidth: 220

    Row {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            size: 14
            color: Theme.muted
            path: Audio.muted ? Icons.speakerMuted : Icons.speaker
        }

        Meter {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 14 - percent.width - 2 * parent.spacing
            fillColor: Theme.fill
            value: Audio.muted ? 0 : Audio.volume
        }

        Label {
            id: percent
            anchors.verticalCenter: parent.verticalCenter
            muted: true
            width: 22
            horizontalAlignment: Text.AlignRight
            text: Math.round((Audio.muted ? 0 : Audio.volume) * 100)
        }
    }
}
