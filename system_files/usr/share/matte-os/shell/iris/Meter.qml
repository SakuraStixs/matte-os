import QtQuick
import qs.common

// A 3 px progress line: a faint track and a filled part (accent for progress, light grey for levels).
Item {
    property real value: 0
    property color fillColor: Theme.accent

    implicitHeight: 3

    Rectangle {
        anchors.fill: parent
        radius: 2
        color: Theme.track
    }

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, parent.value))
        height: parent.height
        radius: 2
        color: parent.fillColor

        Behavior on width {
            NumberAnimation { duration: 120 }
        }
    }
}
