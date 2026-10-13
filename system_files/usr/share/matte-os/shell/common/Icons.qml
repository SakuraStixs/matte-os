pragma Singleton

import QtQuick
import Quickshell

// Path data for the few icons Iris uses (24 x 24 grid).
Singleton {
    readonly property string check: "M20 6 9 17l-5-5"
    readonly property string speaker: "M11 5 6 9H2v6h4l5 4z M15.5 8.5a5 5 0 0 1 0 7"
    readonly property string speakerMuted: "M11 5 6 9H2v6h4l5 4z M22 9l-6 6 M16 9l6 6"
    readonly property string pause: "M6 5h4v14H6z M14 5h4v14h-4z"
    readonly property string play: "M7 4v16l13-8z"
    readonly property string bell: "M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9 M10.3 21a1.94 1.94 0 0 0 3.4 0"
    readonly property string lock: "M5 11h14v10H5z M8 11V7a4 4 0 0 1 8 0v4"
}
