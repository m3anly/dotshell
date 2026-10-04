import QtQuick
import qs.components
import qs.theme

Item {
    id: root

    property var row: null
    property bool first: false

    implicitHeight: title.implicitHeight + (first ? 4 : 10) + 6

    Label {
        id: title

        x: 12
        y: root.first ? 4 : 10
        width: parent.width - 24 - aside.implicitWidth
        text: root.row?.title ?? ""
        color: Theme.fg2
        elide: Text.ElideRight
    }

    Label {
        id: aside

        anchors.right: parent.right
        anchors.rightMargin: 12
        y: title.y
        text: root.row?.aside ?? ""
        color: Theme.fg2
    }
}
