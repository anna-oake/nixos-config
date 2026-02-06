import QtQuick
import qs.config

// Password entry drawn as a row of cells: each character fills one, the next
// one blinks as the cursor. `busy` sweeps the cells, `error` flashes them red.
Item {
    id: root

    property int cells: 24
    property bool busy: false
    property bool error: false
    property alias text: input.text

    signal accepted
    signal cancelled

    function clear() {
        input.text = "";
    }

    function grab() {
        input.forceActiveFocus();
    }

    implicitWidth: cells * 13 - 3
    implicitHeight: 18

    property bool cursorOn: true
    property int sweep: 0

    Timer {
        running: input.activeFocus && !root.busy
        repeat: true
        interval: 530
        onTriggered: root.cursorOn = !root.cursorOn
    }

    Timer {
        running: root.busy
        repeat: true
        interval: 45
        onTriggered: root.sweep = (root.sweep + 1) % root.cells
    }

    TextInput {
        id: input
        width: 1
        height: 1
        opacity: 0
        echoMode: TextInput.Password
        focus: true
        enabled: !root.busy
        onAccepted: root.accepted()
        Keys.onEscapePressed: root.cancelled()
    }

    Row {
        spacing: 3

        Repeater {
            model: root.cells

            Rectangle {
                required property int index

                readonly property int length: input.text.length
                readonly property bool filled: index < length || (index === root.cells - 1 && length > root.cells)
                readonly property bool cursor: index === length && !root.busy
                readonly property bool swept: root.busy && Math.abs(index - root.sweep) < 3

                width: 10
                height: 18
                color: root.error ? Theme.red : (swept ? Theme.inkBright : (filled ? Theme.red : "transparent"))
                border.width: 1
                border.color: root.error || filled || swept ? color : (cursor && root.cursorOn && input.activeFocus ? Theme.red : Theme.line)
            }
        }
    }
}
