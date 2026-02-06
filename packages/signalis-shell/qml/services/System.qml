pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory and backlight readouts.
Singleton {
    id: root

    property int cpu: 0
    property int memory: 0
    property int brightness: -1

    signal brightnessAdjusted

    property var lastCpu: null

    function setBrightness(change) {
        brightnessSet.command = ["brightnessctl", "--class=backlight", "-m", "set", change];
        brightnessSet.running = true;
    }

    function parseBrightness(text) {
        // name,class,current,percent,max
        const fields = text.trim().split(",");
        if (fields.length >= 4)
            brightness = parseInt(fields[3]);
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const fields = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = fields[3] + fields[4];
            const total = fields.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                if (dt > 0)
                    root.cpu = Math.round(100 * (1 - (idle - root.lastCpu.idle) / dt));
            }
            root.lastCpu = {
                idle,
                total
            };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const value = key => parseInt(text().match(new RegExp(key + ":\\s+(\\d+)"))[1]);
            root.memory = Math.round(100 * (1 - value("MemAvailable") / value("MemTotal")));
        }
    }

    Process {
        id: brightnessGet
        command: ["brightnessctl", "--class=backlight", "-m", "info"]
        stdout: StdioCollector {
            onStreamFinished: root.parseBrightness(text)
        }
    }

    Process {
        id: brightnessSet
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseBrightness(text);
                root.brightnessAdjusted();
            }
        }
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 2000
        onTriggered: {
            stat.reload();
            meminfo.reload();
            brightnessGet.running = true;
        }
    }
}
