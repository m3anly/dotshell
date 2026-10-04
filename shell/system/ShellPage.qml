pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.settings
import qs.theme

TabPage {
    id: root

    property bool open: false
    property bool visited: false
    readonly property bool showing: open && current

    tab: "shell"
    group: "system"
    onShowingChanged: {
        if (showing)
            visited = true;
    }
    implicitHeight: layout.implicitHeight

    component SwitchTile: MorphButton {
        id: tile

        property string glyph
        property string title
        property bool on: false
        property string key: ""
        readonly property bool pinned: key !== "" && Config.isPinned(key)

        signal toggled

        implicitHeight: 76
        restRadius: on ? 22 : 16
        pressRadius: 10
        pressScale: 0.95
        restColor: on ? Theme.fg : Theme.fill
        hoverColor: on ? Theme.fg : Theme.hover
        outline: on ? "transparent" : Theme.line
        enabled: !pinned
        opacity: pinned ? 0.45 : 1
        onClicked: toggled()

        DotIcon {
            x: 14
            y: 14
            name: tile.pinned ? "lock" : tile.glyph
            color: tile.on ? Theme.glassBase : Theme.fg

            Behavior on color {
                EffectsColor {}
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            width: 6
            height: 6
            radius: 3
            color: tile.on ? Theme.red : Theme.fg3
            antialiasing: true
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 14
            spacing: 2

            Label {
                width: parent.width
                text: tile.title
                pixelSize: 11
                elide: Text.ElideRight
                color: tile.on ? Theme.glassBase : Theme.fg

                Behavior on color {
                    EffectsColor {}
                }
            }

            Label {
                text: tile.on ? "On" : "Off"
                pixelSize: 10
                color: tile.on ? Qt.rgba(0, 0, 0, 0.55) : Theme.fg3

                Behavior on color {
                    EffectsColor {}
                }
            }
        }
    }

    component Pill: MorphButton {
        id: pill

        property string glyph
        property string text

        implicitWidth: pillRow.implicitWidth + 28
        implicitHeight: 36
        restRadius: 18
        pressRadius: 8
        hoverColor: Qt.rgba(1, 1, 1, 0.1)

        Row {
            id: pillRow

            anchors.centerIn: parent
            spacing: 8

            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: pill.glyph
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.text
                pixelSize: 12
            }
        }
    }

    component Heading: Label {
        Layout.leftMargin: 4
        pixelSize: 11
        color: Theme.fg2
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            SwitchTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                glyph: "moon"
                title: "Silent"
                on: Notifications.doNotDisturb
                onToggled: Notifications.toggleDoNotDisturb()
            }

            SwitchTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                glyph: "vol"
                title: "Volume sound"
                key: "sounds.volumeChange"
                on: Config.sounds.volumeChange
                onToggled: Config.set(key, !on)
            }

            SwitchTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                glyph: "pad"
                title: "Game mode"
                key: "gameMode.enabled"
                on: GameMode.active
                onToggled: GameMode.toggle()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 12

            Heading {
                text: "Units"
            }

            Segmented {
                enabled: !Config.isPinned("weather.units")
                opacity: enabled ? 1 : 0.45
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
                value: Config.weather.units
                onPicked: value => Config.set("weather.units", value)
            }

            Item {
                Layout.fillWidth: true
            }

            Heading {
                text: "Week starts"
            }

            Segmented {
                enabled: !Config.isPinned("calendar.weekStart")
                opacity: enabled ? 1 : 0.45
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
                value: Config.calendar.weekStart
                onPicked: value => Config.set("calendar.weekStart", value)
            }
        }

        DottedLine {
            Layout.fillWidth: true
            Layout.topMargin: 2
            vertical: false
        }

        RowLayout {
            Layout.fillWidth: true

            Heading {
                Layout.fillWidth: true
                text: strip.grid ? `Wallpaper · ${strip.grid.count}` : "Wallpaper"
            }

            Label {
                text: Config.wallpaperFolder
                pixelSize: 10
                color: Theme.fg3
                elide: Text.ElideMiddle
                Layout.maximumWidth: 260
                Layout.rightMargin: 4
            }
        }

        Item {
            id: strip

            readonly property WallpaperGrid grid: wallpapers.item as WallpaperGrid
            property real wheel: 0
            property bool swiped: false

            Layout.fillWidth: true
            implicitHeight: grid?.implicitHeight ?? Math.round((width - 30) / 4 * 9 / 16)

            Loader {
                id: wallpapers

                width: parent.width
                active: root.visited

                sourceComponent: WallpaperGrid {
                    columns: 4
                    rows: 2
                    folder: Wallpaper.expand(Config.wallpaperFolder)
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    const touchpad = wheel.pixelDelta.x !== 0 || wheel.pixelDelta.y !== 0;
                    if (touchpad) {
                        gesture.restart();
                        if (strip.swiped || Math.abs(wheel.angleDelta.x) <= Math.abs(wheel.angleDelta.y))
                            return;
                        strip.wheel += wheel.angleDelta.x;
                        if (Math.abs(strip.wheel) < 240)
                            return;
                    } else {
                        strip.wheel += wheel.angleDelta.y || wheel.angleDelta.x;
                        if (Math.abs(strip.wheel) < 120)
                            return;
                    }
                    strip.grid?.step(strip.wheel > 0 ? -1 : 1);
                    strip.wheel = 0;
                    strip.swiped = touchpad;
                }
            }

            Timer {
                id: gesture

                interval: 180
                onTriggered: {
                    strip.swiped = false;
                    strip.wheel = 0;
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            visible: (strip.grid?.pages ?? 1) > 1
            spacing: 2

            Repeater {
                model: strip.grid?.pages ?? 0

                Item {
                    id: dot

                    required property int index
                    readonly property bool current: index === strip.grid.page

                    width: 16
                    height: 16

                    Rectangle {
                        anchors.centerIn: parent
                        width: dot.current ? 8 : 6
                        height: width
                        radius: width / 2
                        antialiasing: true
                        color: dot.current ? Theme.red : pageMouse.containsMouse ? Theme.fg2 : Theme.fg3

                        Behavior on color {
                            EffectsColor {}
                        }
                    }

                    MouseArea {
                        id: pageMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: strip.grid.page = dot.index
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 8

            Pill {
                glyph: "gear"
                text: "All settings"
                onClicked: Session.openSettings()
            }

            Pill {
                glyph: "keyboard"
                text: "Keybinds"
                onClicked: Ui.toggleCheatsheet()
            }

            Item {
                Layout.fillWidth: true
            }

            Pill {
                glyph: "image"
                text: "Default wallpaper"
                visible: Store.wallpaper !== ""
                onClicked: Wallpaper.clear()
            }
        }
    }
}
