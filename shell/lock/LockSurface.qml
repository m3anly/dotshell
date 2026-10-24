pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland
import qs.components
import qs.services
import qs.theme

WlSessionLockSurface {
    id: surface

    property var controller: null
    readonly property var capture: controller?.captureFor(screen) ?? null
    property bool entered: false
    readonly property bool unlocking: controller?.unlocking ?? false
    readonly property int typed: controller?.password.length ?? 0
    readonly property int failures: controller?.failures ?? 0
    readonly property real em: 240

    color: "black"

    Component.onCompleted: {
        keys.forceActiveFocus();
        entered = true;
    }

    LockBackdrop {
        anchors.fill: parent
        capture: surface.capture
        unlocking: surface.unlocking
    }

    Item {
        id: keys

        anchors.fill: parent
        focus: true
        Keys.onPressed: event => event.accepted = surface.controller.key(event)
    }

    Item {
        anchors.fill: parent
        opacity: surface.unlocking || !surface.entered ? 0 : 1

        Behavior on opacity {
            enabled: !Motion.reduced

            NumberAnimation {
                duration: surface.unlocking ? 220 : Motion.effectsMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: surface.unlocking ? Motion.exitCurve : Motion.effectsCurve
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 26

            LockClock {
                id: clock

                anchors.horizontalCenter: parent.horizontalCenter
                em: surface.em
                scale: surface.entered ? 1 : 0.92
                transform: Translate {
                    y: surface.entered ? 0 : 40

                    Behavior on y {
                        enabled: !Motion.reduced

                        SpatialSlow {}
                    }
                }

                Behavior on scale {
                    enabled: !Motion.reduced

                    SpatialSlow {
                        epsilon: 0.002
                    }
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Time.hour12 ? `${Time.dayLabel} · ${Time.period}` : Time.dayLabel
                color: Theme.fg2
                tracking: 0.2
            }

            PasswordDots {
                anchors.horizontalCenter: parent.horizontalCenter
                typed: surface.typed
                failures: surface.failures
                maxWidth: surface.width - 96
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (surface.controller?.busy)
                        return "Checking";
                    if (surface.failures > 0 && surface.typed === 0)
                        return Niri.layoutIndex > 0 ? `Wrong password · layout ${Niri.layoutShort}` : "Wrong password";
                    return "Type password to unlock";
                }
                color: surface.failures > 0 && surface.typed === 0 ? Theme.red : Theme.fg2
                tracking: 0.2
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                MorphButton {
                    id: layoutChip

                    property int previousIndex: Niri.layoutIndex
                    readonly property bool alternate: Niri.layoutIndex > 0

                    visible: Niri.layoutNames.length > 1
                    implicitWidth: layoutRow.implicitWidth + 28
                    implicitHeight: 32
                    restRadius: 16
                    pressRadius: 8
                    pressScale: 0.92
                    restColor: alternate ? Theme.fg : Theme.fill
                    hoverColor: alternate ? Theme.fg : Theme.hover
                    outline: alternate ? "transparent" : Theme.line
                    onClicked: Niri.nextLayout()

                    Row {
                        id: layoutRow

                        anchors.centerIn: parent
                        spacing: 10

                        DotIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 14
                            name: "keyboard"
                            color: layoutChip.alternate ? Theme.glassBase : Theme.fg2
                        }

                        RollText {
                            id: layoutLabel

                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideNone
                            color: layoutChip.alternate ? Theme.glassBase : Theme.fg
                            Component.onCompleted: text = Niri.layoutShort
                        }
                    }

                    Connections {
                        target: Niri

                        function onLayoutShortChanged(): void {
                            layoutLabel.direction = Niri.layoutIndex >= layoutChip.previousIndex ? 1 : -1;
                            layoutChip.previousIndex = Niri.layoutIndex;
                            layoutLabel.text = Niri.layoutShort;
                        }
                    }
                }

                Rectangle {
                    visible: Locks.caps
                    implicitWidth: capsRow.implicitWidth + 28
                    implicitHeight: 32
                    radius: 16
                    color: Theme.fill
                    border.width: 1
                    border.color: Theme.line
                    antialiasing: true

                    Row {
                        id: capsRow

                        anchors.centerIn: parent
                        spacing: 10

                        DotIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            size: 14
                            name: "caps"
                            color: Theme.red
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Caps lock"
                            color: Theme.fg
                        }
                    }
                }
            }
        }
    }
}
