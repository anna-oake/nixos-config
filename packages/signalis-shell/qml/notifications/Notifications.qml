import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.config
import qs.services

// Notification daemon. Popups stack under the bar on the focused output.
Scope {
    id: root

    NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notification => {
            notification.tracked = true;
        }
    }

    PanelWindow {
        visible: server.trackedNotifications.values.length > 0
        screen: {
            const focused = Niri.workspaces.find(w => w.is_focused);
            return Quickshell.screens.find(s => s.name === focused?.output) ?? Quickshell.screens[0];
        }

        anchors {
            top: true
            right: true
        }
        margins {
            top: 10
            right: 10
        }
        implicitWidth: 380
        implicitHeight: stack.implicitHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "signalis-notifications"

        Column {
            id: stack
            width: parent.width
            spacing: 10

            Repeater {
                model: server.trackedNotifications

                Popup {
                    required property Notification modelData
                    notification: modelData
                    width: stack.width
                }
            }
        }
    }
}
