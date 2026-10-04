import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme
import "LauncherLogic.js" as Logic

Selectable {
    id: root

    readonly property var entry: row?.entry ?? null

    implicitHeight: Math.max(52, column.implicitHeight + 16)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 14

        LeadBox {
            selected: root.selected
            monogram: Apps.monogram(root.entry?.name ?? "")
            icon: Apps.iconFor(root.entry)
        }

        ColumnLayout {
            id: column

            Layout.fillWidth: true
            spacing: 3

            Body {
                Layout.fillWidth: true
                font.pixelSize: 14
                textFormat: Text.StyledText
                text: Logic.markMatches(root.entry?.name ?? "", root.row?.indices ?? [], String(Theme.red))
            }

            KindLabel {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.row?.sub ?? ""
                color: Theme.fg2
            }
        }

        KindLabel {
            text: "↵ open"
        }
    }
}
