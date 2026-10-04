pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.theme

Rectangle {
    id: root

    property var options: []
    property string value
    readonly property int current: options.findIndex(option => option.value === value)

    signal picked(string value)

    implicitWidth: segments.implicitWidth + 6
    implicitHeight: 36
    radius: 18
    color: Theme.fill
    border.width: 1
    border.color: Theme.line
    antialiasing: true

    Rectangle {
        readonly property Item target: root.current >= 0 && repeater.count > root.current ? repeater.itemAt(root.current) : null

        visible: target !== null
        x: segments.x + (target?.x ?? 0)
        y: 3
        width: target?.width ?? 0
        height: 30
        radius: 15
        color: Theme.fg
        antialiasing: true

        Behavior on x {
            enabled: !Motion.reduced

            SpatialFast {}
        }
        Behavior on width {
            enabled: !Motion.reduced

            SpatialStandard {}
        }
    }

    Row {
        id: segments

        x: 3
        y: 3

        Repeater {
            id: repeater

            model: root.options

            Item {
                id: segment

                required property var modelData
                required property int index
                readonly property bool selected: index === root.current

                implicitWidth: label.implicitWidth + 28
                implicitHeight: 30
                width: implicitWidth
                height: implicitHeight

                Label {
                    id: label

                    anchors.centerIn: parent
                    text: segment.modelData.label
                    pixelSize: 12
                    color: segment.selected ? Theme.glassBase : Theme.fg2

                    Behavior on color {
                        EffectsColor {}
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(segment.modelData.value)
                }
            }
        }
    }
}
