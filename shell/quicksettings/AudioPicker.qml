pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.theme

Item {
    id: root

    property bool open: false
    property bool output: true
    property real openness: 0
    readonly property var nodes: output ? Audio.sinks : Audio.sources
    readonly property PwNode current: output ? Audio.sink : Audio.source

    implicitHeight: Math.round((card.height + 8) * openness)
    visible: openness > 0
    clip: true

    states: State {
        name: "open"
        when: root.open

        PropertyChanges {
            root.openness: 1
        }
    }

    transitions: [
        Transition {
            to: "open"
            enabled: !Motion.reduced

            Expand {
                property: "openness"
            }
        },
        Transition {
            from: "open"
            enabled: !Motion.reduced

            Exit {
                property: "openness"
                duration: 220
            }
        }
    ]

    Rectangle {
        id: card

        y: 8
        width: parent.width
        height: column.implicitHeight + 16
        radius: 16
        color: Qt.rgba(1, 1, 1, 0.05)
        border.width: 1
        border.color: Theme.line
        antialiasing: true

        ColumnLayout {
            id: column

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 4

            Label {
                Layout.fillWidth: true
                visible: root.nodes.length === 0
                topPadding: 14
                bottomPadding: 14
                text: root.output ? "No output devices" : "No input devices"
                color: Theme.fg2
                pixelSize: 12
                tracking: 0.08
                horizontalAlignment: Text.AlignHCenter
            }

            Repeater {
                model: root.nodes

                ListRow {
                    id: row

                    required property PwNode modelData
                    required property int index

                    Layout.fillWidth: true
                    current: root.current === modelData
                    name: Audio.label(modelData)
                    status: current ? `${Audio.bus(modelData)} · in use` : Audio.bus(modelData)
                    opacity: root.open ? 1 : 0
                    onClicked: Audio.setDefault(modelData)

                    lead: DotIcon {
                        name: Audio.glyph(row.modelData)
                        size: 16
                        color: row.current ? Theme.fg : Theme.fg2
                    }

                    Behavior on opacity {
                        enabled: !Motion.reduced

                        SequentialAnimation {
                            PauseAnimation {
                                duration: root.open ? Math.min(row.index, 9) * 30 : 0
                            }
                            Effects {}
                        }
                    }
                }
            }
        }
    }
}
