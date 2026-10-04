pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    readonly property color fg: "#F2F2F0"
    readonly property color fg2: Qt.rgba(0.949, 0.949, 0.941, 0.55)
    readonly property color fg3: Qt.rgba(0.949, 0.949, 0.941, 0.3)
    readonly property color off: Qt.rgba(1, 1, 1, 0.13)
    readonly property color line: Qt.rgba(1, 1, 1, 0.13)
    readonly property color fill: Qt.rgba(1, 1, 1, 0.06)
    readonly property color hover: Qt.rgba(1, 1, 1, 0.07)
    readonly property color glassBase: Qt.rgba(16 / 255, 16 / 255, 18 / 255, 1)
    readonly property color red: "#D71921"
    readonly property color urgent: Config.urgentColor

    readonly property bool blur: Config.blur && !GameMode.flatGlass
    readonly property real fallbackTint: 1
    readonly property real tintBar: 0.42
    readonly property real tintPanel: 0.62
    readonly property real tintLauncher: 0.66

    function glass(tint: real): color {
        return Qt.rgba(glassBase.r, glassBase.g, glassBase.b, blur ? tint : fallbackTint);
    }

    function css(c: color): string {
        return `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, ${c.a})`;
    }

    readonly property string displayFont: "Doto"
    readonly property string uiFont: "Space Mono"
    readonly property var displayAxes: ({
            "ROND": 100
        })

    readonly property int labelSize: 13
    readonly property real labelTracking: 0.07

    readonly property int barHeight: Math.max(28, Math.min(56, Math.round(Config.bar.height)))
    readonly property bool barAtBottom: Config.bar.position === "bottom"
    readonly property int bayPadding: 16
    readonly property int baySpacing: 10
    readonly property int iconSize: 14
}
