pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.components
import qs.services
import qs.theme

Item {
    id: root

    readonly property real artRadius: width * 0.27
    readonly property real progressRadius: artRadius + 9
    readonly property int progressDots: 72
    readonly property real pitch: 7
    readonly property real matrixInner: progressRadius + 9
    readonly property real matrixOuter: width / 2 - 3
    readonly property var cells: {
        const list = [];
        const reach = Math.ceil(matrixOuter / pitch);
        for (let row = -reach; row <= reach; row++) {
            for (let column = -reach; column <= reach; column++) {
                const x = column * pitch;
                const y = row * pitch;
                const radius = Math.hypot(x, y);
                if (radius < matrixInner || radius > matrixOuter)
                    continue;
                list.push({
                    x: x,
                    y: y,
                    band: Math.abs(Math.atan2(x, -y)) / Math.PI * (Spectrum.bands - 1),
                    depth: (radius - matrixInner) / (matrixOuter - matrixInner)
                });
            }
        }
        return list;
    }
    readonly property real progress: Media.length > 0 ? Math.max(0, Math.min(1, Media.position / Media.length)) : -1
    readonly property bool hovered: hover.hovered
    property var shown: []

    implicitWidth: 236
    implicitHeight: implicitWidth

    onProgressChanged: dots.requestPaint()
    onCellsChanged: dots.requestPaint()

    function levelAt(band: real): real {
        const low = Math.floor(band);
        const high = Math.min(Spectrum.bands - 1, low + 1);
        const mix = band - low;
        return (shown[low] ?? 0) * (1 - mix) + (shown[high] ?? 0) * mix;
    }

    HoverHandler {
        id: hover
    }

    FrameAnimation {
        running: root.visible && (Spectrum.levels.length > 0 || root.shown.some(value => value > 0.002))
        onTriggered: {
            const blend = 1 - Math.exp(-frameTime * 22);
            const next = [];
            for (let i = 0; i < Spectrum.bands; i++) {
                const value = root.shown[i] ?? 0;
                const target = Spectrum.levels[i] ?? 0;
                const moved = value + (target - value) * blend;
                next.push(moved < 0.002 && target === 0 ? 0 : moved);
            }
            root.shown = next;
            dots.requestPaint();
        }
    }

    Canvas {
        id: dots

        anchors.fill: parent
        renderStrategy: Canvas.Threaded

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2;
            const cy = height / 2;
            const batches = {};
            const put = (style, x, y, r) => {
                (batches[style] = batches[style] ?? []).push(x, y, r);
            };
            const lit = alpha => Theme.css(Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, Math.round(alpha * 10) / 10));
            const off = Theme.css(Theme.off);
            const current = root.progress < 0 ? -1 : Math.min(root.progressDots - 1, Math.floor(root.progress * root.progressDots));
            for (let i = 0; i < root.progressDots; i++) {
                const angle = -Math.PI / 2 + (i + 0.5) * Math.PI * 2 / root.progressDots;
                const x = cx + Math.cos(angle) * root.progressRadius;
                const y = cy + Math.sin(angle) * root.progressRadius;
                if (i === current)
                    put(Theme.css(Theme.red), x, y, 2.4);
                else
                    put(i < current ? lit(0.45) : off, x, y, 1.4);
            }
            const edge = root.pitch / (root.matrixOuter - root.matrixInner);
            for (const cell of root.cells) {
                const level = root.levelAt(cell.band);
                const fill = level <= 0.01 ? 0 : Math.max(0, Math.min(1, (level - cell.depth) / edge + 1));
                put(fill > 0.05 ? lit(fill * (1 - cell.depth * 0.45)) : off, cx + cell.x, cy + cell.y, 2.1);
            }
            for (const style in batches) {
                const list = batches[style];
                ctx.fillStyle = style;
                ctx.beginPath();
                for (let j = 0; j < list.length; j += 3) {
                    ctx.moveTo(list[j] + list[j + 2], list[j + 1]);
                    ctx.arc(list[j], list[j + 1], list[j + 2], 0, Math.PI * 2);
                }
                ctx.fill();
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: root.artRadius * 2
        height: width
        radius: width / 2
        color: Theme.fill
        border.width: 1
        border.color: Theme.line
        antialiasing: true

        DotIcon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            name: "note"
            size: 28
            color: Theme.fg3
        }

        ClippingRectangle {
            anchors.fill: parent
            visible: art.status === Image.Ready
            radius: width / 2
            color: "transparent"

            Image {
                id: art

                anchors.fill: parent
                visible: false
                source: Media.artUrl
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            MultiEffect {
                anchors.fill: parent
                source: art
                saturation: root.hovered ? 0 : -1

                Behavior on saturation {
                    Effects {
                        duration: 320
                    }
                }
            }
        }
    }
}
