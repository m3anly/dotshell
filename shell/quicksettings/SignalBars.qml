pragma ComponentBehavior: Bound

import QtQuick
import qs.theme

Row {
    id: root

    property int bars: 0

    width: 16
    height: 16
    spacing: 2

    Repeater {
        model: [0.3, 0.55, 0.8, 1]

        Rectangle {
            required property real modelData
            required property int index

            y: root.height - height
            width: 2.5
            height: root.height * modelData
            radius: 1.25
            color: index <= root.bars ? Theme.fg : Theme.off

            Behavior on color {
                EffectsColor {}
            }
        }
    }
}
