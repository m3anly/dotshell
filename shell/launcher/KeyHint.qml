import QtQuick
import qs.components
import qs.theme

Rectangle {
    id: root

    property string keys
    property string label
    property string action: ""
    property bool primary: false
    readonly property bool clickable: action !== ""
    readonly property bool hovered: clickable && mouse.containsMouse

    signal triggered(string action)

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 28
    radius: 8
    color: hovered ? Theme.hover : "transparent"
    scale: clickable && mouse.pressed ? 0.92 : 1

    Behavior on color {
        EffectsColor {}
    }
    Behavior on scale {
        enabled: !Motion.reduced

        SpatialFast {
            epsilon: 0.002
        }
    }

    Row {
        id: row

        x: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            width: Math.max(22, key.implicitWidth + 10)
            height: 20
            radius: 6
            color: root.primary ? Theme.fg : "transparent"
            border.width: root.primary ? 0 : 1
            border.color: Theme.line
            antialiasing: true

            Label {
                id: key

                anchors.centerIn: parent
                text: root.keys
                pixelSize: 11
                tracking: 0.06
                color: root.primary ? Theme.glassBase : Theme.fg
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            pixelSize: 11
            tracking: 0.06
            color: root.hovered ? Theme.fg : Theme.fg2

            Behavior on color {
                EffectsColor {}
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: root.clickable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered(root.action)
    }
}
