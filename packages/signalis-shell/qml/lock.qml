//@ pragma IgnoreSystemSettings

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.auth
import qs.config
import qs.services

// Lock screen, kept running as its own instance so locking is instant and
// independent of the desktop shell. Also locks before suspend.
ShellRoot {
    id: root

    property string status: ""
    property bool error: false

    function lock() {
        if (!sessionLock.locked) {
            status = "";
            error = false;
            Niri.action("switch-layout", "0");
            sessionLock.locked = true;
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }

    // Passwords are always typed in the default layout: switch back if it
    // changes while locked (the xkb toggle still works on the lock screen).
    Connections {
        target: Niri

        function onLayoutIndexChanged() {
            if (sessionLock.locked && Niri.layoutIndex !== 0)
                Niri.action("switch-layout", "0");
        }
    }

    PamContext {
        id: pam

        property string password: ""

        // Password-only stack; see security.pam.services.signalis-lock.
        config: "signalis-lock"

        onResponseRequiredChanged: if (responseRequired) {
            respond(password);
            password = "";
        }

        onCompleted: result => {
            if (result === PamResult.Success) {
                sessionLock.locked = false;
                return;
            }
            root.error = true;
            root.status = "Access denied";
            errorTimer.restart();
        }
    }

    Timer {
        id: errorTimer
        interval: 1200
        onTriggered: {
            root.error = false;
            root.status = "";
        }
    }

    // Holds the lock wallpaper in the pixmap cache between locks.
    Image {
        visible: false
        source: Theme.lockWallpaper
        asynchronous: false
    }

    WlSessionLock {
        id: sessionLock

        WlSessionLockSurface {
            id: surface
            color: "black"

            AuthScreen {
                id: auth
                anchors.fill: parent
                mode: "Locked"
                host: Host.name.toUpperCase()
                user: Quickshell.env("USER") ?? ""
                busy: pam.active
                error: root.error
                status: pam.active ? "Verifying" : root.status

                onSubmitted: password => {
                    pam.password = password;
                    reset();
                    pam.start();
                }
            }
        }
    }

    // Hold a sleep delay while unlocked; on PrepareForSleep lock first and
    // release it once the compositor confirms every output is covered.
    Process {
        running: !sessionLock.secure
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=signalis-lock", "--why=Lock the screen before sleep", "sleep", "infinity"]
    }

    Process {
        id: logind
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("PrepareForSleep (true,)") || line.includes(".Session.Lock ()"))
                    root.lock();
            }
        }
        onExited: logindRestart.start()
    }

    Timer {
        id: logindRestart
        interval: 1000
        onTriggered: logind.running = true
    }
}
