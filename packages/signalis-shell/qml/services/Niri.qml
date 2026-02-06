pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// niri state from `niri msg --json event-stream`.
Singleton {
    id: root

    property var workspaces: []
    property var windows: ({})
    property var focusedWindowId: null
    property var layouts: []
    property int layoutIndex: 0
    property bool overviewOpen: false

    readonly property var focusedWindow: focusedWindowId !== null ? (windows[focusedWindowId] ?? null) : null
    // "English (US)" -> "EN", "Russian" -> "RU"
    readonly property string layout: layouts.length > layoutIndex ? layouts[layoutIndex].slice(0, 2).toUpperCase() : ""

    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output).sort((a, b) => a.idx - b.idx);
    }

    function action(...args) {
        Quickshell.execDetached(["niri", "msg", "action", ...args]);
    }

    function setWorkspaces(list) {
        workspaces = list;
    }

    function handle(event) {
        const [kind, data] = Object.entries(event)[0];
        switch (kind) {
        case "WorkspacesChanged":
            setWorkspaces(data.workspaces);
            break;
        case "WorkspaceActivated": {
            const target = workspaces.find(w => w.id === data.id);
            if (!target)
                break;
            setWorkspaces(workspaces.map(w => Object.assign({}, w, {
                is_active: w.output === target.output ? w.id === data.id : w.is_active,
                is_focused: data.focused ? w.id === data.id : w.is_focused
            })));
            break;
        }
        case "WorkspaceUrgencyChanged":
            setWorkspaces(workspaces.map(w => w.id === data.id ? Object.assign({}, w, {
                is_urgent: data.urgent
            }) : w));
            break;
        case "WorkspaceActiveWindowChanged":
            setWorkspaces(workspaces.map(w => w.id === data.workspace_id ? Object.assign({}, w, {
                active_window_id: data.active_window_id
            }) : w));
            break;
        case "WindowsChanged": {
            const map = {};
            for (const w of data.windows) {
                map[w.id] = w;
                if (w.is_focused)
                    focusedWindowId = w.id;
            }
            windows = map;
            break;
        }
        case "WindowOpenedOrChanged": {
            const map = Object.assign({}, windows);
            map[data.window.id] = data.window;
            windows = map;
            if (data.window.is_focused)
                focusedWindowId = data.window.id;
            break;
        }
        case "WindowClosed": {
            const map = Object.assign({}, windows);
            delete map[data.id];
            windows = map;
            if (focusedWindowId === data.id)
                focusedWindowId = null;
            break;
        }
        case "WindowFocusChanged":
            focusedWindowId = data.id;
            break;
        case "KeyboardLayoutsChanged":
            layouts = data.keyboard_layouts.names;
            layoutIndex = data.keyboard_layouts.current_idx;
            break;
        case "KeyboardLayoutSwitched":
            layoutIndex = data.idx;
            break;
        case "OverviewOpenedOrClosed":
            overviewOpen = data.is_open;
            break;
        }
    }

    Process {
        id: stream
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.handle(JSON.parse(line));
                } catch (e) {
                    console.warn("niri: bad event", e);
                }
            }
        }
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 1000
        onTriggered: stream.running = true
    }
}
