import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// Volume and backlight level meter, shown briefly when either changes.
Scope {
    id: root

    property string kind: ""
    property int level: 0
    property bool muted: false
    property bool shown: false

    // PipeWire reports the initial state as a change; ignore it.
    property bool armed: false

    readonly property var sink: Pipewire.defaultAudioSink

    function show(newKind, newLevel, newMuted) {
        kind = newKind;
        level = newLevel;
        muted = newMuted;
        shown = true;
        hide.restart();
    }

    function showVolume() {
        if (armed && sink?.audio)
            show("Volume", Math.round(sink.audio.volume * 100), sink.audio.muted);
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged() {
            root.showVolume();
        }

        function onMutedChanged() {
            root.showVolume();
        }
    }

    Connections {
        target: System

        function onBrightnessAdjusted() {
            root.show("Backlight", System.brightness, false);
        }
    }

    Timer {
        running: true
        interval: 1500
        onTriggered: root.armed = true
    }

    Timer {
        id: hide
        interval: 1400
        onTriggered: root.shown = false
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            System.setBrightness("5%+");
        }

        function down(): void {
            System.setBrightness("5%-");
        }
    }

    PanelWindow {
        visible: root.shown
        screen: {
            const focused = Niri.workspaces.find(w => w.is_focused);
            return Quickshell.screens.find(s => s.name === focused?.output) ?? Quickshell.screens[0];
        }

        anchors.bottom: true
        margins.bottom: 80
        // Hug the meter so the padding is even on both sides.
        implicitWidth: frame.implicitWidth
        implicitHeight: frame.implicitHeight
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "signalis-osd"

        Frame {
            id: frame
            width: parent.width
            label: root.kind
            borderColor: root.muted ? Theme.redBorder : Theme.line

            Row {
                spacing: 10

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Repeater {
                        model: 25

                        Rectangle {
                            required property int index
                            readonly property bool lit: !root.muted && root.level >= (index + 1) * 4

                            width: 7
                            height: 14
                            color: lit ? Theme.red : "transparent"
                            border.width: 1
                            border.color: lit ? Theme.red : Theme.line
                        }
                    }
                }

                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.muted ? "MUTE" : String(root.level).padStart(3, " ") + "%"
                    color: root.muted ? Theme.red : Theme.ink
                }
            }
        }
    }
}
