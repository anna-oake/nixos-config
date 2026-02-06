//@ pragma IgnoreSystemSettings
//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.bar
import qs.launcher
import qs.notifications
import qs.osd
import qs.polkit
import qs.wallpaper

// Desktop shell: everything except the lock screen, which runs as its own
// instance (lock.qml) so a crash here can never leave the session stuck.
ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property ShellScreen modelData

            Wallpaper {
                screen: perScreen.modelData
            }

            Bar {
                screen: perScreen.modelData
            }
        }
    }

    Launcher {}
    Notifications {}
    Osd {}
    Polkit {}

    IdleMonitor {
        timeout: 300
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["signalis-ctl", "lock"])
    }

    IdleMonitor {
        timeout: 600
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"])
    }
}
