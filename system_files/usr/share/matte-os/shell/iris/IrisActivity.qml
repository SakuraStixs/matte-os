import QtQuick
import qs.common

// Live activity: something long-running (a render, a sim, a download) with its progress.
// Driven over IPC, e.g.: qs -p /usr/share/matte-os/shell ipc call iris activity "Rendering" "112 / 240" 0.47
Item {
    id: root

    property string title: ""
    property string detail: ""
    property real progress: -1     // 0..1, or -1 when unknown

    implicitWidth: 280

    Row {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 10

        Label {
            id: titleLabel
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            width: Math.min(implicitWidth, 120)
        }

        Label {
            id: detailLabel
            anchors.verticalCenter: parent.verticalCenter
            muted: true
            text: root.detail
            width: Math.min(implicitWidth, 70)
        }

        Item {
            width: parent.width - titleLabel.width - detailLabel.width - 2 * parent.spacing
            height: parent.height

            Meter {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 80
                visible: root.progress >= 0
                value: root.progress
            }
        }
    }
}
