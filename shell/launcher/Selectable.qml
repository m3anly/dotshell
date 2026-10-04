import QtQuick

Item {
    id: root

    property var row: null
    property bool selected: false
    property Item highlight
    property real originY: 0

    signal pointed(point scenePoint)
    signal activated(bool shift)

    Binding {
        target: root.highlight
        property: "goal"
        when: root.selected && root.highlight !== null
        restoreMode: Binding.RestoreNone
        value: ({
                x: 0,
                y: root.originY,
                width: root.width,
                height: root.height,
                radius: 12
            })
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: event => root.pointed(mapToItem(null, event.x, event.y))
        onClicked: event => root.activated((event.modifiers & Qt.ShiftModifier) !== 0)
    }
}
