pragma ComponentBehavior: Bound

import QtQuick
import qs.theme

Item {
    id: root

    property real level: 0
    property bool charging: false
    readonly property int count: 24
    readonly property int lit: Math.max(1, Math.round(Math.max(0, Math.min(1, level)) * count))
    readonly property real dot: 10

    implicitHeight: 18

    Repeater {
        model: root.count

        Rectangle {
            id: cell

            required property int index
            readonly property bool tip: index === root.lit - 1

            x: index * (root.width - root.dot) / (root.count - 1)
            anchors.verticalCenter: parent.verticalCenter
            width: root.dot
            height: root.dot
            radius: root.dot / 2
            antialiasing: true
            scale: tip ? 1.35 : 1
            color: tip ? Theme.red : index < root.lit ? Theme.fg : Theme.off

            Behavior on color {
                EffectsColor {}
            }
            Behavior on scale {
                enabled: !Motion.reduced

                SpatialFast {
                    epsilon: 0.002
                }
            }

            SequentialAnimation on opacity {
                running: cell.tip && root.charging && !Motion.reduced
                loops: Animation.Infinite
                onRunningChanged: {
                    if (!running)
                        cell.opacity = 1;
                }

                Effects {
                    to: 0.3
                    duration: 600
                }
                Effects {
                    to: 1
                    duration: 600
                }
            }
        }
    }
}
