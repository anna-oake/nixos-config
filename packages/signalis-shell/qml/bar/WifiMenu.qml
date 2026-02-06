import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.components
import qs.config
import qs.services

// Wi-Fi picker under the LINK readout. Click a network to join or leave it; a
// secured one asks for its passphrase inline, and a failed first join is not
// kept. Right-click forgets a network joined here; profiles from the Nix
// config are marked NIX and stay put.
Dropdown {
    id: root

    readonly property var device: Link.wifiAdapter

    // The network waiting for a passphrase, and the last failure to show.
    property var asking: null
    property string failure: ""

    // NetworkManager's saved profiles: { uuid, name, nix }. Nix ones are the
    // ensureProfiles files it keeps under /run (reported as /var/run).
    property var saved: []

    // A network joined with a new passphrase; its profile goes if the join fails.
    property var joining: null

    function profilesFor(network) {
        const ids = network.nmSettings.map(s => s.uuid);
        return saved.filter(p => ids.includes(p.uuid) || p.name === network.name);
    }

    function isDeclared(network) {
        return profilesFor(network).some(p => p.nix);
    }

    function isSaved(network) {
        return network.known || profilesFor(network).length > 0;
    }

    function forget(network) {
        const uuids = profilesFor(network).filter(p => !p.nix).map(p => p.uuid);
        if (uuids.length === 0)
            return;
        remove.command = ["nmcli", "connection", "delete"].concat(...uuids.map(u => ["uuid", u]));
        remove.running = true;
    }

    function secured(network) {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }

    function activate(network) {
        failure = "";
        if (network.connected)
            network.disconnect();
        else if (isSaved(network) || !secured(network))
            network.connect();
        else
            asking = network;
    }

    readonly property var networks: {
        if (!device)
            return [];
        return device.networks.values.filter(n => n.name !== "").sort((a, b) => (b.connected - a.connected) || (isSaved(b) - isSaved(a)) || (b.signalStrength - a.signalStrength));
    }

    onOpenChanged: {
        if (open) {
            profiles.running = true;
        } else {
            joining = null;
            asking = null;
            failure = "";
        }
    }

    Binding {
        when: root.device !== null
        target: root.device
        property: "scannerEnabled"
        value: root.open
    }

    Process {
        id: profiles
        command: ["nmcli", "-t", "-f", "UUID,FILENAME,NAME", "connection", "show"]
        stdout: StdioCollector {
            // UUID and FILENAME never contain colons; NAME comes last with its colons escaped.
            onStreamFinished: root.saved = text.split("\n").filter(l => l !== "").map(l => {
                const [uuid, file] = l.split(":", 2);
                return {
                    uuid,
                    name: l.slice(uuid.length + file.length + 2).replace(/\\:/g, ":"),
                    nix: file.includes("/run/NetworkManager/")
                };
            })
        }
    }

    Process {
        id: remove
        onExited: profiles.running = true
    }

    Timer {
        running: root.open
        repeat: true
        interval: 2000
        onTriggered: profiles.running = true
    }

    Frame {
        id: frame
        label: "Wireless"
        fill: Theme.raised
        borderColor: Theme.red

        Column {
            width: 320
            spacing: 2

            // Radio switch and scan state.
            Item {
                width: parent.width
                height: 22

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: !Networking.wifiEnabled ? "RADIO OFF" : (root.device?.scannerEnabled ? "SCANNING" : "IDLE")
                    color: Theme.muted
                }

                Readout {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    value: Networking.wifiEnabled ? "ON" : "OFF"
                    valueColor: Networking.wifiEnabled ? Theme.ink : Theme.red
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.alpha(Theme.line, 0.6)
            }

            Txt {
                visible: Networking.wifiEnabled && root.networks.length === 0
                topPadding: 6
                bottomPadding: 6
                text: "NO NETWORKS IN RANGE"
                color: Theme.dim
            }

            Repeater {
                model: Networking.wifiEnabled ? root.networks : []

                Column {
                    id: entry

                    required property var modelData
                    readonly property var network: modelData
                    readonly property bool busy: network.stateChanging
                    readonly property bool asked: root.asking === network

                    width: parent.width
                    spacing: 4

                    Connections {
                        target: entry.network

                        function onConnectionFailed(reason) {
                            const why = {
                                [ConnectionFailReason.NoSecrets]: "WRONG PASSPHRASE",
                                [ConnectionFailReason.WifiAuthTimeout]: "AUTH TIMEOUT",
                                [ConnectionFailReason.WifiNetworkLost]: "NETWORK LOST",
                                [ConnectionFailReason.WifiClientDisconnected]: "DISCONNECTED",
                                [ConnectionFailReason.WifiClientFailed]: "FAILED"
                            };
                            root.failure = why[reason] ?? "FAILED";
                            if (root.joining === entry.network) {
                                root.joining = null;
                                root.forget(entry.network);
                            }
                            if (reason === ConnectionFailReason.NoSecrets && root.secured(entry.network))
                                root.asking = entry.network;
                        }

                        function onConnectedChanged() {
                            if (entry.network.connected) {
                                if (root.asking === entry.network)
                                    root.asking = null;
                                if (root.joining === entry.network)
                                    root.joining = null;
                                profiles.running = true;
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 24
                        color: row.containsMouse || entry.asked ? Theme.hover : "transparent"

                        // Connected: solid; saved: hollow; otherwise nothing.
                        Rectangle {
                            id: mark
                            x: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8
                            height: 8
                            color: entry.network.connected ? Theme.red : "transparent"
                            border.width: root.isSaved(entry.network) ? 1 : 0
                            border.color: Theme.red
                            opacity: entry.busy ? (blink.on ? 1 : 0.2) : 1

                            Timer {
                                id: blink
                                property bool on: true
                                running: entry.busy
                                repeat: true
                                interval: 300
                                onTriggered: on = !on
                            }
                        }

                        Txt {
                            anchors.left: mark.right
                            anchors.leftMargin: 10
                            anchors.right: tags.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            text: entry.network.name
                            color: entry.network.connected ? Theme.inkBright : Theme.ink
                        }

                        Row {
                            id: tags
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Txt {
                                visible: root.isDeclared(entry.network)
                                text: "NIX"
                                color: Theme.dim
                            }

                            Txt {
                                text: root.secured(entry.network) ? "SEC" : "OPEN"
                                color: root.secured(entry.network) ? Theme.dim : Theme.yellow
                            }

                            Txt {
                                text: String(Math.round(entry.network.signalStrength * 100)).padStart(3, " ") + "%"
                                color: Theme.soft
                            }
                        }

                        MouseArea {
                            id: row
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    root.forget(entry.network);
                                } else {
                                    root.activate(entry.network);
                                }
                            }
                        }
                    }

                    // Passphrase for a new secured network.
                    Item {
                        visible: entry.asked
                        width: parent.width
                        height: visible ? pass.implicitHeight + 8 : 0

                        Secret {
                            id: pass
                            x: 24
                            cells: 22
                            busy: entry.busy
                            error: root.failure !== "" && entry.asked
                            onAccepted: {
                                root.failure = "";
                                root.joining = entry.network;
                                entry.network.connectWithPsk(text);
                                clear();
                            }
                            onCancelled: root.asking = null
                        }

                        onVisibleChanged: if (visible) pass.grab()
                    }
                }
            }

            Txt {
                visible: root.failure !== ""
                topPadding: 6
                text: root.failure
                color: Theme.red
            }
        }
    }
}
