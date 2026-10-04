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

    WallpaperImage {
        anchors.fill: parent
        source: Wallpaper.source
        transition: Config.wallpaperTransition
        sourceSize: Qt.size(window.width * (window.screen?.devicePixelRatio ?? 1), window.height * (window.screen?.devicePixelRatio ?? 1))
    }

    CrossfadeImage {
        id: small

        anchors.fill: parent
        visible: false
        source: Wallpaper.source
        sourceSize: Qt.size(window.width / 4, window.height / 4)
    }

    MultiEffect {
        anchors.fill: parent
        source: small
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 32
        blur: 1
        opacity: Niri.overviewOpen && !GameMode.flatGlass ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            enabled: !Motion.reduced

            NumberAnimation {
                duration: Motion.fastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.effectsCurve
            }
        }
    }
}
