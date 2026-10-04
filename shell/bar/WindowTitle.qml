import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

Bay {
    id: bay

    readonly property var window: Niri.focusedWindow
    readonly property int workspaceIdx: Niri.focusedWorkspace?.idx ?? 0
    property int previousWorkspaceIdx: 0
    property int direction: 1

    onWorkspaceIdxChanged: {
        direction = workspaceIdx >= previousWorkspaceIdx ? 1 : -1;
        previousWorkspaceIdx = workspaceIdx;
    }

    RollText {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        color: Theme.fg2
        direction: bay.direction
        rollKey: `${bay.window?.id ?? ""}:${bay.workspaceIdx}`
        text: {
            const w = bay.window;
            if (!w)
                return "Desktop";
            const app = Apps.nameFor(w.app_id ?? "");
            const title = w.title ?? "";
            return app && title ? `${app} · ${title}` : app || title || "Window";
        }
    }
}
