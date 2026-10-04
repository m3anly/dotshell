pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.components
import qs.quicksettings
import qs.services
import qs.theme

TabPage {
    id: root

    property bool open: false
    property bool pickerOpen: false
    readonly property bool hasPlayer: Media.player !== null
    readonly property bool seekable: Media.length > 0

    tab: "media"
    implicitHeight: layout.implicitHeight

    onOpenChanged: {
        if (!open)
            pickerOpen = false;
    }

    component TransportButton: MorphButton {
        id: button

        property string glyph
        property bool primary: false
        property bool lit: false
        property bool marked: false

        implicitWidth: primary ? 56 : 40
        implicitHeight: implicitWidth
        restRadius: primary && Media.playing ? 16 : implicitWidth / 2
        pressRadius: primary ? 10 : 8
        pressScale: 0.88
        restColor: primary && Media.playing ? Theme.fg : primary || lit ? Theme.fill : "transparent"
        hoverColor: primary && Media.playing ? Theme.fg : Theme.hover
        outline: primary && !Media.playing || lit ? Theme.line : "transparent"
        opacity: enabled ? 1 : 0.3

        DotIcon {
            anchors.centerIn: parent
            name: button.glyph
            size: button.primary ? 16 : 14
            color: button.primary && Media.playing ? Theme.glassBase : button.lit || button.primary || button.glyph === "prev" || button.glyph === "next" ? Theme.fg : Theme.fg3

            Behavior on color {
                EffectsColor {}
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 5
            width: 4
            height: 4
            radius: 2
            color: Theme.red
            scale: button.marked ? 1 : 0

            Behavior on scale {
                enabled: !Motion.reduced

                SpatialFast {
                    epsilon: 0.002
                }
            }
        }
    }

    component PlayerChip: MorphButton {
        id: chip

        required property MprisPlayer modelData
        readonly property bool selected: modelData === Media.player

        implicitWidth: chipRow.implicitWidth + 22
        implicitHeight: 26
        restRadius: selected ? 8 : 13
        pressRadius: 6
        restColor: selected ? Theme.fg : "transparent"
        hoverColor: selected ? Theme.fg : Theme.hover
        outline: selected ? "transparent" : Theme.line
        onClicked: Media.choose(modelData)

        Row {
            id: chipRow

            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 5
                height: 5
                radius: 2.5
                color: chip.modelData?.isPlaying ? Theme.red : chip.selected ? Qt.rgba(0, 0, 0, 0.3) : Theme.fg3
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.modelData?.identity ?? ""
                pixelSize: 10
                color: chip.selected ? Theme.glassBase : Theme.fg2

                Behavior on color {
                    EffectsColor {}
                }
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            SpectrumRing {
                Layout.alignment: Qt.AlignVCenter
                visible: root.current || root.opacity > 0
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Flow {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    visible: Media.players.length > 1
                    spacing: 6

                    Repeater {
                        model: Media.players

                        PlayerChip {}
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: Media.players.length <= 1
                    text: root.hasPlayer ? Media.player.identity : "No player"
                    pixelSize: 10
                    color: Theme.fg3
                }

                RollText {
                    Layout.fillWidth: true
                    text: root.hasPlayer ? Media.title || "Unknown track" : "Nothing playing"
                    uppercase: false
                    pixelSize: 18
                }

                RollText {
                    Layout.fillWidth: true
                    text: root.hasPlayer ? Media.artist : "Start a player to see it here"
                    uppercase: false
                    pixelSize: 13
                    color: Theme.fg2
                }

                RollText {
                    Layout.fillWidth: true
                    visible: Media.album !== ""
                    text: Media.album
                    pixelSize: 11
                    color: Theme.fg3
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    spacing: 10
                    opacity: root.seekable ? 1 : 0.35

                    Label {
                        text: Media.formatTime(Media.position)
                        color: Theme.fg2
                        pixelSize: 11
                    }

                    DotSlider {
                        Layout.fillWidth: true
                        value: root.seekable ? Media.position / Media.length * 100 : 0
                        enabled: root.seekable && (Media.player?.canSeek ?? false)
                        onMoved: value => Media.seekTo(value / 100)
                    }

                    Label {
                        text: root.seekable ? Media.formatTime(Media.length) : "-:--"
                        color: Theme.fg2
                        pixelSize: 11
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    spacing: 6

                    TransportButton {
                        glyph: "shuffle"
                        enabled: Media.player?.shuffleSupported ?? false
                        lit: Media.shuffle
                        onClicked: Media.toggleShuffle()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TransportButton {
                        glyph: "prev"
                        enabled: Media.player?.canGoPrevious ?? false
                        onClicked: Media.previous()
                    }

                    TransportButton {
                        glyph: Media.playing ? "pause" : "play"
                        primary: true
                        enabled: Media.player?.canTogglePlaying ?? false
                        onClicked: Media.playPause()
                    }

                    TransportButton {
                        glyph: "next"
                        enabled: Media.player?.canGoNext ?? false
                        onClicked: Media.next()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    TransportButton {
                        glyph: "repeat"
                        enabled: Media.player?.loopSupported ?? false
                        lit: Media.loopState !== MprisLoopState.None
                        marked: Media.loopState === MprisLoopState.Track
                        onClicked: Media.cycleLoop()
                    }
                }
            }
        }

        DottedLine {
            Layout.fillWidth: true
            vertical: false
        }

        AudioRow {
            Layout.fillWidth: true
            shown: true
            node: Audio.sink
            glyph: "vol"
            heading: "Out"
            expanded: root.pickerOpen
            onPickerToggled: root.pickerOpen = !root.pickerOpen
        }
    }
}
