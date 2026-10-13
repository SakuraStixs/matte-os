pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.common

// Notifications for Iris. Off by default while DankMaterialShell is the everyday shell, because
// only one program can receive notifications; turn on with "notifications": true in shell.json.
Singleton {
    id: root

    property var latest: null
    signal arrived(var notification)

    LazyLoader {
        active: Config.notifications

        NotificationServer {
            keepOnReload: false
            actionsSupported: true
            bodySupported: true
            imageSupported: true

            onNotification: notification => {
                notification.tracked = true;
                root.latest = notification;
                root.arrived(notification);
            }
        }
    }
}
