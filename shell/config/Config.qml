pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string directory: `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/dotshell`
    readonly property string path: file.path
    readonly property string userPath: file.userPath

    readonly property var defaults: ({
            blur: true,
            gameMode: {
                enabled: false,
                animations: true,
                blur: true,
                widgets: true,
                visualizer: true
            },
            lockOnLogind: true,
            polkitAgent: true,
            wallpaper: "",
            wallpaperTransition: "fade",
            wallpaperFolder: "~/Pictures/wallpapers",
            urgentColor: "#F2C230",
            clock: {
                caption: true
            },
            launcher: {
                currency: false,
                showFrequent: true,
                frequentCount: 6,
                appResults: 5,
                clipboardResults: 3,
                usageHalfLifeDays: 7
            },
            clipboard: {
                enabled: true,
                maxEntries: 1000,
                maxTextMiB: 5,
                maxImageMiB: 50,
                ignoreApps: []
            },
            bar: {
                position: "top",
                height: 36,
                edgeScroll: true,
                show: {
                    workspaceCounter: true,
                    focusedWindow: true,
                    tray: true,
                    layout: true,
                    battery: true,
                    notifications: true,
                    quickSettings: true
                }
            },
            notifications: {
                position: "top-right",
                maxPopups: 4,
                timeout: 6,
                respectAppTimeout: true,
                criticalTimeout: 0
            },
            audio: {
                step: 5
            },
            brightness: {
                step: 5
            },
            power: {
                confirm: ["reboot", "poweroff"],
                holdMs: 900
            },
            battery: {
                lowThreshold: 15,
                notifyLow: true,
                notifyAt: 20,
                criticalAt: 10
            },
            calendar: {
                weekStart: "monday"
            },
            weather: {
                enabled: true,
                location: "",
                units: "celsius",
                windUnit: "auto",
                refreshMinutes: 30,
                hideAfterHours: 3
            },
            commands: {
                settings: [],
                lock: []
            },
            sounds: {
                volumeChange: true
            },
            osd: {
                lockKeys: true,
                layout: true,
                radios: true,
                powerMode: true,
                timeout: 1600,
                position: "bottom"
            },
            keyboardLayouts: {},
            trayGlyphs: {
                "nm-applet": "wifi",
                "blueman": "bt",
                "flameshot": "shot"
            }
        })

    readonly property bool blur: value("blur")
    readonly property var gameMode: ({
            enabled: value("gameMode.enabled"),
            animations: value("gameMode.animations"),
            blur: value("gameMode.blur"),
            widgets: value("gameMode.widgets"),
            visualizer: value("gameMode.visualizer")
        })
    readonly property bool lockOnLogind: value("lockOnLogind")
    readonly property bool polkitAgent: value("polkitAgent")
    readonly property string wallpaper: value("wallpaper")
    readonly property string wallpaperTransition: value("wallpaperTransition")
    readonly property string wallpaperFolder: value("wallpaperFolder")
    readonly property string urgentColor: value("urgentColor")
    readonly property var clock: ({
            caption: value("clock.caption")
        })
    readonly property var keyboardLayouts: value("keyboardLayouts")
    readonly property var trayGlyphs: value("trayGlyphs")
    readonly property var commands: ({
            settings: value("commands.settings"),
            lock: value("commands.lock")
        })
    readonly property var osd: ({
            lockKeys: value("osd.lockKeys"),
            layout: value("osd.layout"),
            radios: value("osd.radios"),
            powerMode: value("osd.powerMode"),
            timeout: value("osd.timeout"),
            position: value("osd.position")
        })
    readonly property var sounds: ({
            volumeChange: value("sounds.volumeChange")
        })
    readonly property var launcher: ({
            currency: value("launcher.currency"),
            showFrequent: value("launcher.showFrequent"),
            frequentCount: value("launcher.frequentCount"),
            appResults: value("launcher.appResults"),
            clipboardResults: value("launcher.clipboardResults"),
            usageHalfLifeDays: value("launcher.usageHalfLifeDays")
        })
    readonly property var clipboard: ({
            enabled: value("clipboard.enabled"),
            maxEntries: value("clipboard.maxEntries"),
            maxTextMiB: value("clipboard.maxTextMiB"),
            maxImageMiB: value("clipboard.maxImageMiB"),
            ignoreApps: value("clipboard.ignoreApps")
        })
    readonly property var bar: ({
            position: value("bar.position"),
            height: value("bar.height"),
            edgeScroll: value("bar.edgeScroll"),
            show: {
                workspaceCounter: value("bar.show.workspaceCounter"),
                focusedWindow: value("bar.show.focusedWindow"),
                tray: value("bar.show.tray"),
                layout: value("bar.show.layout"),
                battery: value("bar.show.battery"),
                notifications: value("bar.show.notifications"),
                quickSettings: value("bar.show.quickSettings")
            }
        })
    readonly property var notifications: ({
            position: value("notifications.position"),
            maxPopups: value("notifications.maxPopups"),
            timeout: value("notifications.timeout"),
            respectAppTimeout: value("notifications.respectAppTimeout"),
            criticalTimeout: value("notifications.criticalTimeout")
        })
    readonly property var audio: ({
            step: value("audio.step")
        })
    readonly property var brightness: ({
            step: value("brightness.step")
        })
    readonly property var power: ({
            confirm: value("power.confirm"),
            holdMs: value("power.holdMs")
        })
    readonly property var battery: ({
            lowThreshold: value("battery.lowThreshold"),
            notifyLow: value("battery.notifyLow"),
            notifyAt: value("battery.notifyAt"),
            criticalAt: value("battery.criticalAt")
        })
    readonly property var calendar: ({
            weekStart: value("calendar.weekStart")
        })
    readonly property var weather: ({
            enabled: value("weather.enabled"),
            location: value("weather.location"),
            units: value("weather.units"),
            windUnit: value("weather.windUnit"),
            refreshMinutes: value("weather.refreshMinutes"),
            hideAfterHours: value("weather.hideAfterHours")
        })

    function isPinned(key: string): bool {
        return file.isPinned(key);
    }

    function value(key: string): var {
        return file.value(key);
    }

    function set(key: string, item: var): void {
        file.set(key, item);
    }

    function reset(key: string): void {
        file.reset(key);
    }

    SettingsFile {
        id: file

        directory: root.directory
        defaults: root.defaults
    }
}
