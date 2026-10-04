.pragma library

function calcExpression(text) {
    const source = text.trim();
    if (!/\d/.test(source))
        return "";
    const hex = /\b0x[\da-f]/i.test(source);
    const expression = (hex ? source : source.replace(/(\d|\))\s*x\s*(?=[\d(.])/gi, "$1×")).replace(/(\d),(?=\d)/g, "$1.").replace(/\s+in\s+(?=[^\s\d]+$)/i, " to ");
    return /[-+*/^%!×÷−()]|\sto\s/i.test(expression) ? expression : "";
}

const currencySymbols = {
    "$": "USD",
    "€": "EUR",
    "£": "GBP",
    "₽": "RUB",
    "¥": "JPY"
};

const amountScales = {
    k: 1e3,
    kk: 1e6
};

function currencyConversion(text) {
    const match = /^(\d+(?:[.,]\d+)?)\s*(kk|k)?\s*([a-z]{3}|[$€£₽¥])\s*(?:to|in)?\s*([a-z]{3}|[$€£₽¥])$/i.exec(text.trim());
    if (!match)
        return null;
    const code = token => currencySymbols[token] ?? token.toUpperCase();
    const amount = +(parseFloat(match[1].replace(",", ".")) * (amountScales[(match[2] ?? "").toLowerCase()] ?? 1)).toPrecision(12);
    const source = code(match[3]);
    const target = code(match[4]);
    return {
        expression: `${amount} ${source} to ${target}`,
        echo: `${amount}${source}`,
        target: target
    };
}

function staleRates(output) {
    return /exchange rates/.test(output);
}

function parseCalculation(output, staleRatesAllowed) {
    const lines = output.split("\n").map(line => line.trim()).filter(line => line !== "");
    const notes = lines.filter(line => /^(error|warning):/.test(line));
    if (notes.some(line => !(staleRatesAllowed && staleRates(line))))
        return null;
    const last = lines.filter(line => !notes.includes(line)).pop() ?? "";
    const parts = last.split(/ ([=≈]) /);
    if (parts.length < 3)
        return null;
    const pretty = parts[0];
    const value = parts[parts.length - 1].replace(/^"(.*)"$/, "$1");
    if (value === pretty)
        return null;
    return {
        value: value.replace(/ /g, " "),
        pretty: pretty.replace(/ /g, " "),
        echo: pretty.replace(/\s/g, ""),
        approximate: parts[parts.length - 2] === "≈",
        plain: value.replace(/(\d) (?=\d)/g, "$1").replace(/ /g, " ").replace(/−/g, "-")
    };
}

function fuzzy(query, text) {
    const haystack = text.toLowerCase();
    let queryIndex = 0;
    let score = 0;
    let last = -2;
    const indices = [];
    for (let k = 0; k < haystack.length && queryIndex < query.length; k++) {
        if (haystack[k] !== query[queryIndex])
            continue;
        let gain = 1;
        if (k === last + 1)
            gain += 3;
        if (k === 0 || /[\s\-_.]/.test(haystack[k - 1]))
            gain += 4;
        score += gain;
        indices.push(k);
        last = k;
        queryIndex++;
    }
    if (queryIndex < query.length)
        return null;
    return {
        score: score - (haystack.length - query.length) * 0.05,
        indices: indices
    };
}

function usageBoost(score) {
    return Math.min(12, 3 * Math.log2(1 + score));
}

function rankApps(entries, query, usageScores, limit) {
    const needle = query.trim().toLowerCase();
    const ranked = [];
    for (const entry of entries) {
        const boost = usageBoost(usageScores[entry.id] ?? 0);
        const nameMatch = fuzzy(needle, entry.name);
        if (nameMatch) {
            ranked.push({
                entry: entry,
                indices: nameMatch.indices,
                score: nameMatch.score + boost
            });
            continue;
        }
        const keywords = [entry.genericName, entry.keywords].filter(Boolean).join(" ");
        const keywordMatch = needle.length > 1 && keywords !== "" ? fuzzy(needle, keywords) : null;
        if (keywordMatch)
            ranked.push({
                entry: entry,
                indices: [],
                score: keywordMatch.score * 0.5 + boost
            });
    }
    return ranked.sort((a, b) => b.score - a.score).slice(0, limit);
}

function escapeHtml(text) {
    return text.replace(/[&<>"]/g, c => ({
                "&": "&amp;",
                "<": "&lt;",
                ">": "&gt;",
                "\"": "&quot;"
            })[c]);
}

function markMatches(text, indices, color) {
    if (indices.length === 0)
        return escapeHtml(text);
    const chars = Array.from(text);
    return chars.map((c, k) => indices.includes(k) ? `<b><font color="${color}">${escapeHtml(c)}</font></b>` : escapeHtml(c)).join("");
}

const commonCommands = ["cd", "ls", "cat", "cp", "mv", "rm", "mkdir", "echo", "grep", "rg", "fd", "find", "sed", "awk", "git", "gh", "nix", "nixos-rebuild", "niri", "systemctl", "journalctl", "loginctl", "sudo", "ssh", "scp", "curl", "wget", "cargo", "npm", "npx", "pnpm", "yarn", "uv", "uvx", "python", "python3", "node", "make", "docker", "podman", "kubectl", "qs", "quickshell", "wl-copy", "wl-paste", "cliphist", "pkill", "kill", "chmod", "chown", "tar", "unzip", "man", "which", "env", "export", "set", "fish", "bash"];

function looksLikeCommand(text) {
    if (text.includes("\n") || text.split(/\s+/).length > 16)
        return false;
    const first = text.split(/\s+/)[0];
    if (commonCommands.includes(first) || /^(\.{0,2}\/|~\/|\$ )/.test(text))
        return true;
    return /^[a-z][\w.-]*$/.test(first) && text.includes(" ") && /(^|\s)--?[a-z]|\s[|>]\s|&&|\$\(|\s~?\/[\w.-]/i.test(text);
}

function clipType(text, mime) {
    if (mime && mime.startsWith("image/"))
        return "image";
    const trimmed = text.trim();
    if (/^https?:\/\/\S+$/.test(trimmed))
        return "link";
    if (/^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(trimmed))
        return "color";
    if (looksLikeCommand(trimmed))
        return "code";
    if (/[{};]\s*$|=>|::|\(\)|^\s*(def|fn|function|let|const|import|pragma|#include)\b/m.test(trimmed))
        return "code";
    return "text";
}

function clipTitle(type, text) {
    if (type === "link")
        return text.trim().replace(/^https?:\/\//, "");
    return text.replace(/\s+/g, " ").trim();
}

function ageText(seconds) {
    const minutes = Math.floor(seconds / 60);
    if (minutes < 1)
        return "Just now";
    if (minutes < 60)
        return `${minutes} min ago`;
    if (minutes < 60 * 48)
        return `${Math.round(minutes / 60)} h ago`;
    return `${Math.round(minutes / 1440)} d ago`;
}

function hexToRgb(hex) {
    let digits = hex.trim().slice(1);
    if (digits.length === 3)
        digits = digits.split("").map(c => c + c).join("");
    return [0, 2, 4].map(k => parseInt(digits.slice(k, k + 2), 16));
}

function rgbToHsl(rgb) {
    const r = rgb[0] / 255;
    const g = rgb[1] / 255;
    const b = rgb[2] / 255;
    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    const l = (max + min) / 2;
    if (max === min)
        return [0, 0, Math.round(l * 100)];
    const d = max - min;
    const s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    const h = max === r ? (g - b) / d + (g < b ? 6 : 0) : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
    return [Math.round(h * 60), Math.round(s * 100), Math.round(l * 100)];
}

function linkHost(url) {
    const match = /^https?:\/\/([^/?#]+)/.exec(url.trim());
    return match ? match[1] : url;
}
