import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Application launcher styled after the LSTR MEMORY panel: a solid red bar on
// the selected row, the rest fading out with distance from it.
Scope {
    id: root

    property bool open: false
    property string query: ""
    property int selected: 0

    readonly property int rows: 11

    readonly property var results: {
        const q = query.trim().toLowerCase();
        const scored = [];
        for (const entry of DesktopEntries.applications.values) {
            if (entry.noDisplay)
                continue;
            const name = entry.name.toLowerCase();
            let score = -1;
            if (q === "")
                score = 0;
            else if (name.startsWith(q))
                score = 0;
            else if (name.split(/[\s\-_.]+/).some(word => word.startsWith(q)))
                score = 1;
            else if (name.includes(q))
                score = 2;
            else if ([entry.genericName, ...entry.keywords].some(k => (k ?? "").toLowerCase().includes(q)))
                score = 3;
            if (score >= 0)
                scored.push({
                    entry,
                    score
                });
        }
        scored.sort((a, b) => a.score - b.score || a.entry.name.localeCompare(b.entry.name));
        return scored.map(s => s.entry);
    }

    function toggle() {
        open = !open;
        query = "";
        selected = 0;
    }

    function launch(entry) {
        const command = entry.runInTerminal ? ["ghostty", "-e", ...entry.command] : entry.command;
        Niri.action("spawn", "--", ...command);
        open = false;
    }

    IpcHandler {
        target: "launcher"

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
        WlrLayershell.namespace: "signalis-launcher"
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        Frame {
            id: panel
            anchors.centerIn: parent
            width: 520
            height: 64 + root.rows * 26 + 34
            label: "Memory"
            borderColor: Theme.red
            padding: 14

            MouseArea {
                anchors.fill: parent
            }

            Column {
                width: parent.width
                spacing: 12

                Rectangle {
                    width: parent.width
                    height: 28
                    color: Theme.input
                    border.width: 1
                    border.color: Theme.lineStrong

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Txt {
                            text: ">"
                            color: Theme.red
                        }

                        Item {
                            width: panel.width - 70
                            height: input.implicitHeight

                            Txt {
                                visible: input.text === ""
                                text: "Search"
                                caps: true
                                color: Theme.dim
                            }

                            TextInput {
                                id: input
                                width: parent.width
                                focus: root.open
                                color: Theme.ink
                                selectionColor: Theme.red
                                selectedTextColor: Theme.bg
                                cursorVisible: true
                                font: prompt.font
                                text: root.query
                                onTextChanged: {
                                    root.query = text;
                                    root.selected = 0;
                                }
                                onVisibleChanged: if (visible) forceActiveFocus()

                                Keys.onPressed: event => {
                                    const count = root.results.length;
                                    if (event.key === Qt.Key_Escape) {
                                        root.open = false;
                                    } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) || (event.key === Qt.Key_N && event.modifiers & Qt.ControlModifier)) {
                                        root.selected = Math.min(count - 1, root.selected + 1);
                                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_P && event.modifiers & Qt.ControlModifier)) {
                                        root.selected = Math.max(0, root.selected - 1);
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        if (count > 0)
                                            root.launch(root.results[root.selected]);
                                    } else {
                                        return;
                                    }
                                    event.accepted = true;
                                }
                            }

                            // Carries the grid-snapped font for the TextInput.
                            Txt {
                                id: prompt
                                visible: false
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        // Keep the selection in view: slide the window of visible rows.
                        model: {
                            const start = Math.max(0, Math.min(root.selected - Math.floor(root.rows / 2), root.results.length - root.rows));
                            return root.results.slice(start, start + root.rows).map((entry, i) => ({
                                        entry,
                                        index: start + i
                                    }));
                        }

                        Rectangle {
                            id: row

                            required property var modelData
                            readonly property bool current: modelData.index === root.selected

                            width: parent.width
                            height: 24
                            color: current ? Theme.red : (hover.containsMouse ? Theme.hover : Theme.raised)
                            opacity: current ? 1 : Math.max(0.25, 1 - Math.abs(modelData.index - root.selected) * 0.13)

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 16
                                    source: Quickshell.iconPath(row.modelData.entry.icon, "application-x-executable")
                                }

                                Txt {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.entry.name
                                    color: row.current ? Theme.bg : Theme.soft
                                }
                            }

                            Txt {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: row.current && text !== ""
                                text: row.modelData.entry.genericName
                                caps: true
                                color: Theme.selection
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.launch(row.modelData.entry)
                            }
                        }
                    }
                }
            }

            Txt {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                text: root.results.length ? String(root.selected + 1).padStart(3, "0") + "/" + String(root.results.length).padStart(3, "0") : "NO RECORD"
                color: Theme.dim
            }
        }
    }
}
