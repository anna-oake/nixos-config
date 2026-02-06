import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Masthead strip: station name, workspace selector, focused window, readouts.
PanelWindow {
    id: bar

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30
    color: Theme.bg

    WlrLayershell.namespace: "signalis-bar"

    Scanlines {
        anchors.fill: parent
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.line
    }

    Row {
        id: left
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // Station mark: red frame with a solid core; opens the overview.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            color: "transparent"
            border.width: 1
            border.color: Theme.red

            Rectangle {
                anchors.centerIn: parent
                width: 6
                height: 6
                color: Theme.red
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Niri.action("toggle-overview")
            }
        }

        Workspaces {
            anchors.verticalCenter: parent.verticalCenter
            output: bar.screen?.name ?? ""
        }

        Rectangle {
            visible: title.text !== ""
            width: 1
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.line
        }

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            visible: title.text !== "" && source != ""
            implicitSize: 14
            asynchronous: true
            source: {
                const entry = DesktopEntries.heuristicLookup(Niri.focusedWindow?.app_id ?? "");
                return entry?.icon ? Quickshell.iconPath(entry.icon, true) : "";
            }
        }

        Txt {
            id: title
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, bar.width - left.x - right.width - 260)
            elide: Text.ElideRight
            color: Theme.muted
            text: {
                const w = Niri.focusedWindow;
                if (!w)
                    return "";
                const ws = Niri.workspaces.find(s => s.id === w.workspace_id);
                return ws && ws.output === bar.screen?.name ? (w.title ?? "") : "";
            }
        }
    }

    Row {
        id: right
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Tray {
            anchors.verticalCenter: parent.verticalCenter
            bar: bar
        }

        Stats {
            id: stats
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
