pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool ready: false
    property bool caps: false
    property bool num: false
    property bool scroll: false

    signal toggled(string key)

    function parse(line: string): void {
        if (!/^[01]{3}$/.test(line))
            return;
        const next = {
            caps: line[0] === "1",
            num: line[1] === "1",
            scroll: line[2] === "1"
        };
        const first = !ready;
        for (const key of ["caps", "num", "scroll"]) {
            if (root[key] === next[key])
                continue;
            root[key] = next[key];
            if (!first)
                toggled(key);
        }
        ready = true;
    }

    Process {
        running: true
        command: ["bash", "-c", `exec 3<> <(:)
previous=""
while :; do
    state=""
    for key in capslock numlock scrolllock; do
        lit=0
        for file in /sys/class/leds/*::$key/brightness; do
            [ -r "$file" ] || continue
            read -r value < "$file"
            [ "$value" != 0 ] && lit=1
        done
        state="$state$lit"
    done
    [ "$state" != "$previous" ] && echo "$state" && previous="$state"
    read -rt 0.15 -u 3 _
done`]
        stdout: SplitParser {
            onRead: line => root.parse(line)
        }
    }
}
