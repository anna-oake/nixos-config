import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.components
import qs.config
import qs.services

Row {
    spacing: 4

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var battery: UPower.displayDevice

    PwObjectTracker {
        objects: [sink]
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // Wi-Fi band and channel from a centre frequency in MHz, e.g. "5 GHz (36)".
    function band(mhz) {
        if (!mhz)
            return undefined;
        if (mhz === 2484)
            return "2.4 GHz (14)";
        if (mhz < 3000)
            return `2.4 GHz (${(mhz - 2407) / 5})`;
        if (mhz < 5925)
            return `5 GHz (${(mhz - 5000) / 5})`;
        return `6 GHz (${(mhz - 5950) / 5})`;
    }

    function pct(value) {
        return String(value).padStart(3, " ") + "%";
    }

    // Gauges fill with the load and turn red past the limit.
    component Gauge: Readout {
        property int percent: 0
        readonly property bool over: percent >= 90

        value: pct(percent)
        valueColor: over ? Theme.red : Theme.ink
        frameColor: over ? Theme.redBorder : Theme.line
        fill: percent / 100
        fillColor: over ? Theme.tealOver : Theme.teal
    }

    Gauge {
        label: "CPU"
        percent: System.cpu
    }

    Gauge {
        label: "MEM"
        percent: System.memory
    }

    Readout {
        visible: sink?.audio !== undefined
        label: "VOL"
        value: sink?.audio?.muted ? "MUTE" : pct(Math.round((sink?.audio?.volume ?? 0) * 100))
        valueColor: sink?.audio?.muted ? Theme.red : Theme.ink
        frameColor: sink?.audio?.muted ? Theme.redBorder : Theme.line
        onClicked: if (sink?.audio) sink.audio.muted = !sink.audio.muted
        onScrolled: delta => {
            if (sink?.audio)
                sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (delta > 0 ? 0.05 : -0.05)));
        }
    }

    WifiMenu {
        id: wifiMenu
        anchorItem: link
    }

    Readout {
        id: link

        readonly property int dbm: Link.signal
        readonly property bool weak: Link.wifi && dbm !== 0 && dbm < -75

        label: "LINK"
        value: !Link.up ? "NO SIGNAL" : (!Link.wifi ? "WIRED" : (dbm !== 0 ? dbm + " dBm" : "···"))
        valueColor: !Link.up || weak ? Theme.red : (Link.wifi && dbm < -67 ? Theme.yellow : Theme.ink)
        frameColor: !Link.up ? Theme.redBorder : Theme.line
        onClicked: if (Link.wifiAdapter) wifiMenu.toggle()
        tooltip: {
            if (wifiMenu.open)
                return "";
            if (!Link.up)
                return "NO LINK";
            const i = Link.info;
            const sections = [
                Link.wifi ? [["SSID", Link.ssid], ["BSSID", i.bssid], ["FREQ", band(parseInt(i.freq))]] : [],
                [["IPV4", i.ipv4], ["IPV6", i.ipv6], ["GW", i.gateway]],
                [["DEV", Link.device.name], ["MAC", Link.device.address]]
            ];
            return sections.map(rows => rows.filter(r => r[1]).map(r => r[0].padEnd(6, " ") + r[1]).join("\n")).filter(s => s !== "").join("\n\n");
        }
    }

    Readout {
        readonly property bool charging: battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.FullyCharged || battery?.state === UPowerDeviceState.PendingCharge
        readonly property int level: Math.round((battery?.percentage ?? 0) * 100)

        visible: battery?.isLaptopBattery ?? false
        label: charging ? "CHG" : "BAT"
        value: pct(level)
        valueColor: charging ? Theme.green : (level <= 15 ? Theme.red : (level <= 30 ? Theme.yellow : Theme.ink))
        frameColor: !charging && level <= 30 ? (level <= 15 ? Theme.red : Theme.yellow) : Theme.line
        blink: !charging && level <= 15
    }

    Readout {
        visible: Niri.layouts.length > 1
        value: Niri.layout
        // The first layout is the default; anything else is worth noticing.
        valueColor: Niri.layoutIndex > 0 ? Theme.red : Theme.soft
        frameColor: Niri.layoutIndex > 0 ? Theme.redBorder : Theme.line
        onClicked: Niri.action("switch-layout", "next")
    }

    Readout {
        value: Qt.formatDateTime(clock.date, "hh:mm:ss")
        valueColor: Theme.inkBright
        tooltip: Qt.formatDateTime(clock.date, "dddd\ndd MMMM yyyy").toUpperCase()
    }
}
