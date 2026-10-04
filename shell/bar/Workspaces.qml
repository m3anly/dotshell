pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.theme

Bay {
    id: bay

    required property string output
    readonly property var workspaces: Niri.workspacesOn(output)
    readonly property int activeIndex: Math.max(0, workspaces.findIndex(ws => ws.is_active))
    readonly property real pitch: 20

    Item {
        implicitWidth: Math.max(0, bay.workspaces.length * bay.pitch - 12)
        implicitHeight: 8

        Repeater {
            model: bay.workspaces.length

            Item {
                id: dot

                readonly property var modelData: bay.workspaces[index] ?? ({})
                required property int index
                readonly property bool active: index === bay.activeIndex
                readonly property bool busy: Niri.occupiedWorkspaceIds[modelData.id] === true
                readonly property bool urgent: modelData.is_urgent === true && !active
                property real heat: active ? 1 : 0

                x: index * bay.pitch
                width: 8
                height: 8
                scale: hover.hovered ? 1.5 : 1

                onActiveChanged: {
                    if (active && !Motion.reduced)
                        pop.restart();
                }

                Behavior on heat {
                    enabled: !Motion.reduced

                    NumberAnimation {
                        duration: dot.active ? 90 : 260
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: dot.active ? Motion.effectsCurve : Motion.exitCurve
                    }
                }
                Behavior on scale {
                    enabled: !Motion.reduced

                    SpatialFast {
                        epsilon: 0.002
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: dot.urgent ? Theme.urgent : dot.busy ? Theme.fg2 : "transparent"
                    border.width: dot.urgent || dot.busy ? 0 : 1
                    border.color: Theme.fg2
                    opacity: 1 - dot.heat
                    scale: 1 - dot.heat * 0.2

                    Behavior on color {
                        EffectsColor {}
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    radius: 8
                    color: Theme.red
                    opacity: 0.22 * dot.heat
                    scale: lit.scale
                }

                Rectangle {
                    id: lit

                    anchors.fill: parent
                    radius: 4
                    color: Theme.red
                    opacity: dot.heat
                }

                SequentialAnimation {
                    id: pop

                    PropertyAction {
                        target: lit
                        property: "scale"
                        value: 0.55
                    }
                    SpatialFast {
                        target: lit
                        property: "scale"
                        to: 1
                        epsilon: 0.002
                    }
                }

                HoverHandler {
                    id: hover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: Niri.focusWorkspace(dot.modelData.idx)
                }
            }
        }
    }

    DisplayText {
        visible: Config.bar.show.workspaceCounter
        text: `${bay.activeIndex + 1}/${bay.workspaces.length}`
        color: Theme.fg2
        font.pixelSize: Theme.labelSize
        Layout.minimumWidth: font.pixelSize * 1.8
    }
}
