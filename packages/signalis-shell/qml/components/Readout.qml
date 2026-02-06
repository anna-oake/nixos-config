import QtQuick
import Quickshell
import qs.config

// Outlined instrument readout: dim label, bright value.
Rectangle {
    id: root

    property string label: ""
    property string value: ""
    property color valueColor: Theme.ink
    property color frameColor: Theme.line
    property bool blink: false
    // Gauge fill behind the text, 0..1; negative for none.
    property real fill: -1
    property color fillColor: Theme.teal
    // Shown in a popup below the readout while hovered; one entry per line,
    // with a blank line between sections.
    property string tooltip: ""

    signal clicked(var mouse)
    signal scrolled(int delta)

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 20
    color: Theme.surface
    border.width: 1
    border.color: hovered ? Theme.red : (blinkOn ? frameColor : Theme.redDark)

    property bool blinkOn: true

    // Mouse: hover shows the tooltip. Touch: a tap clicks, holding shows it.
    readonly property bool hovered: mouse.touch ? mouse.held : mouse.containsMouse

    Timer {
        running: root.blink
        repeat: true
        interval: 500
        onTriggered: root.blinkOn = !root.blinkOn
        onRunningChanged: if (!running) root.blinkOn = true
    }

    Rectangle {
        visible: root.fill >= 0
        x: 1
        y: 1
        height: parent.height - 2
        width: (parent.width - 2) * Math.max(0, Math.min(1, root.fill))
        color: root.fillColor
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7

        Txt {
            visible: root.label !== ""
            text: root.label
            caps: true
            color: Theme.muted
        }

        Txt {
            text: root.value
            color: root.blinkOn ? root.valueColor : Theme.redDark
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        property bool touch: false
        property bool held: false

        onPressed: m => {
            touch = m.source !== Qt.MouseEventNotSynthesized;
            held = false;
            if (touch)
                hold.restart();
        }
        onReleased: {
            hold.stop();
            held = false;
        }
        onCanceled: {
            hold.stop();
            held = false;
        }
        onPositionChanged: m => {
            if (!pressed)
                touch = m.source !== Qt.MouseEventNotSynthesized;
        }
        onClicked: m => {
            if (!(touch && hold.fired))
                root.clicked(m);
        }

        Timer {
            id: hold
            property bool fired: false
            interval: 400
            onRunningChanged: if (running) fired = false
            onTriggered: {
                fired = true;
                mouse.held = true;
            }
        }
        // Trackpads send many small deltas; step once per mouse-wheel notch (120).
        property int wheelAccum: 0
        onWheel: w => {
            wheelAccum += w.angleDelta.y;
            while (Math.abs(wheelAccum) >= 120) {
                const step = wheelAccum > 0 ? 120 : -120;
                root.scrolled(step);
                wheelAccum -= step;
            }
        }
    }

    PopupWindow {
        visible: root.tooltip !== "" && root.hovered
        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.rect: Qt.rect(0, 0, root.width, root.height + 6)
        implicitWidth: tip.implicitWidth + 20
        implicitHeight: tip.implicitHeight + 14
        color: Theme.raised

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1
            border.color: Theme.red
        }

        Column {
            id: tip
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: root.tooltip.split("\n\n")

                Column {
                    id: section
                    required property string modelData
                    required property int index

                    spacing: 6

                    Rectangle {
                        visible: section.index > 0
                        width: tip.width
                        height: 1
                        color: Theme.alpha(Theme.line, 0.6)
                    }

                    Txt {
                        text: section.modelData
                        color: Theme.soft
                        lineHeight: 1.2
                    }
                }
            }
        }
    }
}
