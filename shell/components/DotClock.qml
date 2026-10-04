import QtQuick
import qs.theme
import "Glyphs.js" as Glyphs

Canvas {
    id: root

    property string digits: "0000"
    property color color: Theme.fg

    readonly property real cell: height / 7
    readonly property var digitColumns: [0, 6, 14, 20]
    property var dots: []
    property bool moving: false

    implicitHeight: 15
    implicitWidth: cell * 25

    Component.onCompleted: {
        build();
        retarget(true);
    }
    onDigitsChanged: retarget(false)
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function build(): void {
        const list = [];
        for (let k = 0; k < 4; k++)
            for (let row = 0; row < 7; row++)
                for (let col = 0; col < 5; col++)
                    list.push({
                        digit: k,
                        col: col,
                        row: row,
                        x: digitColumns[k] + col,
                        value: 0,
                        velocity: 0,
                        target: 0,
                        startAt: 0,
                        exitFrom: 0
                    });
        dots = list;
    }

    function retarget(instant: bool): void {
        const now = Date.now();
        const animate = !instant && !Motion.reduced;
        for (const dot of dots) {
            const target = Glyphs.digitLit(digits[dot.digit], dot.col, dot.row) ? 1 : 0;
            if (target === dot.target)
                continue;
            dot.target = target;
            if (!animate) {
                dot.value = target;
                dot.velocity = 0;
                continue;
            }
            dot.startAt = now + (target ? Math.random() * 220 : 0);
            dot.exitFrom = dot.value;
        }
        moving = animate;
        requestPaint();
    }

    function advance(dt: real): void {
        const now = Date.now();
        let busy = false;
        for (const dot of dots) {
            if (now < dot.startAt) {
                busy = true;
                continue;
            }
            if (dot.target === 1) {
                if (Math.abs(1 - dot.value) > 0.002 || Math.abs(dot.velocity) > 0.02) {
                    Motion.springStep(dot, 1, 0.6, 800, dt);
                    busy = true;
                } else {
                    dot.value = 1;
                    dot.velocity = 0;
                }
            } else if (dot.value > 0) {
                const t = (now - dot.startAt) / 160;
                dot.velocity = 0;
                dot.value = t >= 1 ? 0 : dot.exitFrom * (1 - Motion.exitAt(t));
                busy = busy || dot.value > 0;
            }
        }
        moving = busy;
        requestPaint();
    }

    FrameAnimation {
        running: root.moving
        onTriggered: root.advance(Math.min(frameTime, 0.064))
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = Theme.css(color);
        const full = cell * 0.44;
        const disc = (cx, cy, r) => {
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.fill();
        };
        for (const dot of dots) {
            if (dot.value <= 0.01)
                continue;
            ctx.globalAlpha = Math.min(1, dot.value);
            disc((dot.x + 0.5) * cell, (dot.row + 0.5) * cell, full * Math.max(0, 0.3 + 0.7 * dot.value));
        }
        ctx.globalAlpha = 1;
        disc(12.5 * cell, 2.5 * cell, full);
        disc(12.5 * cell, 4.5 * cell, full);
    }
}
