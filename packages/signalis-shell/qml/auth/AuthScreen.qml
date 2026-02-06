import QtQuick
import Quickshell
import qs.components
import qs.config

// Full-screen authorization terminal, shared by the lock screen and the greeter.
Rectangle {
    id: root

    property string mode: "Locked"
    property string user: ""
    property string status: ""
    property bool busy: false
    property bool error: false
    property string host: ""

    signal submitted(string password)

    function reset() {
        secret.clear();
        secret.grab();
    }

    color: Theme.bg

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Pre-darkened at build time and kept loaded by the lock instance, so it
    // is on screen in the same frame as the lock.
    Image {
        anchors.fill: parent
        source: Theme.lockWallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
    }

    Scanlines {
        anchors.fill: parent
        strength: 0.03
    }

    // Masthead: station name and the mode as the selected site, sharing a baseline.
    Din {
        id: hostText
        x: 48
        // Same face and size as the mode text, so the same offset puts both on one baseline.
        y: modeBox.y + modeText.y
        size: 50
        text: root.host
        color: Theme.red
    }

    Rectangle {
        id: modeBox
        x: hostText.x + hostText.implicitWidth + 16
        y: 40
        width: modeText.implicitWidth + 24
        height: 52
        color: Theme.redDeep

        Din {
            id: modeText
            anchors.horizontalCenter: parent.horizontalCenter
            y: capCentre(modeBox.height)
            size: 50
            text: root.mode
            color: "#000000"
        }
    }

    Column {
        x: 48
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        spacing: 2

        Din {
            size: 120
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: Theme.ink
        }

        Txt {
            leftPadding: 4
            text: Qt.formatDateTime(clock.date, "dddd dd MMMM yyyy · hh:mm:ss")
            caps: true
            color: Theme.muted
        }
    }

    Frame {
        id: frame
        anchors.centerIn: parent
        width: secret.implicitWidth + padding * 2
        height: implicitHeight
        label: "Authorization"
        borderColor: root.error ? Theme.red : Theme.lineStrong
        fill: Theme.alpha(Theme.bg, 0.9)
        padding: 18
        bottomPadding: 22

        Column {
            width: secret.implicitWidth
            spacing: 14

            // IDENT user on the left, status on the right, on one baseline.
            Item {
                width: parent.width
                height: identLabel.implicitHeight

                Txt {
                    id: identLabel
                    text: "IDENT"
                    color: Theme.muted
                }

                Txt {
                    x: identLabel.implicitWidth + 8
                    anchors.baseline: identLabel.baseline
                    text: root.user
                    color: Theme.inkBright
                }

                Txt {
                    anchors.right: parent.right
                    anchors.baseline: identLabel.baseline
                    text: root.status
                    caps: true
                    color: root.error ? Theme.red : Theme.muted
                }
            }

            Secret {
                id: secret
                busy: root.busy
                error: root.error
                onAccepted: if (text !== "") root.submitted(text)
            }
        }
    }

    // Nothing here takes the mouse; hide the pointer over the whole screen.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.BlankCursor
    }

    Component.onCompleted: reset()
}
