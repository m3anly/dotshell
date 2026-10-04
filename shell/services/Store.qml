pragma ComponentBehavior: Bound

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    component ClockState: JsonObject {
        property real right: -1
        property real bottom: -1
        property real x: -1
        property real y: -1
        property string mode: "time"
    }

    component NotificationState: JsonObject {
        property bool doNotDisturb: false
    }

    readonly property string directory: (Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`) + "/dotshell"
    property alias appUsage: adapter.appUsage
    property alias clock: adapter.clock
    property alias notifications: adapter.notifications
    property alias wallpaper: adapter.wallpaper
    property alias weather: adapter.weather
    property bool fresh: false
    readonly property bool ready: file.loaded || fresh

    FileView {
        id: file

        path: `${root.directory}/state.json`
        atomicWrites: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                return;
            root.fresh = true;
            writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property var appUsage: ({})
            property ClockState clock: ClockState {}
            property NotificationState notifications: NotificationState {}
            property string wallpaper: ""
            property var weather: ({})
        }
    }
}
