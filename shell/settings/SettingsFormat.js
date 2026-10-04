.pragma library

function splitCommand(text) {
    const parts = [];
    const pattern = /"([^"]*)"|'([^']*)'|(\S+)/g;
    let match;
    while ((match = pattern.exec(text)) !== null)
        parts.push(match[1] !== undefined ? match[1] : match[2] !== undefined ? match[2] : match[3]);
    return parts;
}

function joinCommand(parts) {
    return parts.map(part => part === "" || /[\s"']/.test(part) ? `'${part}'` : part).join(" ");
}

function normalizeColor(text) {
    const value = text.trim();
    const short = /^#?([0-9a-fA-F])([0-9a-fA-F])([0-9a-fA-F])$/.exec(value);
    if (short)
        return `#${short[1]}${short[1]}${short[2]}${short[2]}${short[3]}${short[3]}`.toUpperCase();
    const long = /^#?([0-9a-fA-F]{6})$/.exec(value);
    return long ? `#${long[1]}`.toUpperCase() : "";
}

function withEntry(map, key, value) {
    const copy = Object.assign({}, map);
    if (value === undefined)
        delete copy[key];
    else
        copy[key] = value;
    return copy;
}
