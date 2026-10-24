pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.theme

Row {
    id: root

    property real em: 240

    DisplayText {
        id: hours

        text: Time.hhmm.slice(0, 2)
        font.pixelSize: root.em
        font.weight: 600
    }

    Item {
        readonly property real digitCenter: 0.35

        width: root.em * (0.105 + 0.11 + 0.165)
        height: hours.height

        Column {
            x: root.em * 0.105
            y: hours.baselineOffset - root.em * parent.digitCenter - height / 2 + root.em * 0.005
            spacing: root.em * 0.19

            Repeater {
                model: 2

                Rectangle {
                    width: root.em * 0.11
                    height: width
                    radius: width / 2
                    color: Theme.red
                    antialiasing: true
                }
            }
        }
    }

    DisplayText {
        text: Time.hhmm.slice(2, 4)
        font.pixelSize: root.em
        font.weight: 600
    }
}
