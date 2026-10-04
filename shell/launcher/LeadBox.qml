import QtQuick
import Quickshell.Widgets
import qs.components
import qs.theme

Rectangle {
    id: root

    property bool selected: false
    property real size: 36
    property real restRadius: 11
    property real monogramSize: 20
    property string monogram: ""
    property string glyph: ""
    property string swatch: ""
    property string image: ""
    property string icon: ""
    readonly property bool hasIcon: icon !== "" && appIcon.status === Image.Ready
    readonly property bool isSwatch: swatch !== ""

    implicitWidth: size
    implicitHeight: size
    radius: selected ? size / 2 : restRadius
    color: isSwatch ? swatch : selected ? Theme.fg : Theme.fill
    border.width: isSwatch && selected ? 3 : 1
    border.color: isSwatch && selected ? Theme.fg : Theme.line
    antialiasing: true

    Behavior on radius {
        enabled: !Motion.reduced

        SpatialStandard {}
    }
    Behavior on color {
        EffectsColor {}
    }
    Behavior on border.color {
        EffectsColor {}
    }

    DisplayText {
        anchors.centerIn: parent
        visible: root.monogram !== "" && !root.hasIcon
        text: root.monogram
        font.pixelSize: root.monogramSize
        color: root.selected ? Theme.glassBase : Theme.fg

        Behavior on color {
            EffectsColor {}
        }
    }

    IconImage {
        id: appIcon

        anchors.centerIn: parent
        implicitSize: Math.round(root.size * 0.64)
        visible: root.hasIcon
        source: root.icon
        asynchronous: true
        mipmap: true
    }

    RoundedImage {
        id: thumbnail

        anchors.fill: parent
        anchors.margins: 1
        visible: status === Image.Ready
        radius: Math.max(0, root.radius - 1)
        source: root.image !== "" ? `file://${root.image}` : ""
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        asynchronous: true
    }

    DotIcon {
        anchors.centerIn: parent
        visible: root.glyph !== "" && !root.isSwatch && !(root.image !== "" && thumbnail.status === Image.Ready)
        name: root.glyph
        color: root.selected ? Theme.glassBase : Theme.fg2
    }
}
