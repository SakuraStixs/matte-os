pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Output volume, so Iris can show the volume pill when it changes.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool ready: sink?.ready ?? false

    // Emitted for real changes only, not when the sink first appears or switches.
    signal adjusted()

    property bool _settled: false
    property real _lastVolume: -1
    property bool _lastMuted: false

    onSinkChanged: {
        root._settled = false;
        settle.restart();
    }
    onVolumeChanged: root._maybeEmit()
    onMutedChanged: root._maybeEmit()

    function _maybeEmit() {
        if (!root._settled)
            return;
        if (Math.abs(root.volume - root._lastVolume) < 0.005 && root.muted === root._lastMuted)
            return;
        root._lastVolume = root.volume;
        root._lastMuted = root.muted;
        root.adjusted();
    }

    Timer {
        id: settle
        interval: 800
        running: true
        onTriggered: {
            root._lastVolume = root.volume;
            root._lastMuted = root.muted;
            root._settled = true;
        }
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
