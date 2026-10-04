import QtQuick
import qs.components
import qs.theme

Item {
    id: root

    property var row: null

    implicitHeight: note.implicitHeight + 52

    Label {
        id: note

        anchors.centerIn: parent
        width: parent.width - 24
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.row?.text ?? ""
        color: Theme.fg2
    }
}
