.pragma library

function tokenize(source) {
    const tokens = [];
    let i = 0;
    const n = source.length;
    const isSpace = c => c === " " || c === "\t" || c === "\r";
    const isBreak = c => c === "\n";
    const isPunct = c => c === "{" || c === "}" || c === ";" || c === "=" || c === "(" || c === ")";
    while (i < n) {
        const c = source[i];
        if (isSpace(c)) {
            i++;
            continue;
        }
        if (c === "\\") {
            let j = i + 1;
            while (j < n && isSpace(source[j]))
                j++;
            if (source[j] === "\n") {
                i = j + 1;
                continue;
            }
        }
        if (isBreak(c)) {
            tokens.push({ type: "end" });
            i++;
            continue;
        }
        if (c === "/" && source[i + 1] === "/") {
            while (i < n && source[i] !== "\n")
                i++;
            continue;
        }
        if (c === "/" && source[i + 1] === "*") {
            let depth = 1;
            i += 2;
            while (i < n && depth > 0) {
                if (source[i] === "/" && source[i + 1] === "*") {
                    depth++;
                    i += 2;
                } else if (source[i] === "*" && source[i + 1] === "/") {
                    depth--;
                    i += 2;
                } else {
                    i++;
                }
            }
            continue;
        }
        if (c === "/" && source[i + 1] === "-") {
            tokens.push({ type: "slashdash" });
            i += 2;
            continue;
        }
        if (c === ";") {
            tokens.push({ type: "end" });
            i++;
            continue;
        }
        if (c === "{" || c === "}" || c === "=") {
            tokens.push({ type: c });
            i++;
            continue;
        }
        if (c === "(") {
            while (i < n && source[i] !== ")")
                i++;
            i++;
            continue;
        }
        if (c === "r" && (source[i + 1] === "#" || source[i + 1] === "\"")) {
            let j = i + 1;
            let hashes = 0;
            while (source[j] === "#") {
                hashes++;
                j++;
            }
            if (source[j] === "\"") {
                const close = "\"" + "#".repeat(hashes);
                const end = source.indexOf(close, j + 1);
                const stop = end < 0 ? n : end;
                tokens.push({ type: "value", value: source.slice(j + 1, stop) });
                i = stop + close.length;
                continue;
            }
        }
        if (c === "\"") {
            let j = i + 1;
            let value = "";
            while (j < n && source[j] !== "\"") {
                if (source[j] === "\\" && j + 1 < n) {
                    const next = source[j + 1];
                    value += next === "n" ? "\n" : next === "t" ? "\t" : next;
                    j += 2;
                } else {
                    value += source[j];
                    j++;
                }
            }
            tokens.push({ type: "value", value: value });
            i = j + 1;
            continue;
        }
        let j = i;
        while (j < n && !isSpace(source[j]) && !isBreak(source[j]) && !isPunct(source[j]) && source[j] !== "\"")
            j++;
        if (j === i) {
            i++;
            continue;
        }
        const word = source.slice(i, j);
        let value = word;
        if (word === "true")
            value = true;
        else if (word === "false")
            value = false;
        else if (word === "null")
            value = null;
        else if (/^[+-]?\d+(\.\d+)?$/.test(word))
            value = Number(word);
        tokens.push({ type: "word", value: value, raw: word });
        i = j;
    }
    return tokens;
}

function parse(source) {
    const tokens = tokenize(source);
    let pos = 0;

    function readNodes(closing) {
        const list = [];
        while (pos < tokens.length) {
            const token = tokens[pos];
            if (token.type === "end") {
                pos++;
                continue;
            }
            if (token.type === "}") {
                if (closing)
                    pos++;
                return list;
            }
            let skip = false;
            if (token.type === "slashdash") {
                skip = true;
                pos++;
            }
            const node = readNode();
            if (node && !skip)
                list.push(node);
        }
        return list;
    }

    function readNode() {
        const head = tokens[pos];
        if (!head || (head.type !== "word" && head.type !== "value")) {
            pos++;
            return null;
        }
        pos++;
        const node = { name: head.type === "word" ? head.raw : head.value, args: [], props: {}, children: [] };
        while (pos < tokens.length) {
            const token = tokens[pos];
            if (token.type === "end") {
                pos++;
                return node;
            }
            if (token.type === "}")
                return node;
            if (token.type === "{") {
                pos++;
                node.children = readNodes(true);
                return node;
            }
            if (token.type === "slashdash") {
                pos++;
                if (tokens[pos]?.type === "{") {
                    pos++;
                    readNodes(true);
                } else {
                    pos++;
                    if (tokens[pos]?.type === "=")
                        pos += 2;
                }
                continue;
            }
            if ((token.type === "word" || token.type === "value") && tokens[pos + 1]?.type === "=") {
                const key = token.type === "word" ? token.raw : token.value;
                const valueToken = tokens[pos + 2];
                node.props[key] = valueToken ? valueToken.value : null;
                pos += 3;
                continue;
            }
            if (token.type === "word" || token.type === "value") {
                node.args.push(token.value);
                pos++;
                continue;
            }
            pos++;
        }
        return node;
    }

    return readNodes(false);
}
