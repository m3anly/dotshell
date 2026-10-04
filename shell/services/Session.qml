pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    readonly property string userName: Quickshell.env("USER") ?? ""
    property real uptimeSeconds: 0
    readonly property string uptime: formatUptime(uptimeSeconds)

    function formatUptime(seconds: real): string {
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        if (days > 0)
            return `up ${days} d ${hours % 24} h`;
        if (hours > 0)
            return `up ${hours} h ${minutes % 60} min`;
        return `up ${minutes} min`;
    }

    function run(command: var): void {
        Ui.closeAll();
        Quickshell.execDetached(command);
    }

    function openSettings(): void {
        if (Config.commands.settings.length > 0) {
            run(Config.commands.settings);
            return;
        }
        Ui.openSettings("");
    }

    function lock(): void {
        if (Config.commands.lock.length > 0) {
            run(Config.commands.lock);
            return;
        }
        Ui.closeAll();
        Lock.lock();
    }

    function suspend(): void {
        run(["systemctl", "suspend"]);
    }

    function logOut(): void {
        Ui.closeAll();
        Niri.quit();
    }

    function reboot(): void {
        run(["systemctl", "reboot"]);
    }

    function powerOff(): void {
        run(["systemctl", "poweroff"]);
    }

    FileView {
        id: uptimeFile

        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = parseFloat(text().split(" ")[0]) || 0
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: uptimeFile.reload()
    }
}
