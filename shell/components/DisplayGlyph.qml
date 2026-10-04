pragma ComponentBehavior: Bound

import QtQuick
import qs.theme
import "Glyphs.js" as Glyphs

Item {
    id: root

    property string character
    property real pixelSize: 40
    property color color: Theme.fg
    readonly property var glyph: Glyphs.displayGlyph(character)
    readonly property bool drawn: glyph !== null
    readonly property real cellWidth: pixelSize * 0.6
    readonly property real pitch: drawn ? Math.max(1, Math.round(glyph.pitch * pixelSize)) : 0
    readonly property real dotSize: drawn ? Math.max(1, Math.round(glyph.dot * pixelSize)) : 0
    readonly property real centerY: text.baselineOffset - pixelSize * 0.35

    implicitWidth: drawn ? Math.max(cellWidth, (glyph.columns - 1) * pitch + pixelSize * 0.2) : text.implicitWidth
    implicitHeight: text.implicitHeight

    DisplayText {
        id: text

        opacity: root.drawn ? 0 : 1
        text: root.drawn ? " " : root.character
        font.pixelSize: root.pixelSize
        color: root.color
    }

    Repeater {
        model: root.drawn ? root.glyph.dots : []

        Rectangle {
            required property var modelData

            x: Math.round(root.pixelSize * 0.05 - width / 2) + modelData.x * root.pitch
            y: Math.round(root.centerY - (root.glyph.rows - 1) / 2 * root.pitch - height / 2) + modelData.y * root.pitch
            width: root.dotSize
            height: width
            radius: width / 2
            color: root.color
            antialiasing: width > 2
        }
    }
}
