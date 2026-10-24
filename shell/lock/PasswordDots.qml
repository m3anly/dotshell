pragma ComponentBehavior: Bound

import QtQuick
import qs.theme

Item {
    id: dots

    property int typed: 0
    property int failures: 0
    property real maxWidth: 400
    property int pitch: 22
    property int size: 10
    readonly property bool template: typed === 0
    readonly property int capacity: Math.max(6, Math.floor(maxWidth / pitch))
    readonly property int count: template ? 6 : Math.min(typed, capacity)

    width: count * pitch - (pitch - size)
    height: size
    transform: Translate {
        id: shakeOffset
    }

    onFailuresChanged: {
        if (failures > 0 && !Motion.reduced)
            shake.restart();
    }

    Behavior on width {
        enabled: !Motion.reduced

        SpatialStandard {}
    }

    Repeater {
        model: Math.max(6, dots.count)

        Rectangle {
            required property int index
            property bool born: false
            readonly property bool present: born && index < dots.count
            readonly property bool filled: present && !dots.template

            x: index * dots.pitch
            width: dots.size
            height: dots.size
            radius: dots.size / 2
            color: filled ? Theme.fg : "transparent"
            border.width: 1
            border.color: dots.failures > 0 && dots.template ? Theme.red : Theme.fg2
            opacity: present ? 1 : 0
            scale: !present ? 0.3 : filled ? 1.15 : 1
            antialiasing: true
            Component.onCompleted: born = true

            Behavior on color {
                EffectsColor {}
            }
            Behavior on border.color {
                EffectsColor {}
            }
            Behavior on opacity {
                Effects {}
            }
            Behavior on scale {
                enabled: !Motion.reduced

                SpatialFast {
                    epsilon: 0.002
                }
            }
        }
    }

    SequentialAnimation {
        id: shake

        PropertyAction {
            target: shakeOffset
            property: "x"
            value: 18
        }
        SpatialFast {
            target: shakeOffset
            property: "x"
            to: 0
        }
    }
}
