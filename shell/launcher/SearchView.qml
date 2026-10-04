import QtQuick
import qs.config
import qs.services
import "LauncherLogic.js" as Logic

ViewSlide {
    id: root

    property bool live: false
    property bool stagger: false
    property string query: ""
    readonly property alias list: list
    readonly property var rows: live && active ? build(query.trim()) : []
    readonly property string primaryLabel: {
        switch (list.current?.kind) {
        case "calc":
            return "Copy result";
        case "clip":
            return "Paste";
        default:
            return "Open";
        }
    }

    enterFrom: -1
    implicitHeight: list.contentHeight + 20

    onQueryChanged: list.reset()
    onActiveChanged: {
        if (active)
            list.reset();
    }

    function clipRow(entry: var): var {
        return {
            key: `clip:${entry.key}`,
            kind: "clip",
            selectable: true,
            entry: entry
        };
    }

    function appRow(entry: var, indices: var): var {
        return {
            key: `app:${entry.id}`,
            kind: "app",
            selectable: true,
            entry: entry,
            indices: indices,
            sub: appSub(entry)
        };
    }

    function appSub(entry: var): string {
        const workspace = Apps.workspaceOf(entry);
        const used = Apps.lastUsed(entry);
        const origin = used > 0 ? `Used ${Logic.ageText((Date.now() - used) / 1000).toLowerCase()}` : "Application";
        return workspace >= 0 ? `${origin} · open on workspace ${workspace}` : origin;
    }

    function build(text: string): var {
        const rows = [];
        if (text === "") {
            const frequent = Config.launcher.showFrequent ? Apps.frequent(Math.max(1, Config.launcher.frequentCount)) : [];
            if (frequent.length === 0)
                return [
                    {
                        key: "note",
                        kind: "note",
                        text: "Type to search apps or calculate"
                    }
                ];
            rows.push({
                key: "header:frequent",
                kind: "header",
                title: "Frequent",
                aside: String(frequent.length)
            });
            frequent.forEach(entry => rows.push(appRow(entry, [])));
            return rows;
        }
        const calculation = calculator.result;
        if (calculation) {
            rows.push({
                key: "header:calculator",
                kind: "header",
                title: calculation.title,
                aside: ""
            });
            rows.push({
                key: "calc",
                kind: "calc",
                selectable: true,
                calculation: calculation
            });
        }
        const apps = Logic.rankApps(Apps.entries, text, Apps.usageScores(), Math.max(1, Config.launcher.appResults));
        if (apps.length > 0) {
            rows.push({
                key: "header:apps",
                kind: "header",
                title: "Applications",
                aside: String(apps.length)
            });
            apps.forEach(match => rows.push(appRow(match.entry, match.indices)));
        }
        const clips = Clipboard.search(text, false).filter(entry => entry.type !== "image").slice(0, Math.max(0, Config.launcher.clipboardResults));
        if (clips.length > 0) {
            rows.push({
                key: "header:clipboard",
                kind: "header",
                title: "Clipboard",
                aside: String(clips.length)
            });
            clips.forEach(entry => rows.push(clipRow(entry)));
        }
        if (rows.length === 0)
            rows.push({
                key: "note",
                kind: "note",
                text: `No results for “${text}”`
            });
        return rows;
    }

    function run(item: var, shift: bool): void {
        switch (item.kind) {
        case "app":
            list.afterPulse(() => Apps.open(item.entry));
            break;
        case "calc":
            list.afterPulse(() => {
                Ui.closeAll();
                Clipboard.copyText(item.calculation.plain, `${item.calculation.title} · ${item.calculation.pretty}`);
            });
            break;
        case "clip":
            if (shift) {
                list.followTop = false;
                Clipboard.copy(item.entry);
                break;
            }
            list.afterPulse(() => {
                Ui.closeAll();
                Clipboard.paste(item.entry);
            });
            break;
        }
    }

    Calculator {
        id: calculator

        query: root.live && root.active ? root.query.trim() : ""
    }

    LauncherList {
        id: list

        x: 10
        y: 10
        width: parent.width - 20
        height: contentHeight
        cacheBuffer: 2000
        rows: root.rows
        stagger: root.stagger
        onActivated: (item, shift) => root.run(item, shift)
    }
}
