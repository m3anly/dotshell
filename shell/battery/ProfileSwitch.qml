pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import qs.components
import qs.services
import qs.theme

Rectangle {
    id: root

    readonly property var options: [
        {
            profile: PowerProfile.PowerSaver,
            glyph: "leaf",
            label: "Efficiency"
        },
        {
            profile: PowerProfile.Balanced,
            glyph: "half",
            label: "Balanced"
        },
        {
            profile: PowerProfile.Performance,
            glyph: "bolt",
            label: "Performance"
        }
    ]
    readonly property int current: options.findIndex(option => option.profile === Power.profile)
    readonly property real slot: (width - 8) / options.length

    implicitHeight: 68
    radius: 16
    color: Theme.fill
    border.width: 1
    border.color: Theme.line
    antialiasing: true

    Rectangle {
        id: indicator

        visible: root.current >= 0
        x: 4 + Math.max(0, root.current) * root.slot
        y: 4
        width: root.slot
        height: root.height - 8
        radius: 12
        color: Theme.fg
        antialiasing: true

        Behavior on x {
            enabled: !Motion.reduced

            SpatialFast {}
        }
    }

    Row {
        x: 4
        y: 4

        Repeater {
            model: root.options

            Item {
                id: option

                required property var modelData
                required property int index
                readonly property bool selected: index === root.current
                readonly property bool available: modelData.profile !== PowerProfile.Performance || Power.hasPerformance
                readonly property color tone: selected ? Theme.glassBase : Theme.fg

                width: root.slot
                height: root.height - 8
                opacity: available ? 1 : 0.35

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: mouse.containsMouse && !option.selected ? Theme.hover : "transparent"

                    Behavior on color {
                        EffectsColor {}
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    scale: mouse.pressed ? 0.9 : 1

                    Behavior on scale {
                        enabled: !Motion.reduced

                        SpatialFast {
                            epsilon: 0.002
                        }
                    }

                    DotIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: option.modelData.glyph
                        size: 16
                        color: option.tone

                        Behavior on color {
                            EffectsColor {}
                        }
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: option.modelData.label
                        pixelSize: 11
                        color: option.tone

                        Behavior on color {
                            EffectsColor {}
                        }
                    }
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    enabled: option.available
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Power.setProfile(option.modelData.profile)
                }
            }
        }
    }
}
