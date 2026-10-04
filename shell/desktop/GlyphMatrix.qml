pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.theme
import "../components/Glyphs.js" as Glyphs

Item {
    id: root

    property string mode: "time"

    readonly property int size: 25
    readonly property int center: 12
    readonly property real cell: width / size
    readonly property real dotRadius: cell * 0.34
    readonly property var spring: Motion.spring(0.55, 300)
    readonly property var digitOrigins: [[7, 4], [13, 4], [7, 14], [13, 14]]
    readonly property var ringCells: {
        const list = [];
        for (let y = 0; y < size; y++)
            for (let x = 0; x < size; x++) {
                const r = Math.hypot(x - center, y - center);
                if (r > 10.6 && r <= 12.4)
                    list.push({
                        x: x,
                        y: y,
                        r: r
                    });
            }
        const angle = c => (Math.atan2(c.x - center, center - c.y) + Math.PI * 2) % (Math.PI * 2);
        return list.sort((a, b) => angle(a) - angle(b));
    }
    readonly property var digitCells: {
        const list = [];
        digitOrigins.forEach((origin, digit) => {
            for (let row = 0; row < 7; row++)
                for (let column = 0; column < 5; column++) {
                    const x = origin[0] + column;
                    const y = origin[1] + row;
                    list.push({
                        x: x,
                        y: y,
                        r: Math.hypot(x - center, y - center),
                        digit: digit,
                        column: column,
                        row: row
                    });
                }
        });
        return list;
    }
    property string digits: ""
    property int current: -1
    property real stagger: 0
    property bool intro: true

    function pad(n: int): string {
        return String(n).padStart(2, "0");
    }

    function refresh(stagger: real): void {
        const date = clock.date;
        root.stagger = stagger;
        digits = mode === "time" ? Time.hourText(date.getHours()) + pad(date.getMinutes()) : pad(date.getDate()) + pad(date.getMonth() + 1);
        current = Math.floor(date.getSeconds() / 60 * ringCells.length);
        root.stagger = 0;
    }

    function delayFor(cell: var, ring: bool): real {
        if (intro)
            return 200 + cell.r * 55 + Math.random() * 60;
        return ring ? 0 : Math.random() * stagger;
    }

    onModeChanged: refresh(520)
    onCellChanged: grid.requestPaint()
    Component.onCompleted: {
        refresh(0);
        intro = false;
    }

    component Dot: Rectangle {
        id: dot

        required property var modelData
        property bool ring: false
        property real target: 0
        property real level: 0

        x: (modelData.x + 0.5) * root.cell - root.dotRadius
        y: (modelData.y + 0.5) * root.cell - root.dotRadius
        width: root.dotRadius * 2
        height: width
        radius: width / 2
        antialiasing: true
        visible: level > 0.01
        opacity: Math.min(1, level)
        scale: Math.max(0, 0.55 + 0.45 * level)
        onTargetChanged: {
            const delay = Motion.reduced ? 0 : root.delayFor(modelData, ring);
            if (delay > 0) {
                wait.interval = delay;
                wait.restart();
                return;
            }
            wait.stop();
            level = target;
        }

        Behavior on level {
            enabled: !Motion.reduced

            SpringAnimation {
                spring: root.spring.spring
                damping: root.spring.damping
                mass: root.spring.mass
                epsilon: 0.002
            }
        }

        Timer {
            id: wait

            onTriggered: dot.level = dot.target
        }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
        onSecondsChanged: root.refresh(600)
    }

    Canvas {
        id: grid

        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "rgba(255, 255, 255, 0.12)";
            ctx.beginPath();
            for (let y = 0; y < root.size; y++)
                for (let x = 0; x < root.size; x++) {
                    if (Math.hypot(x - root.center, y - root.center) > 12.4)
                        continue;
                    const cx = (x + 0.5) * root.cell;
                    const cy = (y + 0.5) * root.cell;
                    ctx.moveTo(cx + root.dotRadius, cy);
                    ctx.arc(cx, cy, root.dotRadius, 0, Math.PI * 2);
                }
            ctx.fill();
        }
    }

    Repeater {
        model: root.digitCells

        Dot {
            target: Glyphs.digitLit(root.digits.charAt(modelData.digit), modelData.column, modelData.row) ? 1 : 0
            color: Theme.fg
        }
    }

    Item {
        id: glow

        readonly property Item dot: root.current >= 0 && root.current < ring.count ? ring.itemAt(root.current) : null

        x: dot ? dot.x + dot.width / 2 : 0
        y: dot ? dot.y + dot.height / 2 : 0
        visible: dot !== null && dot.level > 0.01
        opacity: dot ? Math.min(1, dot.level) : 0

        Rectangle {
            x: -width / 2
            y: -height / 2
            width: root.dotRadius * 4.8
            height: width
            radius: width / 2
            color: Theme.red
            opacity: 0.12
            antialiasing: true
        }

        Rectangle {
            x: -width / 2
            y: -height / 2
            width: root.dotRadius * 3.2
            height: width
            radius: width / 2
            color: Theme.red
            opacity: 0.25
            antialiasing: true
        }
    }

    Repeater {
        id: ring

        model: root.ringCells

        Dot {
            required property int index

            ring: true
            target: index < root.current ? 0.45 : index === root.current ? 1 : 0
            color: index === root.current ? Theme.red : Theme.fg
        }
    }
}
