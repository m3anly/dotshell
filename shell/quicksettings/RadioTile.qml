import QtQuick
import QtQuick.Layouts
import qs.components
import qs.theme

Rectangle {
    id: root

    property string glyph
    property bool on: false
    property bool expanded: false
    property string title
    property string subtitle
    property real lowerRadius: expanded ? 6 : 16

    signal toggled
    signal opened

    implicitHeight: 60
    radius: 16
    bottomLeftRadius: lowerRadius
    bottomRightRadius: lowerRadius
    color: expanded ? Qt.rgba(1, 1, 1, 0.1) : Theme.fill
    border.width: 1
    border.color: expanded ? Theme.fg3 : Theme.line
    antialiasing: true

    Behavior on lowerRadius {
        enabled: !Motion.reduced

        SpatialStandard {}
    }
    Behavior on color {
        EffectsColor {}
    }
    Behavior on border.color {
        EffectsColor {}
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        MorphButton {
            implicitWidth: 48
            implicitHeight: 48
            restRadius: root.on ? 24 : 12
            pressRadius: 8
            pressScale: 0.88
            restColor: root.on ? Theme.fg : "transparent"
            outline: root.on ? "transparent" : Theme.fg3
            onClicked: root.toggled()

            DotIcon {
                anchors.centerIn: parent
                name: root.glyph
                size: 18
                color: root.on ? Theme.glassBase : Theme.fg2

                Behavior on color {
                    EffectsColor {}
                }
            }
        }

        MorphButton {
            Layout.fillWidth: true
            implicitHeight: 48
            restRadius: 12
            pressScale: 0.97
            restColor: "transparent"
            hoverColor: Theme.hover
            outline: "transparent"
            onClicked: root.opened()

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 6
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Body {
                        Layout.fillWidth: true
                        text: root.title
                        color: root.on ? Theme.fg : Theme.fg2

                        Behavior on color {
                            EffectsColor {}
                        }
                    }

                    Body {
                        Layout.fillWidth: true
                        text: root.subtitle
                        color: Theme.fg2
                        font.pixelSize: 11
                    }
                }

                DotIcon {
                    name: "chev"
                    size: 12
                    color: root.expanded ? Theme.fg : Theme.fg2
                    rotation: root.expanded ? 180 : 0

                    Behavior on rotation {
                        enabled: !Motion.reduced

                        SpatialStandard {}
                    }
                    Behavior on color {
                        EffectsColor {}
                    }
                }
            }
        }
    }
}
