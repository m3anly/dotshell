pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string device: ""
    property int percent: 0
    property int requested: -1
    readonly property bool available: device !== ""

    function parse(text: string): void {
        const fields = text.trim().split("\n")[0]?.split(",") ?? [];
        if (fields.length < 5)
            return;
        device = fields[0];
        if (requested < 0)
            percent = parseInt(fields[3]) || 0;
    }

    function set(value: real): void {
        if (!available)
            return;
        percent = Math.max(1, Math.min(100, Math.round(value)));
        requested = percent;
        if (!writer.running)
            apply();
    }

    function change(step: int): void {
        set(percent + step);
    }

    function apply(): void {
        writer.target = requested;
        writer.running = true;
    }

    function refresh(): void {
        if (!reader.running && requested < 0)
            reader.running = true;
    }

    Process {
        id: reader

        running: true
        command: ["brightnessctl", "--class=backlight", "-m", "info"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: writer

        property int target: 0

        command: ["brightnessctl", "--class=backlight", "-m", "-n1", "set", `${target}%`]
        onExited: {
            if (root.requested !== writer.target)
                root.apply();
            else
                root.requested = -1;
        }
    }
}
