import QtQuick
import Quickshell
import qs.components
import qs.theme

PopupWindow {
    id: popup

    required property Item target
    property string text
    property bool shown: false
    property bool above: Theme.barAtBottom

    anchor.item: target
    anchor.rect.x: 0
    anchor.rect.y: above ? -16 : target.height + 16
    anchor.rect.width: target.width
    anchor.rect.height: 1
    anchor.edges: above ? Edges.Top : Edges.Bottom
    anchor.gravity: above ? Edges.Top : Edges.Bottom
    implicitWidth: bubble.implicitWidth + 12
    implicitHeight: bubble.implicitHeight + 12
    color: "transparent"
    visible: (shown && text !== "") || bubble.opacity > 0

    Rectangle {
        id: bubble

        anchors.horizontalCenter: parent.horizontalCenter
        y: popup.shown ? 0 : popup.above ? 6 : -6
        implicitWidth: label.implicitWidth + 18
        implicitHeight: label.implicitHeight + 10
        radius: 4
        color: Theme.fg
        opacity: popup.shown ? 1 : 0
        scale: popup.shown ? 1 : 0.8

        Behavior on opacity {
            Effects {}
        }
        Behavior on y {
            enabled: !Motion.reduced

            SpatialStandard {}
        }
        Behavior on scale {
            enabled: !Motion.reduced

            SpatialStandard {
                epsilon: 0.002
            }
        }

        Label {
            id: label

            anchors.centerIn: parent
            text: popup.text
            color: Theme.glassBase
            pixelSize: 12
            tracking: 0.06
        }
    }
}
