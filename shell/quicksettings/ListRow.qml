import QtQuick
import QtQuick.Layouts
import qs.components
import qs.theme

MorphButton {
    id: root

    property bool current: false
    property string name
    property string status
    property bool busy: false
    property bool showExtra: false
    property color statusColor: current ? Theme.fg : Theme.fg2
    property real extraOpenness: showExtra ? 1 : 0
    property alias lead: leadSlot.data
    property alias extra: extraSlot.data

    readonly property color currentFill: Qt.rgba(1, 1, 1, 0.09)

    implicitHeight: Math.max(50, column.implicitHeight + 16)
    restRadius: 10
    pressRadius: 18
    pressScale: 0.97
    restColor: current ? currentFill : "transparent"
    hoverColor: current ? currentFill : Theme.hover
    outline: "transparent"

    Behavior on extraOpenness {
        enabled: !Motion.reduced

        NumberAnimation {
            duration: root.showExtra ? Motion.expandMs : 220
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.showExtra ? Motion.expandCurve : Motion.exitCurve
        }
    }

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                id: leadSlot

                implicitWidth: 16
                implicitHeight: 16
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Body {
                    Layout.fillWidth: true
                    text: root.name
                }

                Row {
                    spacing: 6

                    Label {
                        text: root.status
                        pixelSize: 11
                        tracking: 0.06
                        color: root.statusColor
                    }

                    LoadingDots {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.busy
                        dot: 3
                        color: Theme.red
                    }
                }
            }

            Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: root.current ? Theme.red : "transparent"
                border.width: root.current ? 0 : 1
                border.color: Theme.fg3
                scale: root.current ? 1.2 : 1

                Behavior on color {
                    EffectsColor {}
                }
                Behavior on scale {
                    enabled: !Motion.reduced

                    SpatialFast {
                        epsilon: 0.002
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round((extraSlot.childrenRect.height + 10) * root.extraOpenness)
            visible: root.extraOpenness > 0
            opacity: root.extraOpenness
            clip: true

            Item {
                id: extraSlot

                y: 10
                width: parent.width
                height: childrenRect.height
            }
        }
    }
}
