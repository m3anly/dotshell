pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string directory: `${Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`}/dotshell`
    readonly property string path: `${directory}/config.json`
    readonly property string userPath: `${directory}/settings.json`

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
    property var pinned: ({})
    property var user: ({})
    property bool pendingSave: false

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

    function lookup(source: var, key: string): var {
        let node = source;
        for (const part of key.split(".")) {
            if (node === null || typeof node !== "object" || Array.isArray(node) || !(part in node))
                return undefined;
            node = node[part];
        }
        return node;
    }

    function kind(item: var): string {
        if (Array.isArray(item))
            return "array";
        return item === null ? "null" : typeof item;
    }

    function fits(key: string, candidate: var): bool {
        return candidate !== undefined && kind(candidate) === kind(lookup(defaults, key));
    }

    function isPinned(key: string): bool {
        return fits(key, lookup(pinned, key));
    }

    function value(key: string): var {
        const fromPinned = lookup(pinned, key);
        if (fits(key, fromPinned))
            return fromPinned;
        const fromUser = lookup(user, key);
        if (fits(key, fromUser))
            return fromUser;
        return lookup(defaults, key);
    }

    function withValue(source: var, parts: var, item: var): var {
        const copy = Object.assign({}, kind(source) === "object" ? source : {});
        const [head, ...rest] = parts;
        if (rest.length === 0) {
            if (item === undefined)
                delete copy[head];
            else
                copy[head] = item;
            return copy;
        }
        const child = withValue(copy[head], rest, item);
        if (Object.keys(child).length === 0)
            delete copy[head];
        else
            copy[head] = child;
        return copy;
    }

    function set(key: string, item: var): void {
        if (isPinned(key) || !fits(key, item))
            return;
        user = withValue(user, key.split("."), item);
        save();
    }

    function reset(key: string): void {
        if (lookup(user, key) === undefined)
            return;
        user = withValue(user, key.split("."), undefined);
        save();
    }

    function save(): void {
        pendingSave = true;
        if (!makeDirectory.running)
            makeDirectory.running = true;
    }

    function parse(text: string): var {
        try {
            const parsed = JSON.parse(text);
            return kind(parsed) === "object" ? parsed : null;
        } catch (e) {
            return null;
        }
    }

    FileView {
        id: pinnedFile

        property bool missing: false

        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            missing = false;
            root.pinned = root.parse(text()) ?? root.pinned;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                return;
            missing = true;
            root.pinned = {};
        }
    }

    Process {
        id: makeDirectory

        command: ["mkdir", "-p", root.directory]
        onExited: {
            if (!root.pendingSave)
                return;
            root.pendingSave = false;
            userFile.setText(`${JSON.stringify(root.user, null, 2)}\n`);
        }
    }

    FileView {
        id: userFile

        property bool missing: false

        path: root.userPath
        watchChanges: true
        printErrors: false
        atomicWrites: true
        onFileChanged: reload()
        onLoaded: {
            missing = false;
            root.user = root.parse(text()) ?? root.user;
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                return;
            missing = true;
            root.user = {};
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: pinnedFile.missing || userFile.missing
        onTriggered: {
            if (pinnedFile.missing)
                pinnedFile.reload();
            if (userFile.missing && !root.pendingSave)
                userFile.reload();
        }
    }
}
