import QtQuick

NumberAnimation {
    duration: Motion.reduced ? 0 : Motion.expandMs
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.expandCurve
}
