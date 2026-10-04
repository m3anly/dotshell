import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

Reveal {
    id: root

    implicitHeight: 14 + row.implicitHeight + powerRow.implicitHeight

    DottedLine {
        vertical: false
        width: parent.width
    }

    component Pill: MorphButton {
        id: pill

        property string glyph
        property string text
        property color glyphColor: Theme.fg
        property color textColor: Theme.fg
        property real glyphRotation: 0

        implicitWidth: pillRow.implicitWidth + 32
        implicitHeight: 40
        restRadius: 20
        pressRadius: 8
        hoverColor: Qt.rgba(1, 1, 1, 0.1)

        Row {
            id: pillRow

            anchors.centerIn: parent
            spacing: 10

            DotIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: pill.glyph
                color: pill.glyphColor
                rotation: pill.glyphRotation

                Behavior on rotation {
                    enabled: !Motion.reduced

                    SpatialStandard {}
                }
                Behavior on color {
                    EffectsColor {}
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.text
                color: pill.textColor

                Behavior on color {
                    EffectsColor {}
                }
            }
        }
    }

    RowLayout {
        id: row

        y: 14
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        Pill {
            glyph: "gear"
            text: "Settings"
            onClicked: Session.openSettings()
        }

        Item {
            Layout.fillWidth: true
        }

        Pill {
            glyph: "power"
            text: "Power"
            restRadius: Ui.powerExpanded ? 10 : 20
            restColor: Ui.powerExpanded ? Theme.red : Theme.fill
            hoverColor: Ui.powerExpanded ? Theme.red : Qt.rgba(1, 1, 1, 0.1)
            outline: Ui.powerExpanded ? "transparent" : Theme.line
            glyphColor: Ui.powerExpanded ? "white" : Theme.red
            textColor: Ui.powerExpanded ? "white" : Theme.fg
            glyphRotation: Ui.powerExpanded ? 90 : 0
            onClicked: Ui.powerExpanded = !Ui.powerExpanded
        }
    }

    PowerRow {
        id: powerRow

        y: row.y + row.height
        width: parent.width
        open: root.shown && Ui.powerExpanded
    }
}
