import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

Scope {
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            Ui.openLauncher("search");
        }

        function clipboard(): void {
            Ui.openLauncher("clipboard");
        }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void {
            Ui.toggleSettings();
        }

        function open(section: string): void {
            Ui.openSettings(section);
        }

        function close(): void {
            Ui.settingsOpen = false;
        }
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            Ui.toggleCheatsheet();
        }
    }

    IpcHandler {
        target: "gamemode"

        function toggle(): void {
            GameMode.toggle();
        }

        function enable(): void {
            GameMode.setActive(true);
        }

        function disable(): void {
            GameMode.setActive(false);
        }

        function get(): bool {
            return GameMode.active;
        }
    }

    IpcHandler {
        target: "wallpaper"

        function set(path: string): void {
            Wallpaper.set(path);
        }

        function get(): string {
            return Wallpaper.path;
        }

        function clear(): void {
            Wallpaper.clear();
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            Lock.lock();
        }
    }

    IpcHandler {
        target: "audio"

        function increment(step: int): void {
            Audio.changeVolume(step);
            Osd.show("volume");
        }

        function decrement(step: int): void {
            Audio.changeVolume(-step);
            Osd.show("volume");
        }

        function mute(): void {
            Audio.toggleMute(Audio.sink);
            Osd.show("volume");
        }

        function micmute(): void {
            Audio.toggleMute(Audio.source);
            Osd.show("mic");
        }
    }

    IpcHandler {
        target: "brightness"

        function increment(step: int): void {
            Brightness.change(step);
            Osd.show("brightness");
        }

        function decrement(step: int): void {
            Brightness.change(-step);
            Osd.show("brightness");
        }
    }

    IpcHandler {
        target: "mpris"

        function playPause(): void {
            Media.playPause();
            Osd.show("media");
        }

        function next(): void {
            Media.next();
            Osd.show("media");
        }

        function previous(): void {
            Media.previous();
            Osd.show("media");
        }

        function increment(step: int): void {
            Media.changeVolume(step);
        }

        function decrement(step: int): void {
            Media.changeVolume(-step);
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            Ui.togglePanel("notifications", "");
        }

        function clear(): void {
            Notifications.clear();
        }

        function silent(): void {
            Notifications.toggleDoNotDisturb();
        }
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            Ui.toggleDashboard("", "");
        }

        function open(tab: string): void {
            Ui.openDashboard(tab, "");
        }
    }

    IpcHandler {
        target: "panels"

        function system(): void {
            Ui.togglePanel("system", "");
        }

        function quickSettings(): void {
            Ui.togglePanel("quickSettings", "");
        }

        function power(): void {
            Ui.openPowerMenu();
        }

        function battery(): void {
            Ui.togglePanel("battery", "");
        }

        function close(): void {
            Ui.closeAll();
        }
    }
}
