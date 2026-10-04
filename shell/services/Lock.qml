pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property bool requested: false
    property bool locked: false
    property string sessionPath: ""

    function lock(): void {
        requested = true;
    }

    function release(): void {
        requested = false;
    }

    function setLockedHint(value: bool): void {
        if (sessionPath === "")
            return;
        Quickshell.execDetached(["gdbus", "call", "--system", "--dest", "org.freedesktop.login1", "--object-path", sessionPath, "--method", "org.freedesktop.login1.Session.SetLockedHint", String(value)]);
    }

    onLockedChanged: setLockedHint(locked)

    Process {
        running: true
        command: ["gdbus", "call", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1/user/self", "--method", "org.freedesktop.DBus.Properties.Get", "org.freedesktop.login1.User", "Display"]
        stdout: StdioCollector {
            onStreamFinished: root.sessionPath = /\/org\/freedesktop\/login1\/session\/[^']+/.exec(text)?.[0] ?? ""
        }
    }

    Process {
        id: monitor

        running: Config.lockOnLogind && root.sessionPath !== ""
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", root.sessionPath]
        stdout: SplitParser {
            onRead: line => {
                if (/\.Session\.Lock \(\)/.test(line))
                    root.lock();
            }
        }
        onExited: monitorRestart.start()
    }

    Timer {
        id: monitorRestart

        interval: 5000
        onTriggered: monitor.running = Config.lockOnLogind && root.sessionPath !== ""
    }
}
