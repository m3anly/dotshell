import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components
import qs.services
import qs.theme

Reveal {
    id: root

    property PwNode node
    property string glyph
    property string heading
    property bool output: true
    property bool expanded: false
    readonly property bool available: node?.audio !== undefined && node?.audio !== null
    readonly property int volume: available ? Math.round(node.audio.volume * 100) : 0
    readonly property bool muted: available && node.audio.muted

    signal pickerToggled

    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 12

            MorphButton {
                implicitWidth: 42
                implicitHeight: 42
                restRadius: root.muted ? 10 : 21
                pressScale: 0.88
                restColor: root.muted ? Theme.red : Theme.fill
                outline: root.muted ? "transparent" : Theme.line
                onClicked: {
                    if (root.available)
                        root.node.audio.muted = !root.node.audio.muted;
                }

                DotIcon {
                    anchors.centerIn: parent
                    name: root.glyph
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 9

                MorphButton {
                    Layout.fillWidth: true
                    Layout.leftMargin: -6
                    implicitHeight: 22
                    restRadius: 8
                    pressRadius: 11
                    pressScale: 0.97
                    restColor: root.expanded ? Theme.fill : "transparent"
                    hoverColor: Theme.hover
                    outline: "transparent"
                    onClicked: root.pickerToggled()

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 6

                        Label {
                            text: root.heading
                            color: Theme.fg2
                        }

                        Label {
                            Layout.fillWidth: true
                            text: Audio.label(root.node)
                            elide: Text.ElideRight
                        }

                        DotIcon {
                            size: 10
                            name: "chev"
                            color: root.expanded ? Theme.fg : Theme.fg2
                            rotation: root.expanded ? 180 : 0

                            Behavior on rotation {
                                enabled: !Motion.reduced

                                SpatialFast {}
                            }
                        }
                    }
                }

                DotSlider {
                    id: slider

                    Layout.fillWidth: true
                    value: root.volume
                    muted: root.muted
                    enabled: root.available
                    onMoved: value => {
                        root.node.audio.volume = value / 100;
                        if (root.output)
                            Audio.volumeFeedback();
                    }
                }
            }

            Body {
                Layout.preferredWidth: widest.advanceWidth
                horizontalAlignment: Text.AlignRight
                text: Math.round(slider.displayed)

                TextMetrics {
                    id: widest

                    font.family: Theme.uiFont
                    font.pixelSize: 13
                    text: "100"
                }
            }
        }

        AudioPicker {
            Layout.fillWidth: true
            open: root.expanded
            output: root.output
        }
    }
}
