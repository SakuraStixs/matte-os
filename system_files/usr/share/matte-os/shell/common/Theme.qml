pragma Singleton

import QtQuick
import Quickshell

// Matte OS style guide in one place: dark glass, one sky-blue accent used only where it means something.
Singleton {
    readonly property color ink: "#050608"
    readonly property color glass: Qt.rgba(8 / 255, 9 / 255, 13 / 255, 0.88)
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.07)
    readonly property color text: "#E6E9EF"
    readonly property color muted: "#8B93A3"
    readonly property color accent: "#7DD3FC"
    readonly property color accentSoft: Qt.rgba(125 / 255, 211 / 255, 252 / 255, 0.12)
    readonly property color dot: Qt.rgba(1, 1, 1, 0.25)
    readonly property color track: Qt.rgba(1, 1, 1, 0.08)
    readonly property color fill: Qt.rgba(230 / 255, 233 / 255, 239 / 255, 0.8)
    readonly property color button: Qt.rgba(1, 1, 1, 0.08)
    readonly property color buttonHover: Qt.rgba(1, 1, 1, 0.14)
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.55)

    readonly property string font: "Plus Jakarta Sans"
    readonly property string mono: "JetBrains Mono"

    // Iris geometry: a 34 px pill, 12 px from the top edge
    readonly property int irisTop: 12
    readonly property int irisHeight: 34
    readonly property int irisExpandedHeight: 54

    // Motion: the pill morphs, its contents cross-fade
    readonly property int morphMs: 380
    readonly property int fadeMs: 160
}
