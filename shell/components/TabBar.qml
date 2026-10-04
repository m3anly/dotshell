pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services
import qs.theme

Rectangle {
    id: root

    property string group: "dashboard"
    property var tabs: []
    readonly property int current: tabs.findIndex(tab => tab.id === Ui[`${group}Tab`])
    readonly property real slot: (width - 6) / tabs.length
    property bool animate: false

    implicitHeight: 40
    radius: 20
    color: Theme.fill
    border.width: 1
    border.color: Theme.line
    antialiasing: true

    Rectangle {
        x: 3 + Math.max(0, root.current) * root.slot
        y: 3
        width: root.slot
        height: root.height - 6
        radius: height / 2
        color: Theme.fg
        antialiasing: true

        Behavior on x {
            enabled: root.animate && !Motion.reduced

            SpatialFast {}
        }
    }

    Row {
        x: 3
        y: 3

        Repeater {
            model: root.tabs

            Item {
                id: tab

                required property var modelData
                required property int index
                readonly property bool selected: index === root.current
                readonly property color tone: selected ? Theme.glassBase : Theme.fg2

                width: root.slot
                height: root.height - 6

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: mouse.containsMouse && !tab.selected ? Theme.hover : "transparent"

                    Behavior on color {
                        EffectsColor {}
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    scale: mouse.pressed ? 0.9 : 1

                    Behavior on scale {
                        enabled: !Motion.reduced

                        SpatialFast {
                            epsilon: 0.002
                        }
                    }

                    DotIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: tab.modelData.glyph
                        size: 12
                        color: tab.tone

                        Behavior on color {
                            EffectsColor {}
                        }
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.label
                        pixelSize: 12
                        color: tab.tone

                        Behavior on color {
                            EffectsColor {}
                        }
                    }
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Ui.setTab(root.group, tab.modelData.id)
                }
            }
        }
    }
}
