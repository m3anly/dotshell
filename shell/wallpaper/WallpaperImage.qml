pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.theme

Item {
    id: root

    property url source
    property size sourceSize
    property string transition: "fade"
    property int front: 0
    property int incoming: -1
    property real progress: 0
    readonly property bool masked: ["wipe", "circle", "dots"].includes(transition)

    function begin(index: int): void {
        reveal.stop();
        incoming = index;
        progress = 0;
        if (Motion.reduced) {
            finish();
            return;
        }
        reveal.duration = masked ? 1100 : 480;
        reveal.start();
    }

    function finish(): void {
        if (incoming >= 0)
            front = incoming;
        incoming = -1;
        progress = 0;
    }

    onSourceChanged: {
        if (incoming >= 0) {
            reveal.stop();
            finish();
        }
        const back = images.itemAt(1 - front) as Image;
        if (!back)
            return;
        back.source = source;
        if (source.toString() === "")
            front = 1 - front;
        else if (back.status === Image.Ready)
            begin(1 - front);
    }

    NumberAnimation {
        id: reveal

        target: root
        property: "progress"
        from: 0
        to: 1
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Motion.effectsCurve
        onFinished: root.finish()
    }

    Repeater {
        id: images

        model: 2

        Image {
            required property int index

            anchors.fill: parent
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectCrop
            sourceSize: root.sourceSize
            visible: root.front === index || (root.incoming === index && !root.masked)
            opacity: root.incoming === index ? root.progress : 1
            z: root.incoming === index ? 1 : 0
            Component.onCompleted: {
                if (index === root.front)
                    source = root.source;
            }
            onStatusChanged: {
                if (status === Image.Ready && root.front !== index && root.incoming !== index && source === root.source)
                    root.begin(index);
            }
        }
    }

    Loader {
        id: mask

        anchors.fill: parent
        active: root.masked && root.incoming >= 0

        sourceComponent: Canvas {
            readonly property string kind: root.transition

            visible: false
            layer.enabled: true
            onKindChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            function shade(key: real): color {
                return Qt.rgba(1, 1, 1, 0.95 - 0.9 * Math.max(0, Math.min(1, key)));
            }

            onPaint: {
                const context = getContext("2d");
                context.reset();
                if (width <= 0 || height <= 0)
                    return;
                const centerX = width / 2;
                const centerY = height / 2;
                const far = Math.hypot(centerX, centerY);
                if (kind === "wipe") {
                    const gradient = context.createLinearGradient(0, 0, width, 0);
                    gradient.addColorStop(0, shade(0));
                    gradient.addColorStop(1, shade(1));
                    context.fillStyle = gradient;
                    context.fillRect(0, 0, width, height);
                } else if (kind === "circle") {
                    const gradient = context.createRadialGradient(centerX, centerY, 0, centerX, centerY, far);
                    gradient.addColorStop(0, shade(0));
                    gradient.addColorStop(1, shade(1));
                    context.fillStyle = gradient;
                    context.fillRect(0, 0, width, height);
                } else {
                    const cell = 32;
                    const columns = Math.ceil(width / cell);
                    const rows = Math.ceil(height / cell);
                    const left = (width - columns * cell) / 2;
                    const top = (height - rows * cell) / 2;
                    const radius = cell * Math.SQRT1_2;
                    for (let row = 0; row < rows; row++) {
                        for (let column = 0; column < columns; column++) {
                            const x = left + (column + 0.5) * cell;
                            const y = top + (row + 0.5) * cell;
                            const order = Math.hypot(x - centerX, y - centerY) / far * 0.8 + Math.random() * 0.2;
                            const gradient = context.createRadialGradient(x, y, 0, x, y, radius);
                            gradient.addColorStop(0, shade(order * 0.6));
                            gradient.addColorStop(1, shade(order * 0.6 + 0.4));
                            context.fillStyle = gradient;
                            context.fillRect(x - cell / 2, y - cell / 2, cell, cell);
                        }
                    }
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        z: 2
        active: mask.status === Loader.Ready

        sourceComponent: MultiEffect {
            source: images.itemAt(root.incoming)
            autoPaddingEnabled: false
            maskEnabled: true
            maskSource: mask.item as Item
            maskThresholdMin: 1 - root.progress
            maskSpreadAtMin: root.transition === "dots" ? 0.02 : 0.1
        }
    }
}
