import QtQuick
import Quickshell

Region {
    property Item target
    property real offset: 0
    property bool active: target?.visible ?? false
    readonly property var tracked: target ? [target.x, target.y, target.width, target.height, target.scale, offset] : []

    item: active ? target : null
    onTrackedChanged: changed()
}
