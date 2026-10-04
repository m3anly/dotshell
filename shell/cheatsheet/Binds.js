.pragma library

const modifiers = {
    mod: "Super",
    super: "Super",
    win: "Super",
    ctrl: "Ctrl",
    control: "Ctrl",
    alt: "Alt",
    shift: "Shift",
    iso_level3_shift: "AltGr",
    iso_level5_shift: "Mod5"
};

const keyNames = {
    slash: "/",
    backslash: "\\",
    comma: ",",
    period: ".",
    minus: "-",
    equal: "=",
    plus: "+",
    semicolon: ";",
    apostrophe: "'",
    grave: "`",
    bracketleft: "[",
    bracketright: "]",
    return: "Enter",
    space: "Space",
    tab: "Tab",
    escape: "Esc",
    backspace: "Bksp",
    delete: "Del",
    insert: "Ins",
    print: "PrtSc",
    page_down: "PgDn",
    page_up: "PgUp",
    home: "Home",
    end: "End",
    left: "←",
    right: "→",
    up: "↑",
    down: "↓",
    wheelscrolldown: "Wheel ↓",
    wheelscrollup: "Wheel ↑",
    wheelscrollleft: "Wheel ←",
    wheelscrollright: "Wheel →",
    touchpadscrolldown: "Swipe ↓",
    touchpadscrollup: "Swipe ↑",
    touchpadscrollleft: "Swipe ←",
    touchpadscrollright: "Swipe →",
    xf86audioraisevolume: "Vol +",
    xf86audiolowervolume: "Vol −",
    xf86audiomute: "Mute",
    xf86audiomicmute: "Mic mute",
    xf86audioplay: "Play",
    xf86audiopause: "Pause",
    xf86audionext: "Next",
    xf86audioprev: "Prev",
    xf86monbrightnessup: "Bri +",
    xf86monbrightnessdown: "Bri −"
};

const ipcTitles = {
    "launcher toggle": "Launcher",
    "launcher clipboard": "Clipboard",
    "panels power": "Power menu",
    "panels quickSettings": "Quick settings",
    "panels system": "System",
    "gamemode toggle": "Game mode",
    "notifications toggle": "Notification center",
    "cheatsheet toggle": "Keybinds",
    "audio increment": "Volume up",
    "audio decrement": "Volume down",
    "audio mute": "Mute",
    "audio micmute": "Mute microphone",
    "mpris playPause": "Play or pause",
    "mpris next": "Next track",
    "mpris previous": "Previous track",
    "mpris increment": "Player volume up",
    "mpris decrement": "Player volume down",
    "brightness increment": "Brightness up",
    "brightness decrement": "Brightness down"
};

const groupAliases = {
    window: "Windows",
    workspace: "Workspaces",
    app: "Apps",
    utility: "Utilities"
};

const groupOrder = ["Shell", "Apps", "Windows", "Workspaces", "Media", "Utilities", "Session"];

function keys(combo) {
    const parts = combo.split("+").filter(part => part !== "");
    if (combo.endsWith("++"))
        parts.push("+");
    return parts.map((part, index) => {
        const lower = part.toLowerCase();
        if (index < parts.length - 1 && modifiers[lower])
            return modifiers[lower];
        if (keyNames[lower])
            return keyNames[lower];
        if (part.length === 1)
            return part.toUpperCase();
        return part.replace(/^XF86/, "").replace(/_/g, " ");
    });
}

function humanize(name, args) {
    const shown = (args ?? []).filter(arg => typeof arg === "number" || (typeof arg === "string" && arg.length <= 12));
    const text = [name.replace(/-/g, " "), ...shown].join(" ");
    return text.charAt(0).toUpperCase() + text.slice(1);
}

function spawnTitle(args) {
    const call = args.indexOf("call");
    if (args.includes("ipc") && call >= 0) {
        const key = `${args[call + 1]} ${args[call + 2]}`;
        return ipcTitles[key] ?? humanize(`${args[call + 1]} ${args[call + 2] ?? ""}`.trim());
    }
    const program = String(args[0] ?? "").split("/").pop();
    return program === "" ? "Run command" : `Run ${program}`;
}

function groupOf(key, action) {
    if (/^(.*\+)?XF86/i.test(key))
        return "Media";
    if (action.includes("workspace"))
        return "Workspaces";
    if (/column|window|monitor|maximize|fullscreen|floating|tiling|consume|expel|width|height/.test(action))
        return "Windows";
    if (action === "spawn" || action === "spawn-sh")
        return "Apps";
    return "Session";
}

function collect(nodes) {
    const byKey = new Map();
    for (const node of nodes) {
        if (node.name !== "binds")
            continue;
        for (const bind of node.children) {
            const action = bind.children[0];
            if (!action)
                continue;
            const hasTitle = Object.prototype.hasOwnProperty.call(bind.props, "hotkey-overlay-title");
            const rawTitle = bind.props["hotkey-overlay-title"];
            if (hasTitle && rawTitle === null) {
                byKey.delete(bind.name.toLowerCase());
                continue;
            }
            let title = hasTitle ? String(rawTitle) : action.name.startsWith("spawn") ? spawnTitle(action.args.map(String)) : humanize(action.name, action.args);
            let group = groupOf(bind.name, action.name);
            const split = title.indexOf(" | ");
            if (split > 0) {
                group = title.slice(0, split);
                group = groupAliases[group.toLowerCase()] ?? group;
                title = title.slice(split + 3);
            }
            byKey.delete(bind.name.toLowerCase());
            byKey.set(bind.name.toLowerCase(), {
                combo: bind.name,
                keys: keys(bind.name),
                title: title,
                group: group
            });
        }
    }
    return Array.from(byKey.values());
}

function grouped(binds, query) {
    const needle = query.trim().toLowerCase();
    const groups = new Map();
    for (const bind of binds) {
        if (needle !== "" && !`${bind.group} ${bind.title} ${bind.keys.join(" ")} ${bind.combo}`.toLowerCase().includes(needle))
            continue;
        if (!groups.has(bind.group))
            groups.set(bind.group, []);
        groups.get(bind.group).push(bind);
    }
    const rank = name => {
        const index = groupOrder.indexOf(name);
        return index < 0 ? groupOrder.length : index;
    };
    return Array.from(groups, ([name, rows]) => ({ name: name, rows: rows })).sort((a, b) => rank(a.name) - rank(b.name));
}

const headerCost = 1;
const gapCost = 0.7;
const minimumChunk = 2;

function pack(groups, count, capacity) {
    const result = [[]];
    let used = 0;
    for (const group of groups) {
        let rows = group.rows;
        let continued = false;
        while (rows.length > 0) {
            const column = result[result.length - 1];
            const cost = headerCost + (column.length > 0 ? gapCost : 0);
            const room = Math.floor(capacity - used - cost);
            if (room >= rows.length) {
                column.push({ name: group.name, rows: rows, continued: continued });
                used += cost + rows.length;
                break;
            }
            const take = Math.min(room, rows.length - minimumChunk);
            if (take >= minimumChunk) {
                column.push({ name: group.name, rows: rows.slice(0, take), continued: continued });
                rows = rows.slice(take);
                continued = true;
            }
            if (result.length === count)
                return null;
            result.push([]);
            used = 0;
        }
    }
    while (result.length < count)
        result.push([]);
    return result;
}

function columns(groups, count) {
    if (groups.length === 0)
        return Array.from({ length: count }, () => []);
    const total = groups.reduce((sum, group) => sum + group.rows.length + headerCost + gapCost, 0);
    for (let capacity = Math.ceil(total / count); ; capacity++) {
        const result = pack(groups, count, capacity);
        if (result !== null)
            return result;
    }
}
