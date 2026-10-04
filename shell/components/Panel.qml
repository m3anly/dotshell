import QtQuick
import QtQuick.Layouts
import qs.theme

Rectangle {
    id: root

    property bool open: false
    property bool fromRight: false
    default property alias content: column.data

    width: 460
    height: column.implicitHeight + 28
    radius: 18
    color: Theme.glass(Theme.tintPanel)
    border.width: 1
    border.color: Theme.line
    antialiasing: true
    visible: opacity > 0
    opacity: 0
    scale: 0.9
    transformOrigin: Theme.barAtBottom ? (fromRight ? Item.BottomRight : Item.BottomLeft) : (fromRight ? Item.TopRight : Item.TopLeft)
    readonly property alias offset: shift.y

    transform: Translate {
        id: shift

        y: Theme.barAtBottom ? 10 : -10
    }

    states: State {
        name: "open"
        when: root.open

        PropertyChanges {
            root.opacity: 1
            root.scale: 1
            shift.y: 0
        }
    }

    transitions: [
        Transition {
            to: "open"
            enabled: !Motion.reduced

            ParallelAnimation {
                Effects {
                    property: "opacity"
                }
                SpatialStandard {
                    property: "scale"
                    epsilon: 0.002
                }
                SpatialStandard {
                    target: shift
                    property: "y"
                }
            }
        },
        Transition {
            from: "open"
            enabled: !Motion.reduced

            ParallelAnimation {
                Exit {
                    property: "opacity"
                    duration: 150
                }
                Exit {
                    properties: "scale,y"
                    duration: 200
                }
            }
        }
    ]

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
    }

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: 14
        spacing: 12
    }
}
