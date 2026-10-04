pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int span: 30
    readonly property bool watching: Ui.panel === "system" && Ui.systemTab === "monitor"
    property var sample: null
    property var cpuHistory: []
    property var memoryHistory: []
    property var gpuHistory: []
    property var networkHistory: []

    readonly property bool ready: sample !== null
    readonly property bool hasGpu: (sample?.gpu ?? -1) >= 0
    readonly property real cpu: Math.max(0, sample?.cpu ?? 0) / 1000
    readonly property real memory: (sample?.memTotal ?? 0) > 0 ? 1 - Math.max(0, sample.memAvailable) / sample.memTotal : 0
    readonly property real memoryTotal: Math.max(0, sample?.memTotal ?? 0) * 1024
    readonly property real memoryUsed: memory * memoryTotal
    readonly property real swapUsed: Math.max(0, (sample?.swapTotal ?? 0) - (sample?.swapFree ?? 0)) * 1024
    readonly property real gpu: Math.max(0, sample?.gpu ?? 0) / 100
    readonly property var processes: (sample?.procs ?? []).map(entry => ({
                pid: entry[0],
                name: entry[1],
                cpu: entry[2] / 1000,
                memory: entry[3] * 1024
            }))

    function celsius(milli: real): int {
        return milli > 0 ? Math.round(milli / 1000) : -1;
    }

    function append(list: var, value: real): var {
        const next = list.concat([value]);
        return next.slice(Math.max(0, next.length - span));
    }

    function parse(line: string): void {
        let data;
        try {
            data = JSON.parse(line);
        } catch (error) {
            return;
        }
        sample = data;
        if (data.cpu >= 0)
            cpuHistory = append(cpuHistory, cpu);
        memoryHistory = append(memoryHistory, memory);
        if (data.gpu >= 0)
            gpuHistory = append(gpuHistory, gpu);
        if (data.rx >= 0)
            networkHistory = append(networkHistory, data.rx + data.tx);
    }

    onWatchingChanged: monitor.write(`procs ${watching ? 1 : 0}\n`)

    Process {
        id: monitor

        running: true
        stdinEnabled: true
        command: ["bash", `${Quickshell.shellDir}/scripts/sysmon`, "1"]
        onStarted: write(`procs ${root.watching ? 1 : 0}\n`)
        stdout: SplitParser {
            onRead: line => root.parse(line)
        }
    }
}
