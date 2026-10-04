pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.theme

Flow {
    id: root

    property var options: []
    property var values: []

    signal edited(var values)

    spacing: 6

    Repeater {
        model: root.options

        MorphButton {
            id: chip

            required property var modelData
            readonly property bool selected: root.values.includes(modelData.value)

            implicitWidth: label.implicitWidth + 28
            implicitHeight: 32
            restRadius: selected ? 16 : 10
            pressRadius: 8
            restColor: selected ? Theme.fg : Theme.fill
            hoverColor: selected ? Theme.fg : Theme.hover
            outline: selected ? "transparent" : Theme.line
            onClicked: root.edited(selected ? root.values.filter(value => value !== modelData.value) : [...root.values, modelData.value])

            Label {
                id: label

                anchors.centerIn: parent
                text: chip.modelData.label
                pixelSize: 12
                color: chip.selected ? Theme.glassBase : Theme.fg2

                Behavior on color {
                    EffectsColor {}
                }
            }
        }
    }
}
