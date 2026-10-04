import QtQuick
import qs.theme

Item {
    id: root

    property bool vertical: true
    property real dot: 2
    property real pitch: 4
    property color color: Theme.fg3
    readonly property real length: vertical ? height : width
    readonly property int count: Math.max(0, Math.floor((length - dot) / pitch) + 1)
    readonly property real span: Math.max(0, count - 1) * pitch + dot
    readonly property string sprite: {
        const width = vertical ? dot : pitch;
        const height = vertical ? pitch : dot;
        const fill = `rgb(${Math.round(color.r * 255)},${Math.round(color.g * 255)},${Math.round(color.b * 255)})`;
        const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}"><rect width="${dot}" height="${dot}" rx="${dot / 2}" fill="${fill}" fill-opacity="${color.a}"/></svg>`;
        return `data:image/svg+xml,${encodeURIComponent(svg)}`;
    }

    implicitWidth: vertical ? dot : 0
    implicitHeight: vertical ? 0 : dot

    Image {
        visible: root.count > 0
        width: root.vertical ? root.dot : root.span
        height: root.vertical ? root.span : root.dot
        source: root.sprite
        fillMode: root.vertical ? Image.TileVertically : Image.TileHorizontally
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
    }
}
