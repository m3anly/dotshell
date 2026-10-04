import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.services
import qs.theme

PanelWindow {
    id: host

    required property ShellScreen output
    readonly property bool active: Ui.launcherOpen && Ui.screen === output.name

    screen: output
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: active || launcher.visible || scrim.opacity > 0
    mask: active ? null : passThrough
    WlrLayershell.namespace: "dotshell-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    Region {
        id: passThrough
    }

    TrackedRegion {
        id: blurRegion

        target: launcher
        offset: launcher.offset
        radius: 24
    }

    Rectangle {
        id: scrim

        anchors.fill: parent
        color: "black"
        opacity: host.active ? 0.22 : 0

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
            onPressed: Ui.closeAll()
        }
    }

    Launcher {
        id: launcher

        open: host.active
        anchors.horizontalCenter: parent.horizontalCenter
        y: 196
    }
}
