import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.theme
import "LauncherLogic.js" as Logic

Selectable {
    id: root

    property bool compact: false
    readonly property var entry: row?.entry ?? null
    readonly property string age: entry && entry.time > 0 ? Logic.ageText(Time.now - entry.time) : ""
    readonly property string sub: compact ? age : [entry?.source ?? "", age].filter(Boolean).join(" · ")

    implicitHeight: Math.max(compact ? 46 : 52, column.implicitHeight + (compact ? 12 : 16))

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: root.compact ? 12 : 14

        LeadBox {
            selected: root.selected
            size: root.compact ? 30 : 36
            restRadius: root.compact ? 9 : 11
            glyph: root.entry?.type ?? ""
            swatch: root.entry?.type === "color" ? root.entry.text.trim() : ""
            image: root.entry?.type === "image" ? root.entry.file : ""
        }

        ColumnLayout {
            id: column

            Layout.fillWidth: true
            spacing: 3

            Body {
                Layout.fillWidth: true
                font.pixelSize: root.compact ? 13 : 14
                text: root.entry?.title ?? ""
            }

            KindLabel {
                Layout.fillWidth: true
                visible: root.sub !== ""
                elide: Text.ElideRight
                text: root.sub
                color: Theme.fg2
            }
        }

        DotIcon {
            visible: root.compact && (root.entry?.pinned ?? false)
            size: 12
            name: "pin"
            color: Theme.red
        }

        KindLabel {
            visible: !root.compact
            text: root.entry?.type ?? ""
        }
    }
}
