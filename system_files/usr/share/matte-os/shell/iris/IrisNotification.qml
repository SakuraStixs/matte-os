import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.common

// A notification: one line, one button. Clicking the body dismisses it.
Item {
    id: root

    property var notification: null
    signal done()

    readonly property var mainAction: {
        const actions = notification?.actions ?? [];
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default")
                return actions[i];
        }
        return actions.length > 0 ? actions[0] : null;
    }
    readonly property string iconSource: {
        const icon = notification?.image || notification?.appIcon || "";
        if (icon === "")
            return "";
        return icon.startsWith("/") || icon.startsWith("file:") || icon.startsWith("image:") ? icon : Quickshell.iconPath(icon, true);
    }

    implicitWidth: 420

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.notification?.dismiss();
            root.done();
        }
    }

    Row {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        spacing: 12

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: 17
            color: Theme.accentSoft
            clip: true

            IconImage {
                anchors.centerIn: parent
                implicitSize: 20
                visible: root.iconSource !== ""
                source: root.iconSource
            }

            Icon {
                anchors.centerIn: parent
                visible: root.iconSource === ""
                size: 16
                color: Theme.accent
                path: Icons.check
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 34 - (button.visible ? button.width + parent.spacing : 0) - parent.spacing
            spacing: 1

            Label {
                width: parent.width
                font.pixelSize: 14
                font.weight: Font.DemiBold
                text: root.notification?.summary ?? ""
            }

            Label {
                width: parent.width
                muted: true
                textFormat: Text.PlainText
                text: {
                    const n = root.notification;
                    if (!n)
                        return "";
                    const body = (n.body ?? "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim();
                    return body !== "" ? n.appName + " · " + body : n.appName;
                }
            }
        }

        Rectangle {
            id: button
            anchors.verticalCenter: parent.verticalCenter
            visible: root.mainAction !== null
            width: buttonLabel.implicitWidth + 32
            height: 32
            radius: 16
            color: buttonArea.containsMouse ? Theme.buttonHover : Theme.button

            Label {
                id: buttonLabel
                anchors.centerIn: parent
                text: root.mainAction?.text || "Open"
            }

            MouseArea {
                id: buttonArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    root.mainAction?.invoke();
                    root.done();
                }
            }
        }
    }
}
