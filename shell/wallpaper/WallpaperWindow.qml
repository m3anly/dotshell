import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services
import qs.theme

PanelWindow {
    id: window

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Theme.glassBase
    WlrLayershell.namespace: "dotshell-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    property real veil: Niri.overviewOpen && !GameMode.flatGlass ? 1 : 0

    Behavior on veil {
        enabled: !Motion.reduced

        NumberAnimation {
            duration: Motion.standardMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.effectsCurve
        }
    }

    WallpaperImage {
        id: sharp

        anchors.fill: parent
        source: Wallpaper.source
        transition: Config.wallpaperTransition
        sourceSize: Qt.size(window.width * (window.screen?.devicePixelRatio ?? 1), window.height * (window.screen?.devicePixelRatio ?? 1))
    }

    ShaderEffectSource {
        id: small

        width: Math.ceil(window.width / 4)
        height: Math.ceil(window.height / 4)
        visible: false
        sourceItem: sharp
        textureSize: Qt.size(width, height)
    }

    MultiEffect {
        anchors.fill: parent
        source: small
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 32
        blur: window.veil * window.veil
        opacity: Math.min(1, window.veil * 4)
        visible: window.veil > 0
    }
}
