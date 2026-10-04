pragma ComponentBehavior: Bound

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.components
import qs.services
import qs.theme

Item {
    id: root

    property string folder
    property int columns: 3
    property int rows: 0
    property int page: 0
    readonly property real gap: 10
    readonly property real tileWidth: (width - (columns - 1) * gap) / columns
    readonly property real tileHeight: Math.round(tileWidth * 9 / 16)
    readonly property int count: images.count
    readonly property int perPage: rows > 0 ? columns * rows : Math.max(1, count)
    readonly property int pages: Math.max(1, Math.ceil(count / perPage))
    readonly property int shownRows: Math.ceil(Math.min(count, perPage) / columns)
    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || `${Quickshell.env("HOME")}/.cache`}/dotshell/thumbnails`

    function fileUrl(path: string): url {
        return `file://${path.split("/").map(encodeURIComponent).join("/")}`;
    }

    implicitHeight: count === 0 ? empty.implicitHeight : shownRows * tileHeight + Math.max(0, shownRows - 1) * gap
    clip: rows > 0
    onPagesChanged: page = Math.min(page, pages - 1)
    onCountChanged: {
        if (rows === 0 || count === 0 || page !== 0)
            return;
        const index = images.indexOf(fileUrl(Wallpaper.path));
        if (index >= 0)
            page = Math.floor(index / perPage);
    }

    function step(delta: int): void {
        page = Math.max(0, Math.min(pages - 1, page + delta));
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.cache]
    }

    FolderListModel {
        id: images

        folder: root.folder === "" ? "" : `file://${root.folder}`
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp", "*.JPG", "*.JPEG", "*.PNG"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    Body {
        id: empty

        width: parent.width
        visible: root.count === 0
        topPadding: 18
        bottomPadding: 18
        horizontalAlignment: Text.AlignHCenter
        text: "No images in this folder"
        color: Theme.fg2
    }

    Item {
        id: strip

        width: root.width
        height: root.height
        x: -root.page * (root.width + root.gap)

        Behavior on x {
            enabled: !Motion.reduced

            SpatialStandard {}
        }

        Repeater {
            model: images

            Item {
                id: tile

                required property string filePath
                required property date fileModified
                readonly property string thumbnail: `${root.cache}/${Qt.md5(`${filePath}:${fileModified.getTime()}`)}.png`
                property bool original: false
                required property int index
                readonly property bool current: filePath === Wallpaper.path
                readonly property bool hovered: mouse.containsMouse

                readonly property int slot: index % root.perPage

                x: Math.floor(index / root.perPage) * (root.width + root.gap) + slot % root.columns * (root.tileWidth + root.gap)
                y: Math.floor(slot / root.columns) * (root.tileHeight + root.gap)
                width: root.tileWidth
                height: root.tileHeight
                scale: mouse.pressed ? 0.95 : 1

                Behavior on scale {
                    enabled: !Motion.reduced

                    SpatialFast {
                        epsilon: 0.002
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: picture.radius
                    color: Theme.fill
                    antialiasing: true
                }

                RoundedImage {
                    id: picture

                    anchors.fill: parent
                    radius: tile.hovered || tile.current ? 18 : 12
                    source: root.fileUrl(tile.original ? tile.filePath : tile.thumbnail)
                    sourceSize: tile.original ? Qt.size(480, 270) : Qt.size(0, 0)
                    asynchronous: true
                    cache: true
                    opacity: status === Image.Ready ? 1 : 0
                    onStatusChanged: {
                        if (status === Image.Error && !tile.original)
                            tile.original = true;
                        else if (status === Image.Ready && tile.original)
                            capture.restart();
                    }

                    Behavior on radius {
                        enabled: !Motion.reduced

                        SpatialStandard {}
                    }
                    Behavior on opacity {
                        Effects {}
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: picture.radius
                    color: "transparent"
                    border.width: tile.current ? 2 : 1
                    border.color: tile.current ? Theme.fg : Theme.line
                    antialiasing: true

                    Behavior on border.color {
                        EffectsColor {}
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    width: 8
                    height: 8
                    radius: 4
                    color: Theme.red
                    scale: tile.current ? 1 : 0

                    Behavior on scale {
                        enabled: !Motion.reduced

                        SpatialFast {
                            epsilon: 0.002
                        }
                    }
                }

                Timer {
                    id: capture

                    interval: 400
                    onTriggered: {
                        if (picture.status !== Image.Ready || picture.image.implicitWidth <= 0)
                            return;
                        picture.image.grabToImage(result => result.saveToFile(tile.thumbnail), Qt.size(picture.image.implicitWidth, picture.image.implicitHeight));
                    }
                }

                MouseArea {
                    id: mouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Wallpaper.set(tile.filePath)
                }
            }
        }
    }
}
