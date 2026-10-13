import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

// Iris: the floating island at the top centre of the main monitor.
// Small by default; it grows only when something needs you, then gets out of the way.
//
// What it shows, most important first:
//   notification  one line and one button (only when the shell handles notifications)
//   volume        for a moment after the volume changes
//   mode          for a moment after switching mode (Win+M)
//   activity      a live activity sent over IPC (renders, sims, downloads)
//   media         while something is playing
//   idle          your columns and the time
PanelWindow {
    id: iris

    screen: Config.irisScreenObject

    anchors.top: true
    implicitWidth: 480
    implicitHeight: Theme.irisTop + Theme.irisExpandedHeight + 28   // room for the shadow
    exclusiveZone: Theme.irisTop + Theme.irisHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "matte-iris"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Only the pill takes clicks; the rest of the window lets them through.
    mask: Region { item: pill }

    // ---------------------------------------------------------------- state

    property string transient: ""            // "volume" or "mode" while shown
    property var notification: null
    property string activityTitle: ""
    property string activityDetail: ""
    property real activityProgress: -1

    readonly property string view: {
        if (notification !== null)
            return "notification";
        if (transient !== "")
            return transient;
        if (activityTitle !== "")
            return "activity";
        if (Media.active)
            return "media";
        return "idle";
    }

    readonly property var current: ({
        idle: idle, media: media, activity: activity, volume: volume, mode: mode, notification: note
    })[view]

    function flash(kind, ms) {
        iris.transient = kind;
        transientTimer.interval = ms;
        transientTimer.restart();
    }

    function setActivity(title, detail, progress) {
        iris.activityTitle = title;
        iris.activityDetail = detail;
        iris.activityProgress = progress;
    }

    function showNotification(n) {
        iris.notification = n;
        const timeout = n && n.expireTimeout > 0 ? Math.min(n.expireTimeout, 10000) : 6000;
        notificationTimer.interval = timeout;
        notificationTimer.restart();
    }

    Timer {
        id: transientTimer
        onTriggered: iris.transient = ""
    }

    Timer {
        id: notificationTimer
        running: false
        onTriggered: iris.notification = null
    }

    Connections {
        target: Audio
        function onAdjusted() { iris.flash("volume", 1600); }
    }

    Connections {
        target: Mode
        function onSwitched() { iris.flash("mode", 2200); }
    }

    Connections {
        target: Notifications
        function onArrived(n) { iris.showNotification(n); }
    }

    // ---------------------------------------------------------------- the pill

    Rectangle {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.irisTop
        width: Math.max(150, iris.current ? iris.current.implicitWidth : 150)
        height: iris.view === "notification" ? Theme.irisExpandedHeight : Theme.irisHeight
        radius: iris.view === "notification" ? 26 : height / 2
        color: Theme.glass
        border.color: Theme.hairline
        border.width: 1

        Behavior on width {
            NumberAnimation { duration: Theme.morphMs; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: Theme.morphMs; easing.type: Easing.OutCubic }
        }
        Behavior on radius {
            NumberAnimation { duration: Theme.morphMs; easing.type: Easing.OutCubic }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowBlur: 0.7
            shadowVerticalOffset: 8
        }

        Item {
            anchors.fill: parent
            clip: true

            IrisIdle {
                id: idle
                anchors.fill: parent
                output: iris.screen?.name ?? ""
                opacity: iris.view === "idle" ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Theme.fadeMs } }
            }

            IrisMedia {
                id: media
                anchors.fill: parent
                opacity: iris.view === "media" ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Theme.fadeMs } }
            }

            IrisActivity {
                id: activity
                anchors.fill: parent
                title: iris.activityTitle
                detail: iris.activityDetail
                progress: iris.activityProgress
                opacity: iris.view === "activity" ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Theme.fadeMs } }
            }

            IrisVolume {
                id: volume
                anchors.fill: parent
                opacity: iris.view === "volume" ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Theme.fadeMs } }
            }

            IrisMode {
                id: mode
                anchors.fill: parent
                opacity: iris.view === "mode" ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Theme.fadeMs } }
            }

            IrisNotification {
                id: note
                anchors.fill: parent
                notification: iris.notification
                opacity: iris.view === "notification" ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Theme.fadeMs } }
                onDone: iris.notification = null
            }
        }

        // Left click opens the control centre (DMS's, until Matte OS has its own),
        // right click toggles niri's overview, the wheel changes the volume.
        // Sits under the contents, so buttons inside the pill still get their clicks.
        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            onEntered: notificationTimer.running && notificationTimer.stop()
            onExited: if (iris.notification !== null) notificationTimer.restart()
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    Niri.action("toggle-overview");
                else if (iris.view === "media")
                    Media.toggle();
                else
                    Quickshell.execDetached(["dms", "ipc", "call", "control-center", "toggle"]);
            }
            onWheel: wheel => {
                const audio = Audio.sink?.audio;
                if (!audio)
                    return;
                const step = wheel.angleDelta.y > 0 ? 0.03 : -0.03;
                audio.volume = Math.max(0, Math.min(1, audio.volume + step));
            }
        }
    }
}
