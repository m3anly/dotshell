import QtQuick
import qs.theme

Rectangle {
    id: root

    property real restRadius: height / 2
    property real hoverRadius: restRadius
    property real pressRadius: restRadius
    property real pressScale: 0.94
    property color restColor: Theme.fill
    property color hoverColor: restColor
    property color outline: Theme.line
    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed

    signal clicked
    signal pressStarted
    signal pressEnded

    radius: pressed ? pressRadius : hovered ? hoverRadius : restRadius
    color: hovered ? hoverColor : restColor
    border.width: 1
    border.color: outline
    scale: pressed ? pressScale : 1
    antialiasing: true

    Behavior on radius {
        enabled: !Motion.reduced

        SpatialStandard {}
    }
    Behavior on scale {
        enabled: !Motion.reduced

        SpatialFast {
            epsilon: 0.002
        }
    }
    Behavior on color {
        EffectsColor {}
    }
    Behavior on border.color {
        EffectsColor {}
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onPressed: root.pressStarted()
        onReleased: root.pressEnded()
        onCanceled: root.pressEnded()
    }
}
