pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../cheatsheet/Kdl.js" as Kdl
import "../cheatsheet/Binds.js" as Binds

Singleton {
    id: root

    readonly property string configPath: Quickshell.env("NIRI_CONFIG") || `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/niri/config.kdl`
    property var binds: []

    function read(path: string): var {
        const file = reader.createObject(root, {
            path: path
        }) as FileView;
        const text = file.text();
        const found = file.loaded;
        file.destroy();
        return found ? text : null;
    }

    function nodesOf(path: string, seen: var): var {
        if (seen.has(path))
            return [];
        seen.add(path);
        const text = read(path);
        if (text === null)
            return [];
        const directory = path.slice(0, path.lastIndexOf("/"));
        const result = [];
        for (const node of Kdl.parse(text)) {
            if (node.name !== "include") {
                result.push(node);
                continue;
            }
            const target = String(node.args[0] ?? "");
            if (target !== "")
                result.push(...nodesOf(target.startsWith("/") ? target : `${directory}/${target}`, seen));
        }
        return result;
    }

    function reload(): void {
        binds = Binds.collect(nodesOf(configPath, new Set()));
    }

    Component {
        id: reader

        FileView {
            blockLoading: true
            printErrors: false
        }
    }
}
