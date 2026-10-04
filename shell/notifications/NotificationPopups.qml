pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.theme

PanelWindow {
    id: host

    required property ShellScreen output
    readonly property bool atBottom: Config.notifications.position.startsWith("bottom")
    readonly property bool atLeft: Config.notifications.position.endsWith("left")
    readonly property bool besidePanels: atBottom === Theme.barAtBottom
    readonly property bool covered: besidePanels && Ui.screen === output.name && (atLeft ? Ui.panel === "system" : Ui.panel === "quickSettings" || Ui.panel === "notifications")
    readonly property real side: atLeft ? -1 : 1
    readonly property bool active: Notifications.shownPopups.length > 0 && Notifications.screen === output.name && !covered

    screen: output
    anchors {
        top: true
        bottom: true
        left: atLeft
        right: !atLeft
    }
    implicitWidth: 386
    exclusiveZone: 0
    color: "transparent"
    visible: active || stack.visible
    mask: active ? stackRegion : passThrough
    WlrLayershell.namespace: "dotshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    Region {
        id: passThrough
    }

    TrackedRegion {
        id: stackRegion

        target: stack
        offset: stack.offset
    }

    TrackedRegion {
        id: blurRegion

        target: stack
        offset: stack.offset
        radius: stack.radius
    }

    Rectangle {
        id: stack

        property real targetHeight: list.contentHeight + 12

        anchors.left: host.atLeft ? parent.left : undefined
        anchors.right: host.atLeft ? undefined : parent.right
        anchors.top: host.atBottom ? undefined : parent.top
        anchors.bottom: host.atBottom ? parent.bottom : undefined
        anchors.margins: 6
        width: 380
        height: Math.max(Math.min(targetHeight, host.height - 12), 1)
        radius: 18
        color: Theme.glass(Theme.tintPanel)
        border.width: 1
        border.color: Theme.line
        antialiasing: true
        clip: true
        visible: opacity > 0
        opacity: 0
        scale: 0.9
        transformOrigin: host.atBottom ? (host.atLeft ? Item.BottomLeft : Item.BottomRight) : (host.atLeft ? Item.TopLeft : Item.TopRight)
        readonly property alias offset: shift.y

        transform: Translate {
            id: shift

            y: host.atBottom ? 10 : -10
        }

        Behavior on targetHeight {
            enabled: !Motion.reduced && host.active

            SpatialStandard {}
        }

        states: State {
            name: "open"
            when: host.active

            PropertyChanges {
                stack.opacity: 1
                stack.scale: 1
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

        ListView {
            id: list

            anchors.fill: parent
            anchors.margins: 6
            interactive: false
            onCountChanged: positionViewAtBeginning()
            model: ScriptModel {
                comparisonMode: ObjectComparison.Identity
                values: Notifications.shownPopups
            }

            delegate: Item {
                id: slot

                required property Notification modelData
                required property int index
                readonly property real timeout: {
                    const config = Config.notifications;
                    if (modelData?.urgency === NotificationUrgency.Critical)
                        return Math.max(0, config.criticalTimeout) * 1000;
                    const seconds = modelData?.expireTimeout ?? 0;
                    if (config.respectAppTimeout && seconds > 0)
                        return Math.max(3000, seconds * 1000);
                    return Math.max(1, config.timeout) * 1000;
                }

                width: list.width
                height: card.implicitHeight + (index > 0 ? 6 : 0)

                DottedLine {
                    visible: slot.index > 0
                    vertical: false
                    x: 12
                    width: parent.width - 24
                }

                NotificationCard {
                    id: card

                    y: slot.index > 0 ? 6 : 0
                    width: parent.width
                    notification: slot.modelData
                    bodyLines: 3
                }

                Timer {
                    interval: slot.timeout
                    running: slot.timeout > 0 && host.active && !card.hovered
                    onTriggered: Notifications.dropPopup(slot.modelData)
                }
            }

            add: Transition {
                enabled: !Motion.reduced

                SequentialAnimation {
                    PropertyAction {
                        property: "opacity"
                        value: 0
                    }
                    PropertyAction {
                        property: "x"
                        value: 40 * host.side
                    }
                    ParallelAnimation {
                        Effects {
                            property: "opacity"
                            to: 1
                        }
                        SpatialStandard {
                            property: "x"
                            to: 0
                        }
                    }
                }
            }

            remove: Transition {
                enabled: !Motion.reduced

                ParallelAnimation {
                    Exit {
                        property: "opacity"
                        to: 0
                        duration: 160
                    }
                    Exit {
                        property: "x"
                        to: 60 * host.side
                        duration: 200
                    }
                }
            }

            displaced: Transition {
                enabled: !Motion.reduced

                SpatialStandard {
                    property: "y"
                }
                Effects {
                    properties: "opacity"
                    to: 1
                }
                SpatialStandard {
                    property: "x"
                    to: 0
                }
            }
        }
    }
}
