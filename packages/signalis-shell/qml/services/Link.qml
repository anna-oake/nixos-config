pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Current network link: which interface, and what iw and ip say about it.
Singleton {
    id: root

    readonly property var wifiAdapter: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property var wiredDevice: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var device: wifiDevice ?? wiredDevice
    readonly property bool wifi: wifiDevice !== null
    readonly property bool up: device !== null

    readonly property string ssid: {
        if (!wifiDevice)
            return "";
        const network = wifiDevice.networks.values.find(n => n.connected);
        return network?.name ?? "";
    }

    // Filled in from `iw dev <if> link` and `ip addr`.
    property var info: ({})
    readonly property int signal: info.signal !== undefined ? parseInt(info.signal) : 0

    Process {
        id: probe
        command: ["sh", "-c", `
            dev="$1"
            ip -o -4 addr show dev "$dev" | awk '{print "ipv4=" $4; exit}'
            # Only real global unicast (2000::/3); skip ULAs that smart-home gear hands out.
            ip -o -6 addr show dev "$dev" scope global | awk '$4 ~ /^[23]/ {print "ipv6=" $4; exit}'
            ip route show default dev "$dev" | awk '{print "gateway=" $3; exit}'
            [ -d "/sys/class/net/$dev/wireless" ] && iw dev "$dev" link | awk '
                /^Connected to/ { print "bssid=" $3 }
                /freq:/ { print "freq=" $2 }
                /signal:/ { print "signal=" $2 }
                '
            true
        `, "sh", root.device?.name ?? ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const info = {};
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i > 0)
                        info[line.slice(0, i)] = line.slice(i + 1);
                }
                root.info = info;
            }
        }
    }

    Timer {
        running: root.up
        repeat: true
        triggeredOnStart: true
        interval: 3000
        onTriggered: probe.running = true
        onRunningChanged: if (!running) root.info = {}
    }
}
