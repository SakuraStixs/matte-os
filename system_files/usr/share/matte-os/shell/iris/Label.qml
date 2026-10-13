import QtQuick
import qs.common

// Text in the shell's typeface; secondary text sets `muted: true`.
Text {
    property bool muted: false

    color: muted ? Theme.muted : Theme.text
    font.family: Theme.font
    font.pixelSize: muted ? 12 : 13
    font.weight: muted ? Font.Normal : Font.Medium
    elide: Text.ElideRight
    maximumLineCount: 1
    verticalAlignment: Text.AlignVCenter
}
