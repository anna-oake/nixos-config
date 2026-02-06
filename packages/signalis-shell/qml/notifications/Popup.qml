import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.components
import qs.config

// One notification, as a receiver transcript: app name on the tab, summary,
// body, then actions as outlined buttons.
Frame {
    id: root

    required property Notification notification

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property int timeout: critical ? 0 : (notification.expireTimeout > 0 ? notification.expireTimeout : 6000)
    property bool blinkOn: true

    label: notification.appName !== "" ? notification.appName : "Transkription"
    borderColor: critical ? Theme.red : (hover.containsMouse ? Theme.lineStrong : Theme.line)
    tabColor: critical ? (blinkOn ? Theme.red : Theme.redDark) : Theme.ink
    height: implicitHeight

    Timer {
        running: root.timeout > 0 && !hover.containsMouse
        interval: root.timeout
        onTriggered: root.notification.expire()
    }

    Timer {
        running: root.critical
        repeat: true
        interval: 500
        onTriggered: root.blinkOn = !root.blinkOn
    }

    MouseArea {
        id: hover
        width: root.width - root.padding * 2
        height: content.height
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            const fallback = Array.from(root.notification.actions).find(a => a.identifier === "default");
            if (mouse.button === Qt.LeftButton && fallback)
                fallback.invoke();
            else
                root.notification.dismiss();
        }
    }

    Row {
        id: content
        width: root.width - root.padding * 2
        spacing: 12

        IconImage {
            id: icon
            readonly property string source_: root.notification.image !== "" ? root.notification.image : (root.notification.appIcon !== "" ? Quickshell.iconPath(root.notification.appIcon, true) : "")
            visible: source_ !== ""
            source: source_
            implicitSize: 36
        }

        Column {
            width: parent.width - (icon.visible ? 48 : 0)
            spacing: 6

            Txt {
                width: parent.width
                text: root.notification.summary
                color: root.critical ? Theme.red : Theme.inkBright
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            Txt {
                visible: text !== ""
                width: parent.width
                text: root.notification.body
                textFormat: Text.StyledText
                color: Theme.soft
                linkColor: Theme.red
                wrapMode: Text.Wrap
                maximumLineCount: 6
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            Flow {
                visible: actions.count > 0
                width: parent.width
                spacing: 6

                Repeater {
                    id: actions
                    model: Array.from(root.notification.actions).filter(a => a.identifier !== "default")

                    Readout {
                        required property var modelData
                        value: modelData.text.toUpperCase()
                        frameColor: Theme.redBorder
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
