pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.theme

Rectangle {
    id: root

    property string mode: "search"
    property bool animate: false
    readonly property Item current: mode === "clipboard" ? clipboardSegment : searchSegment

    signal picked(string mode)

    component Segment: Item {
        id: segment

        required property string value
        required property string title
        readonly property bool selected: root.mode === value

        implicitWidth: label.implicitWidth + 28
        implicitHeight: 30

        Label {
            id: label

            anchors.centerIn: parent
            text: segment.title
            pixelSize: 12
            tracking: 0.06
            color: segment.selected ? Theme.glassBase : Theme.fg2

            Behavior on color {
                EffectsColor {}
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.picked(segment.value)
        }
    }

    implicitWidth: segments.implicitWidth + 6
    implicitHeight: 36
    radius: 18
    color: Theme.fill
    border.width: 1
    border.color: Theme.line
    antialiasing: true

    Rectangle {
        x: segments.x + root.current.x
        y: 3
        width: root.current.width
        height: 30
        radius: 15
        color: Theme.fg
        antialiasing: true

        Behavior on x {
            enabled: root.animate && !Motion.reduced

            SpatialFast {}
        }
        Behavior on width {
            enabled: root.animate && !Motion.reduced

            SpatialStandard {}
        }
    }

    Row {
        id: segments

        x: 3
        y: 3

        Segment {
            id: searchSegment

            value: "search"
            title: "Search"
        }

        Segment {
            id: clipboardSegment

            value: "clipboard"
            title: "Clipboard"
        }
    }
}
