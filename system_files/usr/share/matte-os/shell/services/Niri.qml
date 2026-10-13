pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Follows niri through `niri msg --json event-stream` and keeps a small picture of the desktop:
// which workspace is showing on each monitor, its columns, and which column has focus.
Singleton {
    id: root

    // Per monitor: { workspaceId, workspaceIndex, columns, focusedColumn (0-based, -1 = none) }
    property var outputs: ({})
    property string focusedOutput: ""
    property string focusedTitle: ""
    property string focusedAppId: ""

    property var _workspaces: ({})   // id -> workspace
    property var _windows: ({})      // id -> window

    function columnsOn(output) {
        return root.outputs[output] ?? { workspaceId: -1, workspaceIndex: 0, columns: 0, focusedColumn: -1 };
    }

    function action(...args) {
        Quickshell.execDetached(["niri", "msg", "action", ...args]);
    }

    function _recompute() {
        const result = {};
        let focusedOutput = "";
        for (const id in root._workspaces) {
            const ws = root._workspaces[id];
            if (ws.is_focused)
                focusedOutput = ws.output ?? "";
            if (!ws.is_active || !ws.output)
                continue;

            // Columns are the distinct column positions of tiled windows on this workspace.
            const columns = new Set();
            let focusedColumn = -1;
            for (const wid in root._windows) {
                const w = root._windows[wid];
                if (w.workspace_id !== ws.id || w.is_floating)
                    continue;
                const pos = w.layout?.pos_in_scrolling_layout;
                if (!pos)
                    continue;
                columns.add(pos[0]);
                if (w.id === ws.active_window_id)
                    focusedColumn = pos[0];
            }
            const ordered = Array.from(columns).sort((a, b) => a - b);
            result[ws.output] = {
                workspaceId: ws.id,
                workspaceIndex: ws.idx,
                columns: ordered.length,
                focusedColumn: ordered.indexOf(focusedColumn)
            };
        }

        let title = "", appId = "";
        for (const wid in root._windows) {
            const w = root._windows[wid];
            if (w.is_focused) {
                title = w.title ?? "";
                appId = w.app_id ?? "";
            }
        }

        root.outputs = result;
        root.focusedOutput = focusedOutput;
        root.focusedTitle = title;
        root.focusedAppId = appId;
    }

    function _handle(line) {
        let event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return;
        }

        if (event.WorkspacesChanged) {
            const map = {};
            for (const ws of event.WorkspacesChanged.workspaces)
                map[ws.id] = ws;
            root._workspaces = map;
        } else if (event.WorkspaceActivated) {
            const { id, focused } = event.WorkspaceActivated;
            const target = root._workspaces[id];
            if (!target)
                return;
            for (const key in root._workspaces) {
                const ws = root._workspaces[key];
                if (ws.output === target.output)
                    ws.is_active = ws.id === id;
                if (focused)
                    ws.is_focused = ws.id === id;
            }
        } else if (event.WorkspaceActiveWindowChanged) {
            const ws = root._workspaces[event.WorkspaceActiveWindowChanged.workspace_id];
            if (ws)
                ws.active_window_id = event.WorkspaceActiveWindowChanged.active_window_id;
        } else if (event.WindowsChanged) {
            const map = {};
            for (const w of event.WindowsChanged.windows)
                map[w.id] = w;
            root._windows = map;
        } else if (event.WindowOpenedOrChanged) {
            const w = event.WindowOpenedOrChanged.window;
            if (w.is_focused) {
                for (const key in root._windows)
                    root._windows[key].is_focused = false;
            }
            root._windows[w.id] = w;
        } else if (event.WindowClosed) {
            delete root._windows[event.WindowClosed.id];
        } else if (event.WindowFocusChanged) {
            const id = event.WindowFocusChanged.id;
            for (const key in root._windows)
                root._windows[key].is_focused = root._windows[key].id === id;
        } else if (event.WindowLayoutsChanged) {
            for (const [id, layout] of event.WindowLayoutsChanged.changes) {
                if (root._windows[id])
                    root._windows[id].layout = layout;
            }
        } else {
            return;
        }
        root._recompute();
    }

    Process {
        id: stream
        command: ["niri", "msg", "--json", "event-stream"]
        running: Quickshell.env("NIRI_SOCKET") !== undefined
        stdout: SplitParser {
            onRead: line => root._handle(line)
        }
        // niri restarts with the session; if the stream drops, reconnect shortly after.
        onRunningChanged: if (!running) restart.start()
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: stream.running = Quickshell.env("NIRI_SOCKET") !== undefined
    }
}
