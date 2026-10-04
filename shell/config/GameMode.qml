pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property bool active: Config.gameMode.enabled
    readonly property bool pinned: Config.isPinned("gameMode.enabled")
    readonly property bool stillMotion: active && Config.gameMode.animations
    readonly property bool flatGlass: active && Config.gameMode.blur
    readonly property bool hideWidgets: active && Config.gameMode.widgets
    readonly property bool muteVisualizer: active && Config.gameMode.visualizer

    function setActive(on: bool): void {
        Config.set("gameMode.enabled", on);
    }

    function toggle(): void {
        setActive(!active);
    }
}
