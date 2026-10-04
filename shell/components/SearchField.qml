import QtQuick
import QtQuick.Layouts
import qs.theme

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder
    readonly property alias input: input

    signal accepted

    implicitHeight: 46
    radius: input.activeFocus ? 12 : 23
    color: Theme.fill
    border.width: 1
    border.color: input.activeFocus ? Theme.fg2 : Theme.line
    antialiasing: true

    Behavior on radius {
        enabled: !Motion.reduced

        SpatialStandard {}
    }
    Behavior on border.color {
        EffectsColor {}
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        DotIcon {
            name: "search"
            color: Theme.fg2
        }

        TextInput {
            id: input

            Layout.fillWidth: true
            font.family: Theme.uiFont
            font.pixelSize: 15
            color: Theme.fg
            selectionColor: Theme.fg2
            clip: true
            onAccepted: root.accepted()

            Body {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                text: root.placeholder
                color: Theme.fg3
                font.pixelSize: 15
            }
        }
    }
}
