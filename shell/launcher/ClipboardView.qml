import QtQuick
import qs.components
import qs.services

ViewSlide {
    id: root

    property bool live: false
    property bool stagger: false
    property string query: ""
    readonly property alias list: list
    readonly property var rows: live && active ? build(query.trim()) : []

    implicitHeight: 500

    onQueryChanged: list.reset()
    onActiveChanged: {
        if (active)
            list.reset();
    }

    function build(text: string): var {
        const entries = Clipboard.search(text, true);
        const rows = [];
        const section = (key, title, members) => {
            if (members.length === 0)
                return;
            rows.push({
                key: key,
                kind: "header",
                title: title,
                aside: String(members.length)
            });
            members.forEach(entry => rows.push({
                    key: `clip:${entry.key}`,
                    kind: "clipItem",
                    selectable: true,
                    entry: entry
                }));
        };
        section("header:pinned", "Pinned", entries.filter(entry => entry.pinned));
        section("header:recent", "Recent", entries.filter(entry => !entry.pinned));
        if (rows.length === 0)
            rows.push({
                key: "note",
                kind: "note",
                text: text === "" ? "Clipboard history is empty" : "No matches"
            });
        return rows;
    }

    function run(item: var, shift: bool): void {
        if (shift) {
            list.followTop = false;
            Clipboard.copy(item.entry);
            return;
        }
        list.afterPulse(() => {
            Ui.closeAll();
            Clipboard.paste(item.entry);
        });
    }

    function togglePin(): void {
        if (!list.current)
            return;
        list.followTop = false;
        Clipboard.togglePin(list.current.entry);
    }

    function removeSelected(): void {
        if (!list.current)
            return;
        list.followTop = false;
        list.leavingKey = list.current.key;
        Clipboard.remove(list.current.entry);
    }

    LauncherList {
        id: list

        x: 10
        width: 310
        height: parent.height
        topMargin: 10
        bottomMargin: 10
        clip: true
        rows: root.rows
        stagger: root.stagger
        onActivated: (item, shift) => root.run(item, shift)
    }

    DottedLine {
        x: 330
        height: parent.height
    }

    ClipPreview {
        x: 332
        width: parent.width - 332
        height: parent.height
        entry: list.current?.entry ?? null
    }
}
