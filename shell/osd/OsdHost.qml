import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.theme

PanelWindow {
    id: host

    required property ShellScreen output
    readonly property bool active: Osd.shown && Osd.screen === output.name
    readonly property bool atTop: Config.osd.position === "top"
    readonly property real margin: 28 + (atTop !== Theme.barAtBottom ? Theme.barHeight : 0)

    screen: output
    anchors.top: atTop
    anchors.bottom: !atTop
    implicitWidth: 440
    implicitHeight: pill.height + host.margin + 36
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: active || pill.visible
    mask: active ? pillRegion : passThrough
    WlrLayershell.namespace: "dotshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Theme.blur ? blurRegion : null

    Region {
        id: passThrough
    }

    TrackedRegion {
        id: pillRegion

        target: pill
        offset: pill.offset
        radius: pill.radius
    }

    TrackedRegion {
        id: blurRegion

        target: pill
        offset: pill.offset
        radius: pill.radius
    }

    OsdPill {
        id: pill

        open: host.active
        fromTop: host.atTop
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: host.atTop ? parent.top : undefined
        anchors.bottom: host.atTop ? undefined : parent.bottom
        anchors.margins: host.margin
    }
}
