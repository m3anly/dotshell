import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme

Reveal {
    id: root

    implicitHeight: row.implicitHeight

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 12

        Rectangle {
            implicitWidth: 42
            implicitHeight: 42
            radius: 21
            color: Theme.fill
            border.width: 1
            border.color: Theme.line

            DotIcon {
                anchors.centerIn: parent
                name: "sun"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 9

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Label {
                    text: "Bri"
                    color: Theme.fg2
                }

                Label {
                    Layout.fillWidth: true
                    text: "Display"
                    elide: Text.ElideRight
                }
            }

            DotSlider {
                id: slider

                Layout.fillWidth: true
                value: Brightness.percent
                onMoved: value => Brightness.set(value)
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
}
