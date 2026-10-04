pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import qs.components
import qs.services
import qs.theme

WlSessionLockSurface {
    id: surface

    property var controller: null
    property var capture: null
    property bool entered: false
    readonly property bool unlocking: controller?.unlocking ?? false
    readonly property bool hasBackdrop: capture !== null && capture.hasContent
    readonly property int typed: controller?.password.length ?? 0
    readonly property int failures: controller?.failures ?? 0
    readonly property real em: 240

    color: "black"

    onCaptureChanged: adopt()
    onFailuresChanged: {
        if (failures > 0 && !Motion.reduced)
            shake.restart();
    }
    Component.onCompleted: {
        adopt();
        keys.forceActiveFocus();
        entered = true;
    }

    function adopt(): void {
        if (!capture)
            return;
        capture.parent = holder;
        capture.anchors.fill = holder;
        capture.visible = true;
    }

    Item {
        id: holder

        anchors.fill: parent
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        visible: surface.hasBackdrop
        source: holder
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 40
        blur: surface.unlocking ? 0 : 1

        Behavior on blur {
            enabled: !Motion.reduced

            Exit {
                duration: 220
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: surface.hasBackdrop ? Qt.rgba(8 / 255, 8 / 255, 9 / 255, 1) : Theme.glassBase
        opacity: surface.hasBackdrop && surface.unlocking ? 0 : surface.hasBackdrop ? 0.55 : 1

        Behavior on opacity {
            enabled: !Motion.reduced

            Exit {
                duration: 220
            }
        }
    }

    Item {
        id: keys

        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            const control = surface.controller;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                control.submit();
            else if (event.key === Qt.Key_Backspace && (event.modifiers & Qt.ControlModifier))
                control.clear();
            else if (event.key === Qt.Key_Backspace)
                control.erase();
            else if (event.key === Qt.Key_Escape)
                control.clear();
            else if (event.text.length > 0 && event.text.charCodeAt(0) >= 32)
                control.type(event.text);
            else {
                event.accepted = false;
                return;
            }
            event.accepted = true;
        }
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

            Row {
                id: clock

                anchors.horizontalCenter: parent.horizontalCenter
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

                DisplayText {
                    id: hours

                    text: Time.hhmm.slice(0, 2)
                    font.pixelSize: surface.em
                    font.weight: 600
                }

                Item {
                    readonly property real digitCenter: 0.35

                    width: surface.em * (0.105 + 0.11 + 0.165)
                    height: hours.height

                    Column {
                        x: surface.em * 0.105
                        y: hours.baselineOffset - surface.em * parent.digitCenter - height / 2 + surface.em * 0.005
                        spacing: surface.em * 0.19

                        Repeater {
                            model: 2

                            Rectangle {
                                width: surface.em * 0.11
                                height: width
                                radius: width / 2
                                color: Theme.red
                                antialiasing: true
                            }
                        }
                    }
                }

                DisplayText {
                    text: Time.hhmm.slice(2, 4)
                    font.pixelSize: surface.em
                    font.weight: 600
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Time.hour12 ? `${Time.dayLabel} · ${Time.period}` : Time.dayLabel
                color: Theme.fg2
                tracking: 0.2
            }

            Item {
                id: dots

                readonly property int pitch: 22
                readonly property int size: 10
                readonly property bool template: surface.typed === 0
                readonly property int capacity: Math.max(6, Math.floor((surface.width - 96) / pitch))
                readonly property int count: template ? 6 : Math.min(surface.typed, capacity)

                anchors.horizontalCenter: parent.horizontalCenter
                width: count * pitch - (pitch - size)
                height: size
                transform: Translate {
                    id: shakeOffset
                }

                Behavior on width {
                    enabled: !Motion.reduced

                    SpatialStandard {}
                }

                Repeater {
                    model: Math.max(6, dots.count)

                    Rectangle {
                        required property int index
                        property bool born: false
                        readonly property bool present: born && index < dots.count
                        readonly property bool filled: present && !dots.template

                        x: index * dots.pitch
                        width: dots.size
                        height: dots.size
                        radius: dots.size / 2
                        color: filled ? Theme.fg : "transparent"
                        border.width: 1
                        border.color: surface.failures > 0 && dots.template ? Theme.red : Theme.fg2
                        opacity: present ? 1 : 0
                        scale: !present ? 0.3 : filled ? 1.15 : 1
                        antialiasing: true
                        Component.onCompleted: born = true

                        Behavior on color {
                            EffectsColor {}
                        }
                        Behavior on border.color {
                            EffectsColor {}
                        }
                        Behavior on opacity {
                            Effects {}
                        }
                        Behavior on scale {
                            enabled: !Motion.reduced

                            SpatialFast {
                                epsilon: 0.002
                            }
                        }
                    }
                }

                SequentialAnimation {
                    id: shake

                    PropertyAction {
                        target: shakeOffset
                        property: "x"
                        value: 18
                    }
                    SpatialFast {
                        target: shakeOffset
                        property: "x"
                        to: 0
                    }
                }
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
