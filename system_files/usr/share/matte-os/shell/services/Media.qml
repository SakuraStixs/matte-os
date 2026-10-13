pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player Iris should show: the one playing, otherwise the first one around.
Singleton {
    id: root

    readonly property var player: {
        const players = Mpris.players.values;
        let first = null;
        for (let i = 0; i < players.length; i++) {
            if (players[i].isPlaying)
                return players[i];
            if (first === null)
                first = players[i];
        }
        return first;
    }

    readonly property bool active: player !== null && player.isPlaying
    readonly property string title: player?.trackTitle || player?.identity || ""
    readonly property string artist: player?.trackArtist || ""

    function toggle() {
        if (player && player.canTogglePlaying)
            player.togglePlaying();
    }
}
