import QtQuick
import QtQuick.Layouts
import qs.components
import qs.theme
import "../components/Glyphs.js" as Glyphs

Selectable {
    id: root

    readonly property string value: root.row?.calculation?.value ?? ""
    readonly property string symbol: value !== "" && Glyphs.displayGlyph(value[0]) !== null ? value[0] : ""

    implicitHeight: Math.max(104, column.implicitHeight + 16)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 12
        spacing: 20

        DisplayGlyph {
            character: root.row?.calculation?.approximate ? "≈" : "="
            pixelSize: 40
            color: Theme.red
        }

        ColumnLayout {
            id: column

            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                DisplayGlyph {
                    visible: root.symbol !== ""
                    character: root.symbol
                    pixelSize: 54
                }

                RollText {
                    Layout.fillWidth: true
                    display: true
                    pixelSize: 54
                    text: root.value.slice(root.symbol.length)
                }
            }

            Body {
                Layout.fillWidth: true
                text: root.row?.calculation?.pretty ?? ""
                color: Theme.fg2
                font.letterSpacing: 13 * 0.02
            }
        }

        KindLabel {
            text: "↵ copy"
        }
    }
}
