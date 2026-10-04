import QtQuick
import qs.components
import qs.theme

MorphButton {
    id: root

    property string glyph
    property string text

    implicitWidth: row.implicitWidth + 28
    implicitHeight: 36
    restRadius: 18
    pressRadius: 8
    hoverColor: Qt.rgba(1, 1, 1, 0.1)
    opacity: enabled ? 1 : 0.4

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 8

        DotIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.glyph !== ""
            name: root.glyph
            size: 12
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            pixelSize: 12
        }
    }
}
