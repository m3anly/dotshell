pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../launcher/LauncherLogic.js" as Logic

Singleton {
    id: root

    readonly property string script: `${Quickshell.shellDir}/scripts/clipdb`
    readonly property string imageDirectory: `${Store.directory}/clipboard/images`
    readonly property int previewLength: 1000
    property var history: []
    property string pendingSource: ""
    property var textCache: ({})
    readonly property var watcherEnvironment: ({
            DOTSHELL_CLIPBOARD_MAX: String(Math.max(1, Math.round(Config.clipboard.maxEntries))),
            DOTSHELL_CLIPBOARD_MAX_TEXT_MIB: String(Math.max(1, Math.round(Config.clipboard.maxTextMiB))),
            DOTSHELL_CLIPBOARD_MAX_IMAGE_MIB: String(Math.max(1, Math.round(Config.clipboard.maxImageMiB)))
        })

    readonly property bool recording: Config.clipboard.enabled

    onRecordingChanged: watcher.running = recording
    onWatcherEnvironmentChanged: {
        if (watcher.running)
            watcher.running = false;
    }
    readonly property var pinned: history.filter(entry => entry.pinned)
    readonly property var recent: history.filter(entry => !entry.pinned)
    readonly property var entries: [...pinned, ...recent]

    function humanSize(bytes: int): string {
        if (bytes < 1024)
            return `${bytes} B`;
        if (bytes < 1024 * 1024)
            return `${Math.round(bytes / 1024)} KiB`;
        return `${(bytes / 1024 / 1024).toFixed(1)} MiB`;
    }

    function fileNames(uriList: string): var {
        return uriList.split(/\r?\n/).filter(line => line !== "" && !line.startsWith("#")).map(uri => {
            const path = uri.replace(/^file:\/\//, "");
            try {
                return decodeURIComponent(path);
            } catch (error) {
                return path;
            }
        });
    }

    function parse(row: var): var {
        const mime = row.mime;
        const extension = mime.split("/")[1]?.toUpperCase() ?? "";
        const entry = {
            key: `entry:${row.id}`,
            id: String(row.id),
            mime: mime,
            pinned: row.pinned === 1,
            text: row.preview,
            complete: row.size <= root.previewLength,
            file: row.file !== "" ? `${root.imageDirectory}/${row.file}` : "",
            imageInfo: "",
            files: [],
            source: row.source,
            time: Math.floor(row.time / 1000)
        };
        if (mime.startsWith("image/")) {
            const dimensions = row.width > 0 ? `${row.width} × ${row.height}` : "";
            entry.type = "image";
            entry.title = dimensions !== "" ? `Image ${dimensions}` : `Image · ${extension}`;
            entry.imageInfo = [dimensions, extension, humanSize(row.size)].filter(Boolean).join(" · ");
        } else if (mime === "text/uri-list") {
            entry.type = "file";
            entry.files = fileNames(row.preview);
            entry.title = entry.files.length === 1 ? entry.files[0].split("/").pop() : `${entry.files.length} files · ${entry.files.map(path => path.split("/").pop()).join(", ")}`;
        } else {
            entry.type = Logic.clipType(row.preview, mime);
            entry.title = Logic.clipTitle(entry.type, row.preview);
        }
        return entry;
    }

    function run(args: var, done: var): void {
        const process = runner.createObject(root, {
            command: ["bash", root.script, ...args],
            done: done ?? null
        });
        process.running = true;
    }

    function refresh(): void {
        lister.running = false;
        lister.running = true;
    }

    function search(query: string, includeSource: bool): var {
        const needle = query.trim().toLowerCase();
        if (needle === "")
            return entries;
        return entries.filter(entry => entry.text.toLowerCase().includes(needle) || entry.title.toLowerCase().includes(needle) || (includeSource && entry.source.toLowerCase().includes(needle)));
    }

    function copy(entry: var): void {
        pendingSource = entry.source;
        Quickshell.execDetached(["bash", root.script, "copy", entry.id]);
    }

    function paste(entry: var): void {
        pendingSource = entry.source;
        Quickshell.execDetached(["bash", "-c", "bash \"$0\" copy \"$1\" && sleep 0.15 && wtype -M ctrl v -m ctrl", root.script, entry.id]);
    }

    function copyText(text: string, source: string): void {
        pendingSource = source;
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    function remove(entry: var): void {
        history = history.filter(other => other.id !== entry.id);
        run(["delete", entry.id], refresh);
    }

    function togglePin(entry: var): void {
        const pinned = !entry.pinned;
        history = history.map(other => other.id === entry.id ? Object.assign({}, other, {
                pinned: pinned
            }) : other);
        run(["pin", entry.id, pinned ? "1" : "0"], refresh);
    }

    function fullText(entry: var, callback: var): void {
        if (entry.complete || entry.type === "image") {
            callback(entry.text);
            return;
        }
        const cached = textCache[entry.id];
        if (cached !== undefined) {
            callback(cached);
            return;
        }
        const process = reader.createObject(root, {
            command: ["bash", root.script, "text", entry.id]
        });
        process.finished.connect(text => {
            root.textCache[entry.id] = text;
            callback(text);
        });
        process.running = true;
    }

    function ignores(appId: string, name: string): bool {
        const candidates = [appId, name].filter(Boolean).map(value => value.toLowerCase());
        return Config.clipboard.ignoreApps.some(app => candidates.includes(String(app).trim().toLowerCase()));
    }

    function stored(line: string): void {
        const [word, id, state] = line.trim().split(" ");
        if (word !== "stored")
            return;
        const appId = Niri.focusedWindow?.app_id ?? "";
        const source = state === "new" ? (pendingSource || (appId !== "" ? Apps.nameFor(appId) : "")) : "";
        const ignored = state === "new" && pendingSource === "" && ignores(appId, source);
        pendingSource = "";
        if (ignored)
            run(["delete", id], refresh);
        else if (source !== "")
            run(["source", id, source], refresh);
        else
            refresh();
    }

    Process {
        id: lister

        command: ["bash", root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.history = JSON.parse(text.trim() || "[]").map(row => root.parse(row));
                } catch (error) {
                    console.warn(`clipboard: cannot read history: ${error}`);
                }
            }
        }
    }

    Process {
        id: watcher

        running: root.recording
        command: ["wl-paste", "--watch", "bash", root.script, "store"]
        environment: root.watcherEnvironment
        stdout: SplitParser {
            onRead: line => root.stored(line)
        }
        onExited: {
            if (root.recording)
                watcherRestart.start();
        }
    }

    Timer {
        id: watcherRestart

        interval: 2000
        onTriggered: watcher.running = root.recording
    }

    Component {
        id: runner

        Process {
            id: process

            property var done: null

            onExited: {
                if (process.done)
                    process.done();
                process.destroy();
            }
        }
    }

    Component {
        id: reader

        Process {
            id: process

            signal finished(string text)

            stdout: StdioCollector {
                onStreamFinished: {
                    process.finished(text);
                    process.destroy();
                }
            }
        }
    }
}
