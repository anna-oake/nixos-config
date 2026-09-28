import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// Power menu: three big square buttons in a row, captioned underneath.
Scope {
    id: root

    property bool open: false
    property int selected: 0

    readonly property var actions: [
        {
            name: "Suspend",
            icon: "suspend",
            command: ["systemctl", "suspend-then-hibernate"]
        },
        {
            name: "Reboot",
            icon: "reboot",
            command: ["systemctl", "reboot"]
        },
        {
            name: "Shutdown",
            icon: "shutdown",
            command: ["systemctl", "poweroff"]
        }
    ]

    function toggle() {
        open = !open;
        selected = 0;
        if (open)
            keys.forceActiveFocus();
    }

    function run(action) {
        open = false;
        Quickshell.execDetached(action.command);
    }

    IpcHandler {
        target: "power"

        function toggle(): void {
            root.toggle();
        }
    }

    PanelWindow {
        visible: root.open
        screen: {
            const focused = Niri.workspaces.find(w => w.is_focused);
            return Quickshell.screens.find(s => s.name === focused?.output) ?? Quickshell.screens[0];
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Theme.alpha(Theme.bg, 0.55)
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "signalis-power"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        Frame {
            anchors.centerIn: parent
            label: "Power"
            borderColor: Theme.red
            padding: 24

            MouseArea {
                anchors.fill: parent
            }

            Row {
                id: keys
                spacing: 24
                focus: root.open

                Keys.onPressed: event => {
                    const count = root.actions.length;
                    if (event.key === Qt.Key_Escape) {
                        root.open = false;
                    } else if (event.key === Qt.Key_Right || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                        root.selected = Math.min(count - 1, root.selected + 1);
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                        root.selected = Math.max(0, root.selected - 1);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.run(root.actions[root.selected]);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }

                Repeater {
                    model: root.actions

                    Column {
                        id: button

                        required property var modelData
                        required property int index
                        readonly property bool current: index === root.selected
                        readonly property color iconColor: current ? Theme.bg : Theme.soft

                        spacing: 10

                        Rectangle {
                            width: 96
                            height: 96
                            color: button.current ? Theme.red : (hover.containsMouse ? Theme.hover : Theme.raised)
                            border.width: 1
                            border.color: button.current ? Theme.red : Theme.lineStrong

                            // Crescent moon.
                            Shape {
                                anchors.centerIn: parent
                                width: 40
                                height: 40
                                visible: button.modelData.icon === "suspend"
                                preferredRendererType: Shape.CurveRenderer

                                ShapePath {
                                    strokeWidth: -1
                                    fillColor: button.iconColor
                                    startX: 26
                                    startY: 4
                                    PathArc {
                                        x: 26
                                        y: 36
                                        radiusX: 17
                                        radiusY: 17
                                        useLargeArc: true
                                        direction: PathArc.Counterclockwise
                                    }
                                    PathArc {
                                        x: 26
                                        y: 4
                                        radiusX: 18
                                        radiusY: 18
                                    }
                                }
                            }

                            // Clockwise arrow around an open ring.
                            Shape {
                                anchors.centerIn: parent
                                width: 40
                                height: 40
                                visible: button.modelData.icon === "reboot"
                                preferredRendererType: Shape.CurveRenderer

                                ShapePath {
                                    strokeWidth: 4
                                    strokeColor: button.iconColor
                                    fillColor: "transparent"
                                    capStyle: ShapePath.FlatCap
                                    PathAngleArc {
                                        centerX: 20
                                        centerY: 20
                                        radiusX: 15
                                        radiusY: 15
                                        startAngle: -60
                                        sweepAngle: 300
                                    }
                                }

                                ShapePath {
                                    strokeWidth: -1
                                    fillColor: button.iconColor
                                    startX: 18.5
                                    startY: 3.5
                                    PathLine {
                                        x: 9.5
                                        y: 1.8
                                    }
                                    PathLine {
                                        x: 15.5
                                        y: 12.2
                                    }
                                    PathLine {
                                        x: 18.5
                                        y: 3.5
                                    }
                                }
                            }

                            // Power symbol: a ring broken at the top with a bar through the gap.
                            Shape {
                                anchors.centerIn: parent
                                width: 40
                                height: 40
                                visible: button.modelData.icon === "shutdown"
                                preferredRendererType: Shape.CurveRenderer

                                ShapePath {
                                    strokeWidth: 4
                                    strokeColor: button.iconColor
                                    fillColor: "transparent"
                                    capStyle: ShapePath.FlatCap
                                    PathAngleArc {
                                        centerX: 20
                                        centerY: 22
                                        radiusX: 15
                                        radiusY: 15
                                        startAngle: -55
                                        sweepAngle: 290
                                    }
                                }

                                ShapePath {
                                    strokeWidth: 4
                                    strokeColor: button.iconColor
                                    fillColor: "transparent"
                                    capStyle: ShapePath.FlatCap
                                    startX: 20
                                    startY: 2
                                    PathLine {
                                        x: 20
                                        y: 20
                                    }
                                }
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.selected = button.index
                                onClicked: root.run(button.modelData)
                            }
                        }

                        Txt {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: button.modelData.name
                            caps: true
                            color: button.current ? Theme.red : Theme.soft
                        }
                    }
                }
            }
        }
    }
}
