import QtQuick
import qs.components
import qs.theme

MorphButton {
    id: root

    property bool on: false

    signal toggled(bool value)

    implicitWidth: 44
    implicitHeight: 44
    restRadius: on ? 22 : 12
    pressRadius: 8
    pressScale: 0.88
    restColor: on ? Theme.fg : "transparent"
    hoverColor: on ? Theme.fg : Theme.hover
    outline: on ? "transparent" : Theme.fg3
    onClicked: toggled(!on)

    Rectangle {
        anchors.centerIn: parent
        width: root.on ? 10 : 8
        height: width
        radius: width / 2
        color: root.on ? Theme.red : Theme.fg3
        antialiasing: true

        Behavior on width {
            enabled: !Motion.reduced

            SpatialFast {}
        }
        Behavior on color {
            EffectsColor {}
        }
    }
}
