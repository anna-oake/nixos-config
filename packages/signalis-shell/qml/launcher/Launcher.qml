import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Application launcher styled after the LSTR MEMORY panel: a solid red bar on
// the selected row, the rest fading out with distance from it. The app list is
// local. Typed queries go to anyrun-provider, which stays running with the shell.
Scope {
    id: root

    property bool open: false
    property string query: ""
    property int selected: 0
    property var results: []
    property var home: []
    // Query the visible rows belong to. Activation waits until it matches.
    property string shownFor: ""
    property int expected: 0
    property bool inflight: false
    property string issued: ""
    property int got: 0
    property var batches: ({})

    readonly property int rows: 11
    readonly property string pokePath: Quickshell.env("XDG_RUNTIME_DIR") + "/signalis-launcher.sock"
    readonly property string providerPath: Quickshell.env("XDG_RUNTIME_DIR") + "/signalis-anyrun.sock"

    function toggle() {
        if (open)
            dismiss();
        else
            show();
    }

    function show() {
        open = true;
        query = "";
        input.text = "";
        selected = 0;
        results = home;
        shownFor = "";
        input.forceActiveFocus();
    }

    function dismiss() {
        if (!open)
            return;
        open = false;
        query = "";
    }

    function buildHome() {
        const values = DesktopEntries.applications.values ?? [];
        const rows = [];
        for (let i = 0; i < values.length; i++) {
            const entry = values[i];
            rows.push({
                name: entry.name,
                description: entry.comment || "",
                icon: Quickshell.iconPath(entry.icon || "application-x-executable", "application-x-executable"),
                desktopId: entry.id,
                keys: (entry.keywords || []).join(" ").toLowerCase()
            });
        }
        rows.sort((a, b) => a.name.localeCompare(b.name));
        home = rows;
        if (open && query === "") {
            results = home;
            shownFor = "";
        }
    }

    function localRows(text) {
        if (text === "")
            return home;
        const needle = text.toLowerCase();
        const rows = [];
        for (let i = 0; i < home.length && rows.length < 100; i++) {
            const row = home[i];
            if (row.name.toLowerCase().includes(needle) || (row.description || "").toLowerCase().includes(needle) || row.keys.includes(needle))
                rows.push(row);
        }
        return rows;
    }

    function paintLocal() {
        results = localRows(query);
        shownFor = query;
        if (selected >= results.length)
            selected = Math.max(0, results.length - 1);
    }

    // One query at a time. A newer keystroke paints the local app filter
    // immediately and is sent when the current reply finishes.
    function requestSearch() {
        paintLocal();
        if (query === "" || !link.connected || expected === 0 || inflight)
            return;
        inflight = true;
        issued = query;
        got = 0;
        batches = {};
        stall.restart();
        link.write(JSON.stringify({
            Query: {
                text: query
            }
        }) + "\n");
        link.flush();
    }

    function onQueryEdited(text) {
        if (text === query)
            return;
        query = text;
        selected = 0;
        requestSearch();
    }

    function finishSearch() {
        inflight = false;
        stall.stop();
        if (issued !== query)
            requestSearch();
    }

    function mergedRows() {
        const rows = [];
        const order = ["Rink", "Websearch", "Shell", "Applications"];
        for (const name of order) {
            const part = batches[name];
            if (part)
                rows.push(...part);
        }
        if (!batches.Applications)
            rows.push(...localRows(issued));
        return rows;
    }

    function paintMerged() {
        if (issued !== query)
            return;
        results = mergedRows();
        shownFor = query;
        if (selected >= results.length)
            selected = Math.max(0, results.length - 1);
    }

    function matchRow(plugin, match) {
        const iconName = unwrap(match.icon) || plugin.icon || "application-x-executable";
        return {
            name: match.title,
            description: unwrap(match.description) || "",
            icon: iconName.startsWith("/") ? iconName : Quickshell.iconPath(iconName, "application-x-executable"),
            plugin: plugin,
            match: match
        };
    }

    function unwrap(value) {
        if (value == null || value === "RNone")
            return "";
        if (typeof value === "object" && value.RSome !== undefined)
            return value.RSome;
        return value;
    }

    function bytesToString(bytes) {
        if (typeof bytes === "string")
            return bytes;
        if (typeof TextDecoder !== "undefined")
            return new TextDecoder().decode(new Uint8Array(bytes));
        return String.fromCharCode.apply(null, bytes);
    }

    function activateSelection() {
        if (shownFor !== query || selected < 0 || selected >= results.length)
            return;
        const row = results[selected];
        if (row.desktopId) {
            const entry = DesktopEntries.byId(row.desktopId);
            if (!entry)
                return;
            if (entry.runInTerminal)
                Niri.action("spawn", "--", "ghostty", "-e", ...entry.command);
            else
                entry.execute();
            dismiss();
            return;
        }
        if (!row.match || !link.connected)
            return;
        link.write(JSON.stringify({
            Handle: {
                plugin: row.plugin,
                selection: row.match
            }
        }) + "\n");
        link.flush();
    }

    function handle(message) {
        if (message.Ready) {
            expected = message.Ready.info.length;
            if (query !== "")
                requestSearch();
            return;
        }
        if (message.Matches) {
            if (!inflight)
                return;
            const next = Object.assign({}, batches);
            next[message.Matches.plugin.name] = message.Matches.matches.map(match => matchRow(message.Matches.plugin, match));
            batches = next;
            got++;
            paintMerged();
            if (got >= expected)
                finishSearch();
            return;
        }
        if (message.Handled) {
            const result = message.Handled.result;
            if (result === "Close")
                dismiss();
            else if (result && result.Copy) {
                Quickshell.execDetached(["wl-copy", bytesToString(result.Copy)]);
                dismiss();
            } else if (result && result.Refresh !== undefined)
                requestSearch();
        }
    }

    function providerCommand() {
        const cmd = [Quickshell.env("SIGNALIS_ANYRUN_PROVIDER"), "--config-dir", Quickshell.env("SIGNALIS_ANYRUN_CONFIG")];
        const plugins = (Quickshell.env("SIGNALIS_ANYRUN_PLUGINS") || "").split(":").filter(plugin => plugin !== "");
        for (const plugin of plugins)
            cmd.push("--plugins", plugin);
        cmd.push("socket", "--path", providerPath);
        return cmd;
    }

    function startProvider() {
        provider.command = providerCommand();
        provider.running = true;
    }

    function ingest(line) {
        const trimmed = line.trim();
        if (trimmed === "")
            return;
        try {
            handle(JSON.parse(trimmed));
        } catch (e) {
            console.warn("launcher:", e, trimmed);
        }
    }

    Component.onCompleted: buildHome()

    Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            root.buildHome();
            root.inflight = false;
            stall.stop();
            if (!link.connected)
                return;
            // Reload plugin state, including the desktop index, before the next query.
            link.write(JSON.stringify("Reset") + "\n");
            link.flush();
            if (root.query !== "")
                root.requestSearch();
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle();
        }
    }

    // Stale socket files make the next bind fail, so remove them before listening.
    Process {
        id: initialWipe
        command: ["rm", "-f", root.pokePath, root.providerPath]
        running: true
        onExited: code => {
            if (code !== 0)
                return;
            poke.active = true;
            root.startProvider();
        }
    }

    SocketServer {
        id: poke
        path: root.pokePath
        handler: Socket {
            parser: SplitParser {
                onRead: line => {
                    if (line.trim() === "toggle")
                        root.toggle();
                }
            }
        }
    }

    Process {
        id: provider
        onStarted: {
            link.connected = false;
            retry.restart();
        }
        onExited: providerRestart.restart()
    }

    Timer {
        id: providerRestart
        interval: 1000
        onTriggered: providerSockWipe.running = true
    }

    Process {
        id: providerSockWipe
        command: ["rm", "-f", root.providerPath]
        onExited: root.startProvider()
    }

    Socket {
        id: link
        path: root.providerPath
        onError: retry.restart()
        onConnectedChanged: {
            if (!connected)
                retry.restart();
        }
        parser: SplitParser {
            onRead: line => root.ingest(line)
        }
    }

    Timer {
        id: retry
        interval: 200
        onTriggered: {
            if (!link.connected)
                link.connected = true;
        }
    }

    // A plugin that never answers must not pin the following keystrokes.
    // Dropping the socket discards a reply that belongs to the old text.
    Timer {
        id: stall
        interval: 500
        onTriggered: {
            root.inflight = false;
            link.connected = false;
            retry.restart();
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
            onClicked: root.dismiss()
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
                                onTextChanged: root.onQueryEdited(text)
                                onVisibleChanged: if (visible) forceActiveFocus()

                                Keys.onPressed: event => {
                                    const count = root.results.length;
                                    if (event.key === Qt.Key_Escape) {
                                        root.dismiss();
                                    } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier)) || (event.key === Qt.Key_N && event.modifiers & Qt.ControlModifier)) {
                                        if (count > 0)
                                            root.selected = Math.min(count - 1, root.selected + 1);
                                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_P && event.modifiers & Qt.ControlModifier)) {
                                        root.selected = Math.max(0, root.selected - 1);
                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.activateSelection();
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
                                width: parent.width - 16

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 16
                                    source: row.modelData.entry.icon
                                }

                                Txt {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.min(implicitWidth, parent.width - (row.current && row.modelData.entry.description ? 176 : 26))
                                    elide: Text.ElideRight
                                    text: row.modelData.entry.name
                                    color: row.current ? Theme.bg : Theme.soft
                                }
                            }

                            Txt {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth, 160)
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignRight
                                visible: row.current && text !== ""
                                text: row.modelData.entry.description
                                caps: true
                                color: Theme.selection
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.selected = row.modelData.index;
                                    root.activateSelection();
                                }
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
