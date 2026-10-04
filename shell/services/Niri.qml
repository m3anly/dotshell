pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property var workspaces: []
    property var windows: ({})
    property int focusedWindowId: -1
    property var layoutNames: []
    property int layoutIndex: 0
    property bool overviewOpen: false

    readonly property var focusedWindow: windows[focusedWindowId] ?? null
    readonly property var focusedWorkspace: workspaces.find(ws => ws.is_focused) ?? null
    readonly property string layoutShort: layoutNames.length > 0 ? shortLayout(layoutNames[layoutIndex] ?? "") : ""

    readonly property var occupiedWorkspaceIds: {
        const ids = {};
        for (const id in windows)
            if (windows[id].workspace_id != null)
                ids[windows[id].workspace_id] = true;
        return ids;
    }

    function workspacesOn(output: string): var {
        return workspaces.filter(ws => ws.output === output).sort((a, b) => a.idx - b.idx);
    }

    function activeWorkspaceOn(output: string): var {
        return workspaces.find(ws => ws.output === output && ws.is_active) ?? null;
    }

    function shortLayout(name: string): string {
        return Config.keyboardLayouts[name] ?? name.slice(0, 2).toUpperCase();
    }

    function action(...args): void {
        Quickshell.execDetached(["niri", "msg", "action", ...args]);
    }

    function focusWorkspace(idx: int): void {
        action("focus-workspace", String(idx));
    }

    function focusWorkspaceRelative(step: int): void {
        action(step > 0 ? "focus-workspace-down" : "focus-workspace-up");
    }

    function focusColumnRelative(step: int): void {
        action(step > 0 ? "focus-column-right" : "focus-column-left");
    }

    function focusMonitor(output: string): void {
        action("focus-monitor", output);
    }

    function focusWindow(id: int): void {
        action("focus-window", "--id", String(id));
    }

    function nextLayout(): void {
        action("switch-layout", "next");
    }

    function quit(): void {
        action("quit", "--skip-confirmation");
    }

    function handle(line: string): void {
        let event;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return;
        }
        const kind = Object.keys(event)[0];
        const body = event[kind];
        switch (kind) {
        case "WorkspacesChanged":
            workspaces = body.workspaces;
            break;
        case "WorkspaceActivated":
            {
                const target = workspaces.find(ws => ws.id === body.id);
                if (!target)
                    break;
                workspaces = workspaces.map(ws => Object.assign({}, ws, {
                        is_active: ws.output === target.output ? ws.id === body.id : ws.is_active,
                        is_focused: body.focused ? ws.id === body.id : ws.is_focused
                    }));
                break;
            }
        case "WorkspaceActiveWindowChanged":
            workspaces = workspaces.map(ws => ws.id === body.workspace_id ? Object.assign({}, ws, {
                        active_window_id: body.active_window_id
                    }) : ws);
            break;
        case "WorkspaceUrgencyChanged":
            workspaces = workspaces.map(ws => ws.id === body.id ? Object.assign({}, ws, {
                        is_urgent: body.urgent
                    }) : ws);
            break;
        case "WindowsChanged":
            {
                const next = {};
                let focused = -1;
                for (const w of body.windows) {
                    next[w.id] = w;
                    if (w.is_focused)
                        focused = w.id;
                }
                windows = next;
                focusedWindowId = focused;
                break;
            }
        case "WindowOpenedOrChanged":
            {
                const w = body.window;
                const next = Object.assign({}, windows);
                if (w.is_focused)
                    for (const id in next)
                        if (next[id].is_focused)
                            next[id] = Object.assign({}, next[id], {
                                is_focused: false
                            });
                next[w.id] = w;
                windows = next;
                if (w.is_focused)
                    focusedWindowId = w.id;
                break;
            }
        case "WindowClosed":
            {
                const next = Object.assign({}, windows);
                delete next[body.id];
                windows = next;
                if (focusedWindowId === body.id)
                    focusedWindowId = -1;
                break;
            }
        case "WindowFocusChanged":
            focusedWindowId = body.id ?? -1;
            break;
        case "KeyboardLayoutsChanged":
            layoutNames = body.keyboard_layouts.names;
            layoutIndex = body.keyboard_layouts.current_idx;
            break;
        case "KeyboardLayoutSwitched":
            layoutIndex = body.idx;
            break;
        case "OverviewOpenedOrClosed":
            overviewOpen = body.is_open;
            break;
        }
    }

    Process {
        id: stream

        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: data => root.handle(data)
        }
        onExited: restart.start()
    }

    Timer {
        id: restart

        interval: 1000
        onTriggered: stream.running = true
    }
}
