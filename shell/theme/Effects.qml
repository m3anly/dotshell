import QtQuick

NumberAnimation {
    duration: Motion.reduced ? 0 : Motion.effectsMs
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.effectsCurve
}
