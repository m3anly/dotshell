pragma ComponentBehavior: Bound

import QtQuick
import qs.theme

Item {
    id: root

    property real value: 0
    property bool muted: false
    property real dragValue: 0
    readonly property int count: 22
    readonly property bool dragging: mouse.pressed
    readonly property real displayed: dragging ? dragValue : value
    readonly property int lit: Math.round(Math.max(0, Math.min(100, displayed)) / 100 * count)
    readonly property real dot: 7
    readonly property real pitch: (width - dot) / (count - 1)

    signal moved(real value)

    implicitHeight: 16
    activeFocusOnTab: true

    function step(delta: real): void {
        moved(Math.max(0, Math.min(100, Math.round(value) + delta)));
    }

    function valueAt(x: real): real {
        const cells = (x - dot / 2) / pitch + 1;
        return Math.round(Math.max(0, Math.min(count, cells)) / count * 100);
    }

    function drag(x: real): void {
        dragValue = valueAt(x);
        moved(dragValue);
    }

    Keys.onRightPressed: step(5)
    Keys.onUpPressed: step(5)
    Keys.onLeftPressed: step(-5)
    Keys.onDownPressed: step(-5)

    Repeater {
        model: root.count

        Rectangle {
            id: dot

            required property int index
            readonly property bool tip: index === root.lit - 1
            readonly property bool on: index < root.lit - 1
            readonly property bool stretched: tip && root.dragging

            x: index * root.pitch
            anchors.verticalCenter: parent.verticalCenter
            width: root.dot
            height: root.dot
            radius: stretched ? 2 : root.dot / 2
            antialiasing: true
            color: {
                if (tip)
                    return root.muted ? Theme.fg2 : Theme.red;
                if (on)
                    return root.muted ? Theme.fg3 : Theme.fg;
                return Theme.off;
            }
            transform: Scale {
                origin.x: root.dot / 2
                origin.y: root.dot / 2
                xScale: dot.stretched ? 2 : dot.tip ? 1.35 : 1
                yScale: dot.stretched ? 2.8 : dot.tip ? 1.35 : 1

                Behavior on xScale {
                    enabled: !Motion.reduced

                    SpatialFast {
                        epsilon: 0.002
                    }
                }
                Behavior on yScale {
                    enabled: !Motion.reduced

                    SpatialFast {
                        epsilon: 0.002
                    }
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.effectsCurve
                }
            }
            Behavior on radius {
                enabled: !Motion.reduced

                SpatialStandard {}
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: event => {
            root.forceActiveFocus();
            root.drag(event.x);
        }
        onPositionChanged: event => root.drag(event.x)
    }
}
