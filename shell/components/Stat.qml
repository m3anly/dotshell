import QtQuick
import qs.components
import qs.theme

Rectangle {
    id: root

    property string heading
    property string value

    implicitHeight: 58
    radius: 14
    color: Theme.fill
    border.width: 1
    border.color: Theme.line
    antialiasing: true

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Label {
            width: parent.width
            text: root.heading
            pixelSize: 10
            color: Theme.fg2
        }

        Body {
            width: parent.width
            text: root.value
            font.pixelSize: 15
        }
    }
}
