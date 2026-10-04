import QtQuick

MouseArea {
    id: root

    property real remainder: 0
    property int stepSize: 5

    signal stepped(int step)

    width: 4
    acceptedButtons: Qt.NoButton

    onWheel: wheel => {
        if (Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y)) {
            wheel.accepted = false;
            return;
        }
        remainder += wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y * 4 : wheel.angleDelta.y;
        const steps = Math.trunc(remainder / 120);
        if (steps === 0)
            return;
        remainder -= steps * 120;
        stepped(steps * Math.max(1, root.stepSize));
    }
}
