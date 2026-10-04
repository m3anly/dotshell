import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.theme

Reveal {
    id: root

    property string title
    property string description
    property string key
    property bool wide: false
    property int indent: 0
    property bool divider: true
    readonly property bool locked: key !== "" && Config.isPinned(key)
    default property alias control: slot.data

    implicitHeight: grid.implicitHeight + 32

    GridLayout {
        id: grid

        anchors.left: parent.left
        anchors.leftMargin: root.indent
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        columns: root.wide ? 1 : 2
        columnSpacing: 20
        rowSpacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Body {
                Layout.fillWidth: true
                text: root.title
            }

            Text {
                Layout.fillWidth: true
                visible: root.description !== ""
                text: root.description
                font.family: Theme.uiFont
                font.pixelSize: 11
                color: Theme.fg2
                wrapMode: Text.Wrap
                lineHeight: 1.15
                textFormat: Text.PlainText
            }

            Row {
                visible: root.locked
                topPadding: 2
                spacing: 6

                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "lock"
                    size: 10
                    color: Theme.fg2
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Set by Home Manager"
                    pixelSize: 10
                    color: Theme.fg2
                }
            }
        }

        ColumnLayout {
            id: slot

            Layout.fillWidth: root.wide
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            enabled: !root.locked
            opacity: root.locked ? 0.45 : 1
            spacing: 10
        }
    }

    DottedLine {
        visible: root.divider
        anchors.bottom: parent.bottom
        width: parent.width
        vertical: false
    }
}
