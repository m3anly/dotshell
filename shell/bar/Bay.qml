import QtQuick
import QtQuick.Layouts
import qs.components
import qs.theme

Item {
    id: bay

    property bool interactive: false
    property bool active: false
    property bool dividerLeft: true
    property bool dividerRight: false
    property real spacing: Theme.baySpacing
    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed
    readonly property color foreground: active ? Theme.glassBase : Theme.fg
    default property alias content: row.data

    signal clicked(var mouse)

    implicitWidth: row.implicitWidth + 2 * Theme.bayPadding
    implicitHeight: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        color: bay.active ? Theme.fg : bay.interactive && bay.hovered ? Theme.hover : "transparent"

        Behavior on color {
            EffectsColor {}
        }
    }

    DottedLine {
        visible: bay.dividerLeft
        anchors.left: parent.left
        height: parent.height
    }

    DottedLine {
        visible: bay.dividerRight
        anchors.right: parent.right
        height: parent.height
    }

    RowLayout {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.bayPadding
        anchors.rightMargin: Theme.bayPadding
        spacing: bay.spacing
        scale: bay.interactive && bay.pressed ? 0.86 : 1

        Behavior on scale {
            enabled: !Motion.reduced

            SpatialFast {
                epsilon: 0.002
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        enabled: bay.interactive
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => bay.clicked(event)
    }
}
