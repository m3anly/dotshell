pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    readonly property real usageHalfLifeMs: Math.max(1, Config.launcher.usageHalfLifeDays) * 24 * 3600 * 1000
    readonly property int usageLimit: 50
    readonly property var entries: DesktopEntries.applications.values.filter(entry => !entry.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property var windowByEntryId: {
        const map = {};
        for (const id in Niri.windows) {
            const window = Niri.windows[id];
            const entry = window.app_id ? DesktopEntries.heuristicLookup(window.app_id) : null;
            if (entry && map[entry.id] === undefined)
                map[entry.id] = window.id;
        }
        return map;
    }

    function nameFor(appId: string): string {
        if (!appId)
            return "";
        return DesktopEntries.heuristicLookup(appId)?.name ?? appId;
    }

    function byId(id: string): var {
        return entries.find(entry => entry.id === id) ?? null;
    }

    function workspaceOf(entry: var): int {
        const window = Niri.windows[windowByEntryId[entry.id]];
        if (!window)
            return -1;
        return Niri.workspaces.find(workspace => workspace.id === window.workspace_id)?.idx ?? -1;
    }

    function isRunning(entry: var): bool {
        return windowByEntryId[entry.id] !== undefined;
    }

    function monogram(name: string): string {
        const glyph = Array.from(name).find(char => char.toLowerCase() !== char.toUpperCase() || (char >= "0" && char <= "9"));
        return (glyph ?? "·").toUpperCase();
    }

    function resolveIcon(source: string): string {
        const prefix = "image://icon/";
        if (!source.startsWith(prefix) || source.includes("?path="))
            return source;
        const [name, fallback] = source.slice(prefix.length).split("?fallback=");
        if (name.startsWith("/"))
            return `file://${name}`;
        const known = [name, fallback ?? ""].some(icon => icon !== "" && Quickshell.iconPath(icon, true) !== "");
        return known ? source : "";
    }

    function iconFor(entry: var): string {
        const icon = entry?.icon ?? "";
        if (icon === "")
            return "";
        if (icon.startsWith("/"))
            return `file://${icon}`;
        return Quickshell.iconPath(icon, true);
    }

    function usageScores(): var {
        const now = Date.now();
        const scores = {};
        for (const id in Store.appUsage) {
            const usage = Store.appUsage[id];
            scores[id] = usage.score * Math.pow(0.5, (now - usage.time) / usageHalfLifeMs);
        }
        return scores;
    }

    function frequent(limit: int): var {
        const scores = usageScores();
        return Object.keys(scores).sort((a, b) => scores[b] - scores[a]).map(id => byId(id)).filter(entry => entry !== null).slice(0, limit);
    }

    function lastUsed(entry: var): real {
        return Store.appUsage[entry.id]?.time ?? 0;
    }

    function recordLaunch(entry: var): void {
        const scores = usageScores();
        scores[entry.id] = (scores[entry.id] ?? 0) + 1;
        const usage = {};
        Object.keys(scores).sort((a, b) => scores[b] - scores[a]).slice(0, usageLimit).forEach(id => usage[id] = id === entry.id ? {
                score: scores[id],
                time: Date.now()
            } : Store.appUsage[id]);
        Store.appUsage = usage;
    }

    function open(entry: var): void {
        Ui.closeAll();
        recordLaunch(entry);
        const windowId = windowByEntryId[entry.id];
        if (windowId !== undefined)
            Niri.focusWindow(windowId);
        else
            entry.execute();
    }
}
