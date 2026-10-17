pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    function watch(): void {
        monitor.running = true;
    }

    function desktopId(uri: string): string {
        return uri.replace(/^application:\/\//, "").replace(/\.desktop$/, "");
    }

    function handle(line: string): void {
        let message;
        try {
            message = JSON.parse(line);
        } catch (error) {
            return;
        }
        const [uri, properties] = message?.payload?.data ?? [];
        if (typeof uri !== "string" || !properties)
            return;
        if (properties["count-visible"]?.data === false || properties.count?.data === 0)
            Niri.clearUrgency(desktopId(uri));
    }

    Process {
        id: monitor

        command: ["busctl", "--user", "monitor", "--json=short", "--match", "type='signal',interface='com.canonical.Unity.LauncherEntry',member='Update'"]
        stdout: SplitParser {
            onRead: line => root.handle(line)
        }
        onExited: monitorRestart.start()
    }

    Timer {
        id: monitorRestart

        interval: 5000
        onTriggered: monitor.running = true
    }
}
