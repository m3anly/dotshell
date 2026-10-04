import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.theme

Rectangle {
    id: root

    property bool open: false
    property bool fromTop: false
    readonly property string kind: Osd.kind
    readonly property bool media: kind === "media"
    readonly property bool statusMode: Osd.isStatus
    readonly property bool levelMode: !media && !statusMode
    property real wheelRemainder: 0
    readonly property var level: {
        switch (kind) {
        case "mic":
            return {
                glyph: "mic",
                label: "Mic",
                value: Audio.percentOf(Audio.source),
                muted: Audio.source?.audio?.muted ?? false
            };
        case "brightness":
            return {
                glyph: "sun",
                label: "Bri",
                value: Brightness.percent,
                muted: false
            };
        default:
            return {
                glyph: "vol",
                label: "Vol",
                value: Audio.percentOf(Audio.sink),
                muted: Audio.sink?.audio?.muted ?? false
            };
        }
    }

    function setLevel(value: real): void {
        if (kind === "brightness") {
            Brightness.set(value);
            return;
        }
        Audio.setPercent(kind === "mic" ? Audio.source : Audio.sink, value);
        if (kind === "volume")
            Audio.volumeFeedback();
    }

    function stepLevel(step: int): void {
        if (media) {
            Media.changeVolume(step);
            return;
        }
        if (statusMode)
            return;
        setLevel(Math.max(0, Math.min(100, level.value + step)));
    }

    function toggleMute(): void {
        if (kind === "volume")
            Audio.toggleMute(Audio.sink);
        else if (kind === "mic")
            Audio.toggleMute(Audio.source);
    }

    width: statusMode ? statusRow.implicitWidth + 30 : 400
    height: 56
    radius: 28
    color: Theme.glass(Theme.tintBar)
    border.width: 1
    border.color: Theme.line
    antialiasing: true
    visible: opacity > 0
    opacity: 0
    scale: 0.85
    readonly property alias offset: shift.y

    transform: Translate {
        id: shift

        y: root.fromTop ? -30 : 30
    }

    states: State {
        name: "open"
        when: root.open

        PropertyChanges {
            root.opacity: 1
            root.scale: 1
            shift.y: 0
        }
    }

    transitions: [
        Transition {
            to: "open"
            enabled: !Motion.reduced

            ParallelAnimation {
                Effects {
                    property: "opacity"
                }
                SpatialStandard {
                    property: "scale"
                    epsilon: 0.002
                }
                SpatialStandard {
                    target: shift
                    property: "y"
                }
            }
        },
        Transition {
            from: "open"
            enabled: !Motion.reduced

            ParallelAnimation {
                Exit {
                    property: "opacity"
                    duration: 150
                }
                Exit {
                    properties: "scale,y"
                    duration: 200
                }
            }
        }
    ]

    Behavior on width {
        enabled: !Motion.reduced && root.open

        SpatialStandard {}
    }

    HoverHandler {
        onHoveredChanged: Osd.hovered = hovered
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y * 4 : event.angleDelta.y;
            root.wheelRemainder += delta;
            const steps = Math.trunc(root.wheelRemainder / 120);
            if (steps === 0)
                return;
            root.wheelRemainder -= steps * 120;
            root.stepLevel(steps * Math.max(1, root.kind === "brightness" ? Config.brightness.step : Config.audio.step));
        }
    }

    Binding {
        target: Osd
        property: "pressed"
        value: slider.dragging || muteButton.pressed
        when: root.open
    }

    component RoundButton: MorphButton {
        id: button

        property string glyph
        property color glyphColor: Theme.fg

        implicitWidth: 36
        implicitHeight: 36
        pressRadius: 8
        pressScale: 0.88

        DotIcon {
            anchors.centerIn: parent
            name: button.glyph
            color: button.glyphColor

            Behavior on color {
                EffectsColor {}
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 20
        spacing: 12
        opacity: root.levelMode ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Effects {}
        }

        RoundButton {
            id: muteButton

            glyph: root.level.glyph
            restRadius: root.level.muted ? 10 : 18
            restColor: root.level.muted ? Theme.red : Theme.fill
            hoverColor: root.level.muted ? Theme.red : Theme.hover
            outline: root.level.muted ? "transparent" : Theme.line
            enabled: root.kind !== "brightness"
            onClicked: root.toggleMute()
        }

        RollText {
            Layout.preferredWidth: 30
            text: root.level.label
            color: Theme.fg2
        }

        DotSlider {
            id: slider

            Layout.fillWidth: true
            value: root.level.value
            muted: root.level.muted
            onMoved: value => root.setLevel(value)
        }

        Body {
            Layout.preferredWidth: widest.advanceWidth
            horizontalAlignment: Text.AlignRight
            text: Math.round(slider.displayed)

            TextMetrics {
                id: widest

                font.family: Theme.uiFont
                font.pixelSize: 13
                text: "100"
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12
        opacity: root.media ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Effects {}
        }

        RoundButton {
            glyph: Media.playing ? "pause" : "play"
            restColor: Media.playing ? Theme.fg : Theme.fill
            hoverColor: Media.playing ? Theme.fg : Theme.hover
            glyphColor: Media.playing ? Theme.glassBase : Theme.fg
            onClicked: Media.playPause()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RollText {
                Layout.fillWidth: true
                text: Media.title || "Nothing playing"
                uppercase: false
                pixelSize: 13
            }

            RollText {
                Layout.fillWidth: true
                visible: Media.artist !== ""
                text: Media.artist
                color: Theme.fg2
                pixelSize: 11
            }
        }

        RoundButton {
            implicitWidth: 32
            implicitHeight: 32
            glyph: "prev"
            restColor: "transparent"
            outline: "transparent"
            hoverColor: Theme.hover
            enabled: Media.player?.canGoPrevious ?? false
            opacity: enabled ? 1 : 0.3
            onClicked: Media.previous()
        }

        RoundButton {
            implicitWidth: 32
            implicitHeight: 32
            glyph: "next"
            restColor: "transparent"
            outline: "transparent"
            hoverColor: Theme.hover
            enabled: Media.player?.canGoNext ?? false
            opacity: enabled ? 1 : 0.3
            onClicked: Media.next()
        }
    }

    RowLayout {
        id: statusRow

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        spacing: 12
        opacity: root.statusMode ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Effects {}
        }

        Rectangle {
            implicitWidth: 36
            implicitHeight: 36
            radius: Osd.status.on === false ? 10 : 18
            color: Osd.status.on === true ? Theme.fg : "transparent"
            border.width: 1
            border.color: Osd.status.on === true ? "transparent" : Osd.status.on === false ? Theme.fg3 : Theme.line
            antialiasing: true

            Behavior on radius {
                enabled: !Motion.reduced

                SpatialFast {}
            }
            Behavior on color {
                EffectsColor {}
            }

            DotIcon {
                anchors.centerIn: parent
                name: Osd.status.glyph
                color: Osd.status.on === true ? Theme.glassBase : Osd.status.on === false ? Theme.fg2 : Theme.fg

                Behavior on color {
                    EffectsColor {}
                }
            }
        }

        RollText {
            Layout.preferredWidth: implicitWidth
            text: Osd.status.label
            rollKey: root.kind
            uppercase: root.kind !== "layout"
            pixelSize: root.kind === "layout" ? 13 : Theme.labelSize
        }

        Rectangle {
            Layout.leftMargin: 6
            implicitWidth: 6
            implicitHeight: 6
            radius: 3
            visible: Osd.status.on !== null
            color: Osd.status.on ? Theme.red : Theme.off

            Behavior on color {
                EffectsColor {}
            }
        }

        RollText {
            Layout.preferredWidth: implicitWidth
            text: Osd.status.state
            direction: Osd.status.on === false ? -1 : 1
            color: Theme.fg2
        }
    }
}
