pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    readonly property string path: expand(Store.wallpaper || Config.wallpaper)
    readonly property url source: path === "" ? "" : `file://${path.split("/").map(encodeURIComponent).join("/")}`

    function expand(value: string): string {
        if (value.startsWith("~/"))
            return `${Quickshell.env("HOME")}${value.slice(1)}`;
        return value;
    }

    function set(value: string): void {
        Store.wallpaper = value;
    }

    function clear(): void {
        Store.wallpaper = "";
    }
}
