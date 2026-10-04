pragma ComponentBehavior: Bound

import QtQuick
import qs.theme

Row {
    id: root

    property real dot: 4
    property color color: Theme.fg
    property real phase: 0

    spacing: dot * 0.75

    NumberAnimation on phase {
        from: 0
        to: 1
        duration: 900
        loops: Animation.Infinite
        running: root.visible && !Motion.reduced
    }

    Repeater {
        model: 3

        Rectangle {
            required property int index

            readonly property real local: (root.phase - index * 120 / 900 + 1) % 1
            readonly property real pulse: local < 0.4 ? local / 0.4 : (1 - local) / 0.6

            width: root.dot
            height: root.dot
            radius: root.dot / 2
            color: root.color
            scale: 0.6 + 0.7 * pulse
            opacity: 0.4 + 0.6 * pulse
        }
    }
}
