import QtQuick

NumberAnimation {
    duration: Motion.reduced ? 0 : Motion.exitMs
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.exitCurve
}
