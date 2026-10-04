import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import qs.theme

PanelWindow {
    id: host

    required property ShellScreen output
    readonly property bool active: Polkit.active && Polkit.screen === output.name

    screen: output
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: active || dialog.visible || scrim.opacity > 0
    mask: active ? null : passThrough
    WlrLayershell.namespace: "dotshell-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    Region {
        id: passThrough
    }

    TrackedRegion {
        id: blurRegion

        target: dialog
        offset: dialog.offset
        radius: 24
    }

    Rectangle {
        id: scrim

        anchors.fill: parent
        color: "black"
        opacity: host.active ? 0.32 : 0

        Behavior on opacity {
            enabled: !Motion.reduced

            NumberAnimation {
                duration: host.active ? Motion.effectsMs : 150
                easing.type: Easing.BezierSpline
                easing.bezierCurve: host.active ? Motion.effectsCurve : Motion.exitCurve
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: host.active
            acceptedButtons: Qt.AllButtons
        }
    }

    PolkitDialog {
        id: dialog

        open: host.active
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.42 - height / 2)
    }
}
