pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.components
import qs.config
import qs.services
import qs.theme
import "SettingsFormat.js" as Format

QtObject {
    id: root

    readonly property var list: [
        {
            id: "appearance",
            title: "Appearance",
            blurb: "Accent color, blur and the desktop clock",
            page: appearance
        },
        {
            id: "gameMode",
            title: "Game mode",
            blurb: "Features disabled while game mode is on",
            page: gameMode
        },
        {
            id: "wallpaper",
            title: "Wallpaper",
            blurb: "Desktop background and transitions",
            page: wallpaper
        },
        {
            id: "bar",
            title: "Bar",
            blurb: "Bar position, contents and labels",
            page: bar
        },
        {
            id: "notifications",
            title: "Notifications",
            blurb: "Popup placement and duration",
            page: notifications
        },
        {
            id: "popups",
            title: "OSD",
            blurb: "On-screen indicators for volume, brightness and system state",
            page: popups
        },
        {
            id: "launcher",
            title: "Launcher",
            blurb: "Application search, calculator and ranking",
            page: launcher
        },
        {
            id: "clipboard",
            title: "Clipboard",
            blurb: "Clipboard history recording and limits",
            page: clipboard
        },
        {
            id: "session",
            title: "Lock & session",
            blurb: "Screen locking, power actions and custom commands",
            page: session
        },
        {
            id: "weather",
            title: "Weather",
            blurb: "Current weather in the bar",
            page: weather
        },
        {
            id: "battery",
            title: "Battery",
            blurb: "Battery alerts and charge levels",
            page: battery
        },
        {
            id: "system",
            title: "System",
            blurb: "System services provided by Dotshell",
            page: system
        }
    ]

    property Component appearance: Page {
        id: appearancePage

        SettingRow {
            Layout.fillWidth: true
            shown: appearancePage.shown
            order: 0
            wide: true
            key: "urgentColor"
            title: "Urgent workspace color"
            description: "Color of workspace indicators that contain a window requesting attention."

            ColorPicker {
                Layout.fillWidth: true
                value: Config.urgentColor
                onPicked: value => Config.set("urgentColor", value)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: appearancePage.shown
            order: 1
            key: "blur"
            title: "Blur"
            description: "Blur the content behind the bar, panels and launcher. When off, these surfaces are opaque."

            Toggle {
                on: Config.blur
                onToggled: value => Config.set("blur", value)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: appearancePage.shown
            order: 2
            divider: false
            key: "clock.caption"
            title: "Clock caption"
            description: "Show a caption under the desktop clock describing the current mode."

            Toggle {
                on: Config.clock.caption
                onToggled: value => Config.set("clock.caption", value)
            }
        }

    }

    property Component gameMode: Page {
        id: gameModePage

        SettingRow {
            Layout.fillWidth: true
            shown: gameModePage.shown
            order: 0
            key: "gameMode.enabled"
            title: "Game mode"
            description: "Reduce visual effects to improve performance. Also available in the System panel and through the gamemode IPC command."

            Toggle {
                on: GameMode.active
                onToggled: value => GameMode.setActive(value)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: gameModePage.shown
            order: 1
            indent: 24
            key: "gameMode.animations"
            title: "Animations"
            description: "Disable animations and transitions."

            Toggle {
                on: Config.gameMode.animations
                onToggled: value => Config.set("gameMode.animations", value)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            shown: gameModePage.shown
            order: 2
            indent: 24
            key: "gameMode.blur"
            title: "Blur"
            description: "Disable background blur, including the blurred wallpaper in the overview."

            Toggle {
                on: Config.gameMode.blur
                onToggled: value => Config.set("gameMode.blur", value)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            shown: gameModePage.shown
            order: 3
            indent: 24
            key: "gameMode.widgets"
            title: "Desktop widgets"
            description: "Hide the desktop clock."

            Toggle {
                on: Config.gameMode.widgets
                onToggled: value => Config.set("gameMode.widgets", value)
            }
        }
        SettingRow {
            Layout.fillWidth: true
            shown: gameModePage.shown
            order: 4
            indent: 24
            divider: false
            key: "gameMode.visualizer"
            title: "Visualizer"
            description: "Stop the audio visualizer on the Media tab."

            Toggle {
                on: Config.gameMode.visualizer
                onToggled: value => Config.set("gameMode.visualizer", value)
            }
        }
    }

    property Component wallpaper: Page {
        id: wallpaperPage

        readonly property string folder: Wallpaper.expand(Config.wallpaperFolder)

        SettingRow {
            Layout.fillWidth: true
            shown: wallpaperPage.shown
            order: 0
            wide: true
            title: "Wallpaper"
            description: grid.count > 0 ? `${grid.count} images in ${Config.wallpaperFolder}` : Config.wallpaperFolder

            WallpaperGrid {
                id: grid

                Layout.fillWidth: true
                columns: Math.max(2, Math.floor((width + gap) / (140 + gap)))
                folder: wallpaperPage.folder
            }

            Pill {
                Layout.alignment: Qt.AlignRight
                visible: Store.wallpaper !== ""
                glyph: "close"
                text: Config.wallpaper !== "" ? "Use default" : "Clear"
                onClicked: Wallpaper.clear()
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: wallpaperPage.shown
            order: 1
            key: "wallpaperTransition"
            title: "Transition"
            description: "Animation used when the wallpaper changes."

            Segmented {
                options: [
                    {
                        value: "fade",
                        label: "Fade"
                    },
                    {
                        value: "wipe",
                        label: "Wipe"
                    },
                    {
                        value: "circle",
                        label: "Circle"
                    },
                    {
                        value: "dots",
                        label: "Dots"
                    }
                ]
                value: Config.wallpaperTransition
                onPicked: value => Config.set("wallpaperTransition", value)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: wallpaperPage.shown
            order: 2
            key: "wallpaperFolder"
            title: "Folder"
            description: "Folder containing the wallpapers shown above."

            TextField {
                text: Config.wallpaperFolder
                placeholder: "~/Pictures/wallpapers"
                onCommitted: value => Config.set("wallpaperFolder", value.trim())
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: wallpaperPage.shown
            order: 3
            divider: false
            key: "wallpaper"
            title: "Default wallpaper"
            description: "Used when no wallpaper is selected here or set over IPC."

            TextField {
                text: Config.wallpaper
                placeholder: "None"
                onCommitted: value => Config.set("wallpaper", value.trim())
            }
        }
    }

    component ToggleRow: SettingRow {
        id: toggleRow

        Layout.fillWidth: true

        Toggle {
            on: Config.value(toggleRow.key)
            onToggled: value => Config.set(toggleRow.key, value)
        }
    }

    component StepperRow: SettingRow {
        id: stepperRow

        property real from: 0
        property real to: 100
        property real step: 1
        property string unit
        property string zeroText

        Layout.fillWidth: true

        Stepper {
            value: Config.value(stepperRow.key)
            from: stepperRow.from
            to: stepperRow.to
            step: stepperRow.step
            unit: stepperRow.unit
            zeroText: stepperRow.zeroText
            onMoved: value => Config.set(stepperRow.key, value)
        }
    }

    component ChoiceRow: SettingRow {
        id: choiceRow

        property var options: []

        Layout.fillWidth: true

        Segmented {
            options: choiceRow.options
            value: Config.value(choiceRow.key)
            onPicked: value => Config.set(choiceRow.key, value)
        }
    }

    property Component bar: Page {
        id: barPage

        readonly property var blocks: [
            {
                value: "workspaceCounter",
                label: "Workspace count"
            },
            {
                value: "focusedWindow",
                label: "Window title"
            },
            {
                value: "tray",
                label: "Tray"
            },
            {
                value: "layout",
                label: "Layout"
            },
            {
                value: "battery",
                label: "Battery"
            },
            {
                value: "notifications",
                label: "Notifications"
            },
            {
                value: "quickSettings",
                label: "Quick settings"
            }
        ]

        ChoiceRow {
            shown: barPage.shown
            order: 0
            key: "bar.position"
            title: "Position"
            description: "Screen edge the bar is attached to. Panels open from this edge."
            options: [
                {
                    value: "top",
                    label: "Top"
                },
                {
                    value: "bottom",
                    label: "Bottom"
                }
            ]
        }

        StepperRow {
            shown: barPage.shown
            order: 1
            key: "bar.height"
            title: "Height"
            from: 28
            to: 56
            unit: "px"
        }

        SettingRow {
            Layout.fillWidth: true
            shown: barPage.shown
            order: 2
            wide: true
            key: "bar.show"
            title: "Blocks"
            description: "Optional items shown in the bar."

            ChipGroup {
                Layout.fillWidth: true
                options: barPage.blocks
                values: barPage.blocks.map(block => block.value).filter(name => Config.bar.show[name])
                onEdited: values => barPage.blocks.forEach(block => Config.set(`bar.show.${block.value}`, values.includes(block.value)))
            }
        }

        ToggleRow {
            shown: barPage.shown
            order: 3
            key: "bar.edgeScroll"
            title: "Scroll at the edges"
            description: "Scroll at the far right of the bar to change the volume, and at the far left to change the brightness."
        }

        SettingRow {
            Layout.fillWidth: true
            shown: barPage.shown
            order: 4
            wide: true
            key: "keyboardLayouts"
            title: "Keyboard layouts"
            description: "Short labels for keyboard layout names. Layouts without a label show their first two letters."

            MapEditor {
                Layout.fillWidth: true
                map: Config.keyboardLayouts
                suggestions: Niri.layoutNames
                suggest: name => name.slice(0, 2).toUpperCase()
                keyPlaceholder: "Layout name"
                valuePlaceholder: "Label"
                onEdited: map => Config.set("keyboardLayouts", map)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: barPage.shown
            order: 5
            wide: true
            key: "trayGlyphs"
            title: "Tray glyphs"
            description: "Dot glyphs for tray items by item ID. Other items use their own icon, desaturated."

            MapEditor {
                Layout.fillWidth: true
                map: Config.trayGlyphs
                glyphs: true
                suggestions: SystemTray.items.values.map(item => item.id)
                keyPlaceholder: "Item id"
                valuePlaceholder: "Glyph"
                onEdited: map => Config.set("trayGlyphs", map)
            }
        }

        ChoiceRow {
            shown: barPage.shown
            order: 6
            divider: false
            key: "calendar.weekStart"
            title: "Week starts on"
            description: "First day of the week in the calendar."
            options: [
                {
                    value: "monday",
                    label: "Mon"
                },
                {
                    value: "sunday",
                    label: "Sun"
                }
            ]
        }
    }

    property Component notifications: Page {
        id: notificationsPage

        ChoiceRow {
            shown: notificationsPage.shown
            order: 0
            wide: true
            key: "notifications.position"
            title: "Position"
            description: "Screen corner where notifications appear."
            options: [
                {
                    value: "top-left",
                    label: "Top left"
                },
                {
                    value: "top-right",
                    label: "Top right"
                },
                {
                    value: "bottom-left",
                    label: "Bottom left"
                },
                {
                    value: "bottom-right",
                    label: "Bottom right"
                }
            ]
        }

        StepperRow {
            shown: notificationsPage.shown
            order: 1
            key: "notifications.maxPopups"
            title: "Popups at once"
            description: "Maximum number of popups shown at once. Others remain in the notification center."
            from: 1
            to: 10
        }

        StepperRow {
            shown: notificationsPage.shown
            order: 2
            key: "notifications.timeout"
            title: "Popup time"
            description: "Display time for notifications that do not specify one."
            from: 1
            to: 120
            unit: "s"
        }

        ToggleRow {
            shown: notificationsPage.shown
            order: 3
            key: "notifications.respectAppTimeout"
            title: "Use the app's time"
            description: "Use the display time requested by the application, with a minimum of 3 seconds. When off, the time above applies to all notifications."
        }

        StepperRow {
            shown: notificationsPage.shown
            order: 4
            divider: false
            key: "notifications.criticalTimeout"
            title: "Critical popups"
            description: "Display time for critical notifications."
            from: 0
            to: 600
            step: 5
            unit: "s"
            zeroText: "Until dismissed"
        }
    }

    property Component popups: Page {
        id: popupsPage

        ChoiceRow {
            shown: popupsPage.shown
            order: 0
            key: "osd.position"
            title: "Position"
            description: "Screen edge where the OSD appears."
            options: [
                {
                    value: "bottom",
                    label: "Bottom"
                },
                {
                    value: "top",
                    label: "Top"
                }
            ]
        }

        StepperRow {
            shown: popupsPage.shown
            order: 1
            key: "osd.timeout"
            title: "Hide after"
            description: "Time before the OSD hides after the last change."
            from: 500
            to: 10000
            step: 100
            unit: "ms"
        }

        StepperRow {
            shown: popupsPage.shown
            order: 2
            key: "audio.step"
            title: "Volume step"
            description: "Volume change per scroll step over the OSD or at the edge of the bar. Volume keys use the step set in their niri bind."
            from: 1
            to: 25
            unit: "%"
        }

        StepperRow {
            shown: popupsPage.shown
            order: 3
            key: "brightness.step"
            title: "Brightness step"
            description: "Brightness change per scroll step over the OSD or at the edge of the bar."
            from: 1
            to: 25
            unit: "%"
        }

        SettingRow {
            Layout.fillWidth: true
            shown: popupsPage.shown
            order: 4
            key: "osd.lockKeys"
            title: "Lock keys"
            description: "Show the OSD when Caps Lock, Num Lock or Scroll Lock is toggled."

            Toggle {
                on: Config.osd.lockKeys
                onToggled: value => Config.set("osd.lockKeys", value)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: popupsPage.shown
            order: 5
            key: "osd.layout"
            title: "Keyboard layout"
            description: "Show the OSD when the keyboard layout changes."

            Toggle {
                on: Config.osd.layout
                onToggled: value => Config.set("osd.layout", value)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: popupsPage.shown
            order: 6
            key: "osd.radios"
            title: "Wi-Fi and Bluetooth"
            description: "Show the OSD when Wi-Fi or Bluetooth is toggled outside quick settings."

            Toggle {
                on: Config.osd.radios
                onToggled: value => Config.set("osd.radios", value)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: popupsPage.shown
            order: 7
            key: "osd.powerMode"
            title: "Power mode"
            description: "Show the OSD when the power profile changes outside the battery panel."

            Toggle {
                on: Config.osd.powerMode
                onToggled: value => Config.set("osd.powerMode", value)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: popupsPage.shown
            order: 8
            divider: false
            key: "sounds.volumeChange"
            title: "Volume sound"
            description: "Play a sound when the volume changes."

            Toggle {
                on: Config.sounds.volumeChange
                onToggled: value => Config.set("sounds.volumeChange", value)
            }
        }
    }

    property Component session: Page {
        id: sessionPage

        SettingRow {
            Layout.fillWidth: true
            shown: sessionPage.shown
            order: 0
            key: "lockOnLogind"
            title: "Lock on logind"
            description: "Lock the screen when requested by logind, for example by loginctl lock-session or an idle daemon."

            Toggle {
                on: Config.lockOnLogind
                onToggled: value => Config.set("lockOnLogind", value)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: sessionPage.shown
            order: 1
            wide: true
            key: "power.confirm"
            title: "Hold to confirm"
            description: "Power actions that must be held to confirm."

            ChipGroup {
                Layout.fillWidth: true
                options: [
                    {
                        value: "lock",
                        label: "Lock"
                    },
                    {
                        value: "suspend",
                        label: "Sleep"
                    },
                    {
                        value: "logout",
                        label: "Log out"
                    },
                    {
                        value: "reboot",
                        label: "Reboot"
                    },
                    {
                        value: "poweroff",
                        label: "Power off"
                    }
                ]
                values: Config.power.confirm
                onEdited: values => Config.set("power.confirm", values)
            }
        }

        StepperRow {
            shown: sessionPage.shown
            order: 2
            key: "power.holdMs"
            title: "Hold time"
            from: 100
            to: 5000
            step: 50
            unit: "ms"
        }

        SettingRow {
            Layout.fillWidth: true
            shown: sessionPage.shown
            order: 3
            key: "commands.lock"
            title: "Lock command"
            description: "Command to run instead of the built-in lock screen."

            TextField {
                text: Format.joinCommand(Config.commands.lock)
                placeholder: "Built-in lock screen"
                onCommitted: value => Config.set("commands.lock", Format.splitCommand(value))
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: sessionPage.shown
            order: 4
            divider: false
            key: "commands.settings"
            title: "Settings command"
            description: "Command to run from the quick settings Settings button instead of opening this window."

            TextField {
                text: Format.joinCommand(Config.commands.settings)
                placeholder: "This window"
                onCommitted: value => Config.set("commands.settings", Format.splitCommand(value))
            }
        }
    }

    property Component launcher: Page {
        id: launcherPage

        SettingRow {
            Layout.fillWidth: true
            shown: launcherPage.shown
            order: 0
            key: "launcher.currency"
            title: "Currency conversion"
            description: "Convert currencies in the launcher, for example 10eur usd. Exchange rates are downloaded when outdated."

            Toggle {
                on: Config.launcher.currency
                onToggled: value => Config.set("launcher.currency", value)
            }
        }

        ToggleRow {
            shown: launcherPage.shown
            order: 1
            key: "launcher.showFrequent"
            title: "Frequent apps"
            description: "Show the most used applications when the search is empty."
        }

        StepperRow {
            shown: launcherPage.shown
            order: 2
            key: "launcher.frequentCount"
            title: "Frequent rows"
            from: 1
            to: 20
        }

        StepperRow {
            shown: launcherPage.shown
            order: 3
            key: "launcher.appResults"
            title: "App results"
            description: "Maximum number of applications shown in search results."
            from: 1
            to: 20
        }

        StepperRow {
            shown: launcherPage.shown
            order: 4
            key: "launcher.clipboardResults"
            title: "Clipboard results"
            description: "Maximum number of clipboard entries shown in search results."
            from: 0
            to: 10
        }

        StepperRow {
            shown: launcherPage.shown
            order: 5
            divider: false
            key: "launcher.usageHalfLifeDays"
            title: "Usage fades over"
            description: "Period after which an application's usage score is halved. Shorter periods adapt to new habits faster."
            from: 1
            to: 90
            unit: "d"
        }
    }

    property Component clipboard: Page {
        id: clipboardPage

        ToggleRow {
            shown: clipboardPage.shown
            order: 0
            key: "clipboard.enabled"
            title: "Record history"
            description: "Save copied content to the history. Existing entries are kept when off."
        }

        StepperRow {
            shown: clipboardPage.shown
            order: 1
            key: "clipboard.maxEntries"
            title: "Entries kept"
            description: "Maximum number of unpinned entries. The oldest are removed first; pinned entries are always kept."
            from: 50
            to: 10000
            step: 50
        }

        StepperRow {
            shown: clipboardPage.shown
            order: 2
            key: "clipboard.maxTextMiB"
            title: "Largest text"
            from: 1
            to: 100
            unit: "MiB"
        }

        StepperRow {
            shown: clipboardPage.shown
            order: 3
            key: "clipboard.maxImageMiB"
            title: "Largest image"
            from: 1
            to: 500
            unit: "MiB"
        }

        SettingRow {
            Layout.fillWidth: true
            shown: clipboardPage.shown
            order: 4
            divider: false
            key: "clipboard.ignoreApps"
            title: "Ignored apps"
            description: "Comma-separated application names or IDs whose copied content is not saved."

            TextField {
                text: Config.clipboard.ignoreApps.join(", ")
                placeholder: "KeePassXC, org.gnome.Secrets"
                onCommitted: value => Config.set("clipboard.ignoreApps", value.split(",").map(app => app.trim()).filter(Boolean))
            }
        }
    }

    property Component weather: Page {
        id: weatherPage

        SettingRow {
            Layout.fillWidth: true
            shown: weatherPage.shown
            order: 0
            key: "weather.enabled"
            title: "Show weather"
            description: "Show the current weather in the bar. Requires a location."

            Toggle {
                on: Config.weather.enabled
                onToggled: value => Config.set("weather.enabled", value)
            }
        }

        SettingRow {
            Layout.fillWidth: true
            shown: weatherPage.shown
            order: 1
            key: "weather.location"
            title: "Location"
            description: {
                if (Weather.loading)
                    return "Looking up the location";
                if (Weather.available)
                    return [Weather.place, `${Weather.temperature} ${Weather.condition}`].filter(Boolean).join(" · ");
                return "City, optionally followed by a country, or coordinates as lat,lon.";
            }

            TextField {
                text: Config.weather.location
                placeholder: "Paris, France"
                onCommitted: value => Config.set("weather.location", value.trim())
            }
        }

        ChoiceRow {
            shown: weatherPage.shown
            order: 2
            key: "weather.units"
            title: "Units"
            options: [
                {
                    value: "celsius",
                    label: "°C"
                },
                {
                    value: "fahrenheit",
                    label: "°F"
                }
            ]
        }

        ChoiceRow {
            shown: weatherPage.shown
            order: 3
            key: "weather.windUnit"
            title: "Wind"
            description: "Automatic selection uses km/h with °C and mph with °F."
            options: [
                {
                    value: "auto",
                    label: "Auto"
                },
                {
                    value: "kmh",
                    label: "km/h"
                },
                {
                    value: "ms",
                    label: "m/s"
                },
                {
                    value: "mph",
                    label: "mph"
                },
                {
                    value: "kn",
                    label: "kn"
                }
            ]
        }

        StepperRow {
            shown: weatherPage.shown
            order: 4
            key: "weather.refreshMinutes"
            title: "Refresh every"
            from: 5
            to: 240
            step: 5
            unit: "min"
        }

        StepperRow {
            shown: weatherPage.shown
            order: 5
            divider: false
            key: "weather.hideAfterHours"
            title: "Hide after"
            description: "Hide readings older than this, for example when offline."
            from: 1
            to: 48
            unit: "h"
        }
    }

    property Component battery: Page {
        id: batteryPage

        ToggleRow {
            shown: batteryPage.shown
            order: 0
            key: "battery.notifyLow"
            title: "Low battery alerts"
            description: "Send a notification when the battery charge falls to the levels below."
        }

        StepperRow {
            shown: batteryPage.shown
            order: 1
            key: "battery.notifyAt"
            title: "Low at"
            from: 5
            to: 50
            unit: "%"
        }

        StepperRow {
            shown: batteryPage.shown
            order: 2
            key: "battery.criticalAt"
            title: "Critical at"
            description: "Level for a critical notification, which remains until dismissed."
            from: 1
            to: 30
            unit: "%"
        }

        StepperRow {
            shown: batteryPage.shown
            order: 3
            divider: false
            key: "battery.lowThreshold"
            title: "Red level"
            description: "Charge level at which the battery panel shows the charge in red."
            from: 5
            to: 50
            unit: "%"
        }
    }

    property Component system: Page {
        id: systemPage

        SettingRow {
            Layout.fillWidth: true
            shown: systemPage.shown
            order: 0
            divider: false
            key: "polkitAgent"
            title: "Polkit agent"
            description: "Handle polkit authentication requests. Disable if another polkit agent is running."

            Toggle {
                on: Config.polkitAgent
                onToggled: value => Config.set("polkitAgent", value)
            }
        }
    }
}
