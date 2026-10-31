import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property string directory
    required property var defaults
    readonly property string path: `${directory}/config.json`
    readonly property string userPath: `${directory}/settings.json`
    property var pinned: ({})
    property var user: ({})
    property bool pendingSave: false

    function lookup(source: var, key: string): var {
        let node = source;
        for (const part of key.split(".")) {
            if (node === null || typeof node !== "object" || Array.isArray(node) || !(part in node))
                return undefined;
            node = node[part];
        }
        return node;
    }

    function kind(item: var): string {
        if (Array.isArray(item))
            return "array";
        return item === null ? "null" : typeof item;
    }

    function fits(key: string, candidate: var): bool {
        return candidate !== undefined && kind(candidate) === kind(lookup(defaults, key));
    }

    function isPinned(key: string): bool {
        return fits(key, lookup(pinned, key));
    }

    function value(key: string): var {
        const fromPinned = lookup(pinned, key);
        if (fits(key, fromPinned))
            return fromPinned;
        const fromUser = lookup(user, key);
        if (fits(key, fromUser))
            return fromUser;
        return lookup(defaults, key);
    }

    function withValue(source: var, parts: var, item: var): var {
        const copy = Object.assign({}, kind(source) === "object" ? source : {});
        const [head, ...rest] = parts;
        if (rest.length === 0) {
            if (item === undefined)
                delete copy[head];
            else
                copy[head] = item;
            return copy;
        }
        const child = withValue(copy[head], rest, item);
        if (Object.keys(child).length === 0)
            delete copy[head];
        else
            copy[head] = child;
        return copy;
    }

    function set(key: string, item: var): void {
        if (isPinned(key) || !fits(key, item))
            return;
        user = withValue(user, key.split("."), item);
        save();
    }

    function reset(key: string): void {
        if (lookup(user, key) === undefined)
            return;
        user = withValue(user, key.split("."), undefined);
        save();
    }

    function save(): void {
        pendingSave = true;
        if (!makeDirectory.running)
            makeDirectory.running = true;
    }

    function parse(text: string): var {
        try {
            const parsed = JSON.parse(text);
            return kind(parsed) === "object" ? parsed : null;
        } catch (e) {
            return null;
        }
    }

    FileView {
        id: pinnedFile

        property bool missing: false

        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            missing = false;
            root.pinned = root.parse(text()) ?? root.pinned;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                return;
            missing = true;
            root.pinned = {};
        }
    }

    Process {
        id: makeDirectory

        command: ["mkdir", "-p", root.directory]
        onExited: {
            if (!root.pendingSave)
                return;
            root.pendingSave = false;
            userFile.setText(`${JSON.stringify(root.user, null, 2)}\n`);
        }
    }

    FileView {
        id: userFile

        property bool missing: false

        path: root.userPath
        watchChanges: true
        printErrors: false
        atomicWrites: true
        onFileChanged: reload()
        onLoaded: {
            missing = false;
            root.user = root.parse(text()) ?? root.user;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                return;
            missing = true;
            root.user = {};
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: pinnedFile.missing || userFile.missing
        onTriggered: {
            if (pinnedFile.missing)
                pinnedFile.reload();
            if (userFile.missing && !root.pendingSave)
                userFile.reload();
        }
    }
}
