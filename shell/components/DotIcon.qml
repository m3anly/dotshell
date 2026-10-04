pragma ComponentBehavior: Bound

import QtQuick
import qs.theme
import "Glyphs.js" as Glyphs

Item {
    id: root

    property string name
    property color color: Theme.fg
    property real size: Theme.iconSize
    readonly property real cell: width / 7

    implicitWidth: size
    implicitHeight: size

    Repeater {
        model: Glyphs.iconDots(root.name)

        Rectangle {
            required property var modelData

            x: (modelData.x + 0.08) * root.cell
            y: (modelData.y + 0.08) * root.cell
            width: root.cell * 0.84
            height: width
            radius: width / 2
            color: root.color
            antialiasing: true
        }
    }
}
