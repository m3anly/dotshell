pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    id: root

    readonly property bool reduced: GameMode.stillMotion

    readonly property real qtStep: 0.016

    function spring(zeta: real, stiffness: real): var {
        const springPerStep = stiffness * qtStep;
        const dampingPerStep = 2 * zeta * Math.sqrt(stiffness) * qtStep;
        const mass = dampingPerStep > 0.9 ? 0.9 / dampingPerStep : 1;
        return {
            spring: springPerStep * mass,
            damping: dampingPerStep * mass,
            mass: mass
        };
    }

    readonly property var fast: spring(0.6, 800)
    readonly property var standard: spring(0.8, 380)
    readonly property var slow: spring(0.8, 200)

    readonly property int fastMs: 360
    readonly property int standardMs: 420
    readonly property int slowMs: 560

    readonly property int effectsMs: 200
    readonly property list<real> effectsCurve: [0.2, 0, 0, 1, 1, 1]

    readonly property list<real> exitCurve: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property int exitMs: 180

    readonly property list<real> expandCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property int expandMs: 480

    function springStep(state: var, target: real, zeta: real, stiffness: real, dt: real): void {
        const steps = Math.max(1, Math.ceil(dt / 0.004));
        const h = dt / steps;
        const damping = 2 * zeta * Math.sqrt(stiffness);
        for (let i = 0; i < steps; i++) {
            state.velocity += (stiffness * (target - state.value) - damping * state.velocity) * h;
            state.value += state.velocity * h;
        }
    }

    function cubicBezier(x1: real, y1: real, x2: real, y2: real, t: real): real {
        let lo = 0, hi = 1, u = t;
        for (let i = 0; i < 20; i++) {
            u = (lo + hi) / 2;
            const x = 3 * (1 - u) * (1 - u) * u * x1 + 3 * (1 - u) * u * u * x2 + u * u * u;
            if (x < t)
                lo = u;
            else
                hi = u;
        }
        return 3 * (1 - u) * (1 - u) * u * y1 + 3 * (1 - u) * u * u * y2 + u * u * u;
    }

    function exitAt(t: real): real {
        return cubicBezier(exitCurve[0], exitCurve[1], exitCurve[2], exitCurve[3], Math.max(0, Math.min(1, t)));
    }
}
